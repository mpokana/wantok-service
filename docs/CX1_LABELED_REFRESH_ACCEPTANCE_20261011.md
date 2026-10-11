# CX1 — Labelled Refresh Controls and Click-Target QA

**Date:** 11 October 2026 (PNG)
**Host:** EAGLT02
**Status:** SOURCE/WIDGET/WEB DEPLOYMENT PASS; SIGNED-IN BROWSER VISUAL ACCEPTANCE OPEN

## Why this change

The three existing refresh actions were icon-only. Live Chrome interaction had been ambiguous: one attempted Saved refresh click navigated instead to vendor onboarding, while earlier Inbox/Track screenshots did not conclusively show their toolbar controls. No destructive input occurred. This did not prove whether the root cause was browser caching, viewport coordinates, focus, or UI rendering. Avoid changing authentication/cookies or guessing that the bundle was defective: independent port parity already proved the three labels existed in the compiled Client JS.

## Implemented

- **Saved:** a visible `Refresh` text + icon, accessible tooltip `Refresh saved items`, stable Flutter ValueKey `cx1-saved-refresh`, minimum 96 × 48 logical px.
- **Inbox:** the same labelled `Refresh` text + icon within the existing green header, tooltip `Refresh Inbox`, ValueKey `cx1-inbox-refresh`, minimum 96 × 48.
- **Track:** the matching `Refresh` action in its green header, tooltip `Refresh activity`, ValueKey `cx1-track-refresh`, minimum 96 × 48.
- Existing read-only repository loaders, owner-scoped RLS, loading/retry/empty states, and concurrency guards are unchanged. Track still disables refresh while a booking/review action is busy.
- No backend schema, bookings, payments, support status, saved item mutations, provider approvals, operations/toggle, public service dispatch, or vendor-governance code changes.

## Verification

- Isolated QA source worktree `D:\Wantok_CX1_Labeled_Refresh_QA_20261011`, created detached from then-current source commit, copying only five relevant Flutter files.
- **12 focused widget tests PASS** across the Saved and Inbox/Track suites. They locate the stable button keys, verify minimum 44 logical px touch height, tap the actual on-screen centre, and check that existing read loaders execute without making writes. Includes 390px/mobile and 1240–1440px/desktop cases plus empty/error Retry cases.
- Complete `scripts/flutter/check.ps1` **PASS** across all seven analyses and complete Client, Operations and Technical widget suites (including unrelated existing vendor-governance tests).
- Client Web built from same isolated source with local Web configuration and smoke-data fixture disabled. `main.dart.js` SHA-256 **2207D8BBCCC5BE261B7C7A77498F4E801829E0D7B13378F56B61A06F3E3B2E66**, length 4,099,079 bytes. The compiled bundle contains all three refresh captions and new ValueKeys.
- **Client Web :3000 and independent staging :3300 deployed successfully**, with file-hash copies and HTTP JS/photo integrity verification; `D:\Wantok_Project_Backups\wantok-client-web-pre-labeled-refresh-20261011` is the independent old-build rollback, and `D:\Wantok_Project_Backups\wantok-client-web-labeled-refresh-candidate-20261011` is the validated candidate.
- Technical :3100, Operations :3200, Technical staging :3400 were not rebuilt/deployed.

## Windows lock screen / acceptance limit

The Windows desktop was showing **Windows Default Lock Screen** during this pass. A new Chrome app window was opened but could not safely be interacted with while Windows was locked. Did not unlock Windows, interact with authentication, read browser tokens/cookies, access account messages, or force user tabs. Thus **actual signed-in Chrome visibility/click acceptance is still OPEN**, despite passing source, widget and serving tests.

**Android offline-demo emulator PASS:** Matching x64 APK build **4010** compiled and saved at `D:\Wantok_Project_Backups\wantok-client-cx1-labeled-refresh-android-preview-4010-20261011.apk` (92,828,063 bytes, SHA-256 `8FE01D17D5C11057B435686F0499D32EC09BE7B368D50CF3F433E696843C8591`). In-place `adb install -r` returned Success, package versionCode 4010 confirmed, original firstInstallTime `2026-10-05 23:44:14` unchanged, app launched. No uninstall, wipe or sign-in mode change; physical HONOR remains separate. Physical HONOR and signed-in Android remain independent open gates.

## Next CX1 acceptance

Once Windows is unlocked: use a dedicated and unambiguous Wantok Client Web window to visually confirm each labelled Refresh button and interact using the visible control rather than hard-coded screen coordinates, all read-only. Then physical HONOR, signed-in Android, six individual PNG/Pacific-relevant pictures for inactive draft service categories and authorised image-editor CRUD. **CX1 IN PROGRESS; T2.4 DEFERRED.**
