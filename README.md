# Campus Connect

This workspace now contains:

- Main Flutter student app (`lib/`, `web/`, mobile folders)
- Standalone admin/POC portal website (`admin-portal/`)

Both share the same Firebase backend (`events`, `society_admins`, Storage), so data posted from the admin portal appears in the app in real time.

## Standalone Admin Portal

See:

- `admin-portal/index.html`
- `admin-portal/app.js`
- `admin-portal/README.md`
- `admin-portal/firebase.hosting.json`

Use `admin-portal/README.md` for independent deployment steps.

## Security Rules

Firebase rules are defined at workspace root:

- `firestore.rules`
- `storage.rules`

Deploy them with:

```bash
firebase deploy --only firestore:rules,storage
```

## Release Prep

Useful local templates and notes:

- `android/key.properties.example`
- `docs/release-readiness.md`
- `docs/society_admins.sample.json`
