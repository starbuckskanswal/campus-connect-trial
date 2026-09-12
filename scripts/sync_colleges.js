#!/usr/bin/env node

const fs = require('fs');
const path = require('path');

let admin = null;

function parseArgs(argv) {
  const args = {};

  for (let i = 0; i < argv.length; i += 1) {
    const token = argv[i];
    if (!token.startsWith('--')) {
      continue;
    }

    const key = token.slice(2);
    const next = argv[i + 1];
    if (!next || next.startsWith('--')) {
      args[key] = true;
      continue;
    }

    args[key] = next;
    i += 1;
  }

  return args;
}

function printUsage() {
  console.log(`
Usage:
  node scripts/sync_colleges.js --file <path> [--dry-run]

Environment:
  GOOGLE_APPLICATION_CREDENTIALS=/absolute/path/to/service-account.json

Input format (JSON array), see docs/colleges.sample.json:
  [{ "docId": "st-stephens", "name": "St. Stephen's College", "shortCode": "SSC",
     "emailDomains": ["ststephens.edu"], "active": true }]

Notes:
  - docId is the Firestore document id (a short slug); falls back to a
    slugified version of "name" if omitted.
  - active defaults to true when omitted.
  - emailDomains defaults to [] when omitted (used for optional college
    email verification later; not required to add a college now).
  - Writes are additive (merge:true) — this only ever adds/updates
    colleges, it never removes ones not present in the file.
`);
}

function slugify(value) {
  return String(value)
      .trim()
      .toLowerCase()
      .replace(/[^a-z0-9]+/g, '-')
      .replace(/^-+|-+$/g, '');
}

function parseBoolean(value, fallback = true) {
  if (value === undefined || value === null || value === '') {
    return fallback;
  }
  if (typeof value === 'boolean') {
    return value;
  }
  const normalized = String(value).trim().toLowerCase();
  if (['true', '1', 'yes', 'y'].includes(normalized)) {
    return true;
  }
  if (['false', '0', 'no', 'n'].includes(normalized)) {
    return false;
  }
  throw new Error(`Invalid boolean value: ${value}`);
}

function normalizeRecord(record, index) {
  const name = String(record.name || '').trim();
  if (!name) {
    throw new Error(`Row ${index + 1}: name is required`);
  }

  const docId = String(record.docId || slugify(name)).trim();
  const shortCode = String(record.shortCode || '').trim();
  const emailDomains = Array.isArray(record.emailDomains)
      ? record.emailDomains.map((d) => String(d).trim().toLowerCase()).filter(Boolean)
      : [];
  const active = parseBoolean(record.active, true);

  return {docId, name, shortCode, emailDomains, active};
}

function loadRecords(filePath) {
  const absolutePath = path.resolve(process.cwd(), filePath);
  const content = fs.readFileSync(absolutePath, 'utf8');
  const data = JSON.parse(content);

  if (!Array.isArray(data)) {
    throw new Error('JSON file must contain an array of records');
  }

  return data.map(normalizeRecord);
}

function ensureFirebaseInitialized() {
  if (!process.env.GOOGLE_APPLICATION_CREDENTIALS) {
    throw new Error(
        'GOOGLE_APPLICATION_CREDENTIALS is not set. Point it to your Firebase service account JSON file.',
    );
  }

  if (!admin) {
    admin = require('firebase-admin');
  }

  if (admin.apps.length === 0) {
    admin.initializeApp({
      credential: admin.credential.applicationDefault(),
    });
  }
}

async function main() {
  const args = parseArgs(process.argv.slice(2));

  if (args.help || !args.file) {
    printUsage();
    process.exit(args.help ? 0 : 1);
  }

  const records = loadRecords(args.file);
  const uniqueRecords = new Map();
  records.forEach((record) => uniqueRecords.set(record.docId, record));

  console.log(`Loaded ${records.length} row(s), ${uniqueRecords.size} unique college(s).`);

  if (args['dry-run']) {
    console.table([...uniqueRecords.values()]);
    console.log('Dry run complete. No Firestore changes made.');
    return;
  }

  ensureFirebaseInitialized();
  const db = admin.firestore();
  const batch = db.batch();

  [...uniqueRecords.values()].forEach((record) => {
    const ref = db.collection('colleges').doc(record.docId);
    batch.set(ref, {
      name: record.name,
      shortCode: record.shortCode,
      emailDomains: record.emailDomains,
      active: record.active,
    }, {merge: true});
  });

  await batch.commit();
  console.log(`Upserted ${uniqueRecords.size} college record(s) to Firestore.`);
}

main().catch((error) => {
  console.error(error.message || error);
  process.exit(1);
});
