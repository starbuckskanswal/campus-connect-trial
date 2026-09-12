#!/usr/bin/env node

let admin = null;

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
  ensureFirebaseInitialized();

  const db = admin.firestore();
  const snapshot = await db.collection('society_admins').orderBy('email').get();
  const rows = snapshot.docs.map((doc) => {
    const data = doc.data() || {};
    const active = data.active !== false;
    const status = data.status || 'active'; // absent = pre-existing, treated as active

    return {
      docId: doc.id,
      email: data.email || '',
      society: data.society || '',
      college: data.college || "St. Stephen's College",
      active,
      status,
    };
  });

  const activeRows = rows.filter((row) => row.active && row.status === 'active');
  const pendingRows = rows.filter((row) => row.status === 'pending');

  console.log(`Total society_admins docs: ${rows.length}`);
  console.log(`Active allowlisted emails: ${activeRows.length}`);
  console.log(`Pending self-registrations awaiting approval: ${pendingRows.length}`);

  if (rows.length === 0) {
    console.log('No allowlist records found.');
    return;
  }

  console.table(rows);

  if (pendingRows.length > 0) {
    console.log('\nTo approve a pending registration, run:');
    console.log('  node scripts/sync_society_admins.js --file <path-with-status-active>');
    console.log('or set status:"active" directly on its society_admins doc.');
  }
}

main().catch((error) => {
  console.error(error.message || error);
  process.exit(1);
});
