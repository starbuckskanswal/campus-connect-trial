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
  node scripts/sync_society_admins.js --file <path> [--dry-run] [--deactivate-missing]

Environment:
  GOOGLE_APPLICATION_CREDENTIALS=/absolute/path/to/service-account.json

Accepted input formats:
  CSV columns: email,society,college,active,status
  JSON array: [{ "email": "...", "society": "...", "college": "...", "active": true, "status": "active" }]

Notes:
  - Firestore doc ID is always the lowercased email.
  - active defaults to true when omitted.
  - college defaults to "St. Stephen's College" when omitted, for
    backward compatibility with single-college allowlist files.
  - status defaults to "active" when omitted (this script is for
    admin-curated approvals, not the in-app self-registration flow,
    which always writes status:"pending" itself).
  - --deactivate-missing marks existing docs not present in the file as active:false.
`);
}

function splitCsvLine(line) {
  const values = [];
  let current = '';
  let inQuotes = false;

  for (let i = 0; i < line.length; i += 1) {
    const char = line[i];
    const next = line[i + 1];

    if (char === '"') {
      if (inQuotes && next === '"') {
        current += '"';
        i += 1;
      } else {
        inQuotes = !inQuotes;
      }
      continue;
    }

    if (char === ',' && !inQuotes) {
      values.push(current);
      current = '';
      continue;
    }

    current += char;
  }

  values.push(current);
  return values.map((value) => value.trim());
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
  const email = String(record.email || '').trim().toLowerCase();
  const society = String(record.society || '').trim();
  const college = String(record.college || '').trim() || "St. Stephen's College";
  const active = parseBoolean(record.active, true);
  const status = String(record.status || '').trim().toLowerCase() || 'active';

  if (!email) {
    throw new Error(`Row ${index + 1}: email is required`);
  }
  if (!society) {
    throw new Error(`Row ${index + 1}: society is required`);
  }
  if (!['active', 'pending'].includes(status)) {
    throw new Error(`Row ${index + 1}: status must be "active" or "pending"`);
  }

  return {
    docId: email,
    email,
    society,
    college,
    active,
    status,
  };
}

function parseCsv(content) {
  const lines = content
      .split(/\r?\n/)
      .map((line) => line.trim())
      .filter((line) => line.length > 0);

  if (lines.length === 0) {
    return [];
  }

  const headers = splitCsvLine(lines[0]).map((value) => value.toLowerCase());

  return lines.slice(1).map((line, index) => {
    const values = splitCsvLine(line);
    const record = {};

    headers.forEach((header, headerIndex) => {
      record[header] = values[headerIndex] || '';
    });

    return normalizeRecord(record, index);
  });
}

function parseJson(content) {
  const data = JSON.parse(content);
  if (!Array.isArray(data)) {
    throw new Error('JSON file must contain an array of records');
  }

  return data.map((record, index) => normalizeRecord(record, index));
}

function loadRecords(filePath) {
  const absolutePath = path.resolve(process.cwd(), filePath);
  const content = fs.readFileSync(absolutePath, 'utf8');
  const ext = path.extname(absolutePath).toLowerCase();

  if (ext === '.json') {
    return parseJson(content);
  }
  if (ext === '.csv') {
    return parseCsv(content);
  }

  throw new Error('Unsupported file type. Use .csv or .json');
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

async function deactivateMissingRecords(db, desiredIds) {
  const snapshot = await db.collection('society_admins').get();
  const batch = db.batch();
  let changed = 0;

  snapshot.docs.forEach((doc) => {
    if (desiredIds.has(doc.id)) {
      return;
    }

    batch.set(doc.ref, {active: false}, {merge: true});
    changed += 1;
  });

  if (changed > 0) {
    await batch.commit();
  }

  return changed;
}

async function main() {
  const args = parseArgs(process.argv.slice(2));

  if (args.help || !args.file) {
    printUsage();
    process.exit(args.help ? 0 : 1);
  }

  const records = loadRecords(args.file);
  const uniqueRecords = new Map();

  records.forEach((record) => {
    uniqueRecords.set(record.docId, record);
  });

  console.log(`Loaded ${records.length} row(s), ${uniqueRecords.size} unique email(s).`);

  if (args['dry-run']) {
    console.table([...uniqueRecords.values()]);
    console.log('Dry run complete. No Firestore changes made.');
    return;
  }

  ensureFirebaseInitialized();
  const db = admin.firestore();
  const batch = db.batch();

  [...uniqueRecords.values()].forEach((record) => {
    const ref = db.collection('society_admins').doc(record.docId);
    batch.set(ref, {
      email: record.email,
      society: record.society,
      college: record.college,
      active: record.active,
      status: record.status,
    }, {merge: true});
  });

  await batch.commit();
  console.log(`Upserted ${uniqueRecords.size} allowlist record(s) to Firestore.`);

  if (args['deactivate-missing']) {
    const changed = await deactivateMissingRecords(db, new Set(uniqueRecords.keys()));
    console.log(`Deactivated ${changed || 0} missing Firestore record(s).`);
  }
}

main().catch((error) => {
  console.error(error.message || error);
  process.exit(1);
});
