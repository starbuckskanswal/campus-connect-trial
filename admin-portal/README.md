# Campus Connect Admin Portal (Standalone)

This folder is a separate standalone website for Society POCs/admins.
It uses the same Firebase backend (`events`, `society_admins`, `nsysuclubs`, Storage) as the main app, so updates appear in the app in real time.

## What it does

- Google Sign-In for admins
- Allowlist check via Firestore `society_admins`
- Create, edit, and delete events in `events`
- Upload event posters to Firebase Storage
- Realtime event list via Firestore `onSnapshot`

## Deploy independently (Firebase Hosting)

1. Install Firebase CLI (`npm i -g firebase-tools`)
2. Login:
   ```bash
   firebase login
   ```
3. Select project:
   ```bash
   firebase use campus-connect-38daf
   ```
4. Create a separate hosting site in Firebase Console (example: `campus-connect-admin`)
5. Bind target locally:
   ```bash
   firebase target:apply hosting adminPortal campus-connect-admin
   ```
6. Deploy only the admin portal:
   ```bash
   firebase deploy --only hosting:adminPortal --config admin-portal/firebase.hosting.json
   ```

This keeps deployment independent from your student app.

## Required backend collections

- `events`
- `society_admins`
- `nsysuclubs` (optional but recommended for society dropdown)

### `society_admins` examples

- Document ID: lowercased admin email, e.g. `quizclub@college.edu`
- Fields:
  - `email`: `quizclub@college.edu`
  - `society`: `Quiz Club`
  - `active`: `true`

## Notes

- Firebase config is currently set in `index.html` under `window.CAMPUS_CONNECT_FIREBASE_CONFIG`.
- Admin access is not hardcoded in source. Authorization comes from Firestore `society_admins` doc IDs (`lowercased_email`).
- Backend enforcement is done through:
  - `../firestore.rules`
  - `../storage.rules`
- Deploy rules after updates:
  ```bash
  firebase deploy --only firestore:rules,storage
  ```
