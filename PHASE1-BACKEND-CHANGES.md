# Phase 1: Multi-College Backend Foundation

Scope, per what we agreed: DU colleges only (no external/scraped events yet),
allowlist model kept but with self-registration, backend first.

## What changed

### 1. Data model
- **`events`** now carries two new required fields:
  - `college` (string) — which college the event belongs to
  - `visibility` (`"college"` | `"du_wide"`) — whether it shows only under
    that college's filter, or DU-wide (fests, inter-college meets)
- **`society_admins`** now carries two new optional fields:
  - `college` (string) — which college this POC/society belongs to
  - `status` (`"active"` | `"pending"`) — absent = treated as `"active"`,
    so every existing allowlist doc keeps working with zero migration
- **New `colleges` collection** — a curated registry (name, shortCode,
  emailDomains, active) for populating college pickers later. Seeded with
  10 DU colleges in `docs/colleges.sample.json`. Public read, no client
  writes (console/script only, like the rest of the reference data).

### 2. Firestore rules (`firestore.rules`)
- Event create/update now validates `college` and `visibility`, and
  checks the writer's college matches their own `society_admins.college`
  (same pattern as the existing society check) — a POC can't post events
  under a college they're not allowlisted for.
- `society_admins` now allows **self-create**: a signed-in user can create
  their own doc, but only with `status: "pending"` and `active: false` —
  never as immediately active. Existing update/delete stay fully locked
  down (an admin approves a pending doc out-of-band, e.g. via script).
- `isAllowlistedAdmin()` now also requires `status == "active"` (or the
  field being absent, for backward compatibility).
- `colleges` is public-read.

### 3. App (Flutter)
- `EventsBundle` model gained `college` and `visibility` fields.
  Old-format events with no `college` field fall back to "St. Stephen's
  College" so existing data doesn't vanish from the feed.
- New `lib/College.dart` — `College` model + `CollegeService` to read the
  `colleges` registry (mirrors the existing `Society.dart` pattern).
- `UserRoleService.getCurrentUserCollege()` — fetches the signed-in POC's
  college from their own `society_admins` doc (the server-trusted value,
  not something typed in a UI).
- `addevent_body.dart` (in-app event creation): now fetches and sends the
  POC's college automatically, plus a "DU-wide event" toggle that sets
  `visibility`. Fails fast with a clear message if a POC's account has no
  college on file yet, instead of a confusing Firestore permission error.
- `my_events.dart` (edit flow): no changes needed — Firestore rules
  evaluate the *resulting* document on update, so partial edits that
  don't touch `college`/`visibility` keep the existing values.

### 4. Admin portal (`admin-portal/`)
- Publish/edit form: added a "DU-wide event" checkbox, sends
  `college`/`visibility` in the write payload, and shows the signed-in
  POC's college as a badge at the top of the form.
- Login check: pending self-registrations are recognized and shown a
  clear "awaiting approval" message instead of a generic access-denied.
- Event list: now shows college + DU-wide tag alongside society.

### 5. Scripts
- `scripts/sync_society_admins.js` — accepts `college` and `status`
  columns/fields now (both optional, both backward compatible).
- `scripts/sync_colleges.js` (**new**) — seeds/updates the `colleges`
  registry from a JSON file, same conventions as the existing sync script.
- `scripts/list_society_admins.js` — now shows college + status per row,
  and surfaces a pending-approvals count with a reminder of how to
  approve.
- `docs/colleges.sample.json` (**new**) — seed data for 10 DU colleges.

## What this does NOT do yet (future slices, by design)
- No feed UI for filtering by college or DU-wide — that's the "home feed
  UI changes" slice we scoped separately.
- No self-registration *form* in the app or portal yet — the rules and
  scripts support it, but there's no UI for a society to submit their own
  `society_admins` doc. That's a natural next slice once you're ready.
- No external/non-DU event sourcing — explicitly deferred per your call.

## Before deploying
- Run `firebase deploy --only firestore:rules` to push the new rules.
- Run `node scripts/sync_colleges.js --file docs/colleges.sample.json`
  (with `GOOGLE_APPLICATION_CREDENTIALS` set) to seed the colleges
  collection — edit the sample file first if the 10 seeded colleges
  aren't the right starting list.
- Existing `society_admins` docs need a `college` value added (via
  `sync_society_admins.js` with an updated CSV/JSON) **before those POCs
  can publish new events** — `validEventPayload` now rejects a blank
  `college`, so this backfill is mandatory, not optional, before rules
  deploy or the in-app "add event" / portal publish flow will start
  failing for anyone not yet backfilled. Existing already-published
  events are read-only fine either way; this only affects new writes.
