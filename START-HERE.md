# Campus Connect — Project Handoff

This bundle contains the COMPLETE source for the Campus Connect project.

## What's inside
- `lib/`            → the Flutter app code. This SAME code builds BOTH the Android and iOS apps.
- `android/`        → Android wrapper project
- `ios/`            → iOS wrapper project
- `macos/`, `web/`  → other platform wrappers (secondary)
- `admin-portal/`   → the standalone backend portal website (society POCs sign in and publish events)
- `firestore.rules`, `storage.rules` → Firebase security rules (the real access control)
- `docs/`           → sample admin-list templates + release notes
- `scripts/`        → helper scripts
- `test/`           → automated tests

## The live admin portal (backend website)
- WORKING portal (use this):   https://campus-connect-38daf.web.app
- Also deployed on Vercel:     https://admin-portal-ssc.vercel.app
  (NOTE: Google sign-in on the Vercel URL currently fails until its domain
   `admin-portal-ssc.vercel.app` is added under Firebase Console →
   Authentication → Settings → Authorized domains.)

Both point at the SAME live Firebase project: `campus-connect-38daf`.
Admin access is controlled by the `society_admins` allowlist in Firestore, NOT by the website.

## First-time setup (for developers)
The big auto-generated folders (`node_modules`, `build`, `Pods`) were left out on
purpose to keep this small. Regenerate them:

1. Install Flutter (https://docs.flutter.dev/get-started/install)
2. In the project root:
       flutter pub get
3. To run the app:
       flutter run           # pick an Android or iOS device/emulator
4. For the admin portal:
       cd admin-portal
       # it's a static site — open index.html, or serve it locally
       # (no build step required)

## Heads-up
The Firebase config in this project points at the LIVE database. Running the app or
portal touches real events. The security rules still apply, so nothing can be changed
unless the signed-in Google email is on the `society_admins` allowlist.
