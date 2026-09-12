# Campus Connect Release Readiness

## Dry Run Right Now

- Share the Android APK manually for testing.
- Keep the admin portal restricted to the allowlisted society emails.
- Deploy the latest Firebase rules before inviting all admins.

## Before Full Student Release

### Android app

- Create a real Android keystore.
- Copy `android/key.properties.example` to `android/key.properties`.
- Put the real keystore at `android/app/keystore.jks` or update the `storeFile` path.
- Bump `flutter.versionName` and `flutter.versionCode` in `android/local.properties`.
- Build a fresh signed release APK.

### Firebase admin allowlist

- Create one Firestore document per society admin in `society_admins`.
- Use the lowercase email as the document ID.
- Keep `active: true` for currently authorized admins only.
- Make sure each doc's `society` matches the society name the admin should publish under.
- To bulk sync the allowlist from a file, use:

```bash
npm install
export GOOGLE_APPLICATION_CREDENTIALS=/absolute/path/to/service-account.json
npm run sync:society-admins -- --file docs/society_admins.sample.csv --dry-run
npm run sync:society-admins -- --file docs/society_admins.sample.csv
```

- The sync script also accepts JSON files like `docs/society_admins.sample.json`.
- Add `--deactivate-missing` if the file should be treated as the full source of truth and old Firestore entries should be disabled automatically.

### Firebase deploys

- Deploy Firestore and Storage rules:

```bash
firebase deploy --only firestore:rules,storage
```

- Deploy the admin portal after admin-side changes:

```bash
firebase deploy --only hosting:adminPortal --config admin-portal/firebase.hosting.json
```

## Recommended Dry-Run Checks

- Verify one allowlisted admin can sign in and publish.
- Verify one non-allowlisted Google account is blocked.
- Upload a poster image and confirm it appears in the app.
- Edit and delete an event from the admin portal.
- Install the APK on at least 3-5 different Android phones.
- Confirm old/outdated events do not show in the main feed.

## Known Current State

- The app is fine for sideloaded Android testing.
- `flutter test` passes with event parsing coverage.
- `flutter analyze` still has pre-existing lint warnings that should be cleaned up later, but they are not immediate dry-run blockers.
