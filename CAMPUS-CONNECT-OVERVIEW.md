# Campus Connect — Project Overview

*A one-stop mobile app for every event happening at St. Stephen's College.*

> This document summarises the app's purpose, features, and current status. It is written as source material for a presentation to the college administration.

---

## The Problem

College life runs on events — society meetings, talks, fests, auditions, placement drives — but information about them is scattered across WhatsApp groups, Instagram pages, and physical notice boards. Students routinely miss events they would have loved to attend, and societies struggle to reach beyond their own circles.

## The Solution

**Campus Connect** is a free mobile app (Android and iOS) that gives every student a single, live feed of everything happening on campus. Society representatives post their events once, and every student sees them instantly — with posters, dates, venues, and details.

---

## What Students Get

- **Live event feed** — every upcoming event across campus in one scrollable feed, with posters and category filters
- **Event details** — full description, date, time, venue, and organising society for each event
- **Calendar view** — see the month at a glance and plan ahead
- **Notice board** — a dedicated tab for official notices and announcements
- **Explore** — browse events by society and discover new societies
- **Bookmarks & reminders** — save events you're interested in and get reminded
- **Accessibility modes** — high-contrast and dark high-contrast colour themes for visually impaired users
- **Simple sign-in** — email/password or Google account; free for every student

## What Societies Get

- **A dedicated admin web portal** — society POCs sign in and can create, edit, and delete their events, and upload posters, from any browser (no app install needed)
- **Instant reach** — an event posted on the portal appears in every student's app in real time
- **Their own identity** — each event carries the society's name and branding

## Governance & Security

- **Only approved society representatives can post.** Admin access is controlled by an official allowlist of society email addresses maintained in the backend database — currently **39 societies and cells onboarded**, including the Students' Union Society, Campus Placement Cell, and Social Service League.
- Both official college email IDs (`@ststephens.edu`) and society Gmail accounts are supported.
- Students can only read; they cannot post or edit anything. All write access is enforced by server-side security rules, not just the app.
- The allowlist can be updated at any time (e.g. yearly handover of society POCs) without changing the app.

## Planned Feature: IQAC Event Reports

A feature designed specifically for the college's quality-assurance (IQAC) needs:

- After an event, the organising society fills a short **structured report form** on the admin portal: attendance, outcomes, and up to ~5 **geotagged, timestamped photographs**, plus an optional PDF.
- At year end, a script exports everything into a **ready-made Excel report and photo bundle** for the IQAC/quality cell — no more chasing societies for reports months later.
- Designed to stay within free hosting limits (photos are compressed and archived annually).

*Status: fully specced; awaiting the IQAC annual-report template so the form fields match the college's official format exactly.*

## Technology & Cost

- Built with **Flutter** (one codebase → Android + iOS) and **Google Firebase** (authentication, database, storage — the same infrastructure used by many universities and startups).
- **Running cost: ₹0.** The app is designed to operate entirely within Firebase's free tier, including the planned IQAC feature.
- The admin portal is a lightweight website hosted free on Firebase Hosting.

### Under the Hood (for the technically curious)

- **App framework:** Flutter, Google's cross-platform toolkit. The app is written once in the **Dart** language, and the same codebase compiles to a native Android app and a native iOS app — no separate teams or duplicate work.
- **Backend:** Google **Firebase**, a managed cloud platform:
  - **Firebase Authentication** — sign-in with email/password or Google accounts
  - **Cloud Firestore** — a real-time database holding events, notices, and the society-admin allowlist; when a society posts an event, students' feeds update live
  - **Firebase Storage** — hosts event posters and (later) IQAC report photos
  - **Firebase Hosting** — serves the society admin portal, which is a simple browser-based site (HTML/JavaScript) so POCs need no installation
- **Security model:** all rules live **server-side** in Firebase security rules — only allowlisted society accounts can write; students have read-only access. Even a modified copy of the app could not bypass this.
- **Build & testing:** iOS builds go through **Xcode** (Apple's required build toolchain), and the app is tested on Xcode's iPhone Simulator. Android builds run through Flutter's command-line tools (which drive Gradle, the standard Android build system, directly) — no heavyweight IDE is needed for either platform.
- **No servers to maintain:** there is no college-hosted machine, no database server to patch, and nothing to keep running — Google's infrastructure handles scaling, uptime, and backups.

## Current Status (August 2026)

| Milestone | Status |
|---|---|
| Android app | ✅ Built and working; installable release APK ready |
| iOS app | ✅ Built and working (tested on simulator) |
| Admin web portal | ✅ Working — create/edit/delete events, poster uploads |
| Society allowlist | ✅ 39 societies onboarded |
| Security rules | ✅ Deployed |
| Play Store release | 🔜 Needs a release signing key + Play Store developer account |
| App Store (iOS) release | 🔜 Needs an Apple Developer account + code signing |
| IQAC report feature | 📝 Specced; awaiting IQAC template |

## What We Need From the College

1. **Approval to launch** the app officially for the student body.
2. **A 5-minute task for college IT:** mark the app as "trusted" in the college's Google Workspace admin console, so official `@ststephens.edu` accounts can use the Google sign-in button (society Gmail accounts already work; college-domain POCs can use email/password sign-in in the meantime).
3. **The IQAC annual-report template**, so the event-report feature can match the official format.
4. *(Optional, for public app-store release)* A one-time **Google Play developer registration (~US$25)** and, if iOS distribution is desired, an **Apple Developer membership (US$99/year)** — ideally under a college-owned account so the app is officially the college's.

---

*Campus Connect is student-built, free to run, and ready to launch.*
