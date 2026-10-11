# CX1 — Narrow-width refresh route-safety QA

**Date:** 11 October 2026 (PNG)
**Device:** EAGLT02
**Stage:** Automated source/widget and local release integrity PASS; actual signed-in Chrome click acceptance OPEN.
**Scope:** Tests and documentation only. No application source/behaviour, Web/Android deployment, database, customer record or VM change.

## Changes

- Extend `cx1_inbox_track_refresh_test.dart` to include 320 px in addition to 390/1440 px, while retaining real centre-tap, read-count and error recovery checks.
- Extend `cx1_saved_read_only_test.dart` to include 320 px in addition to 390/1240 px, verifying existing provider display and safe reload.
- Add `cx1_refresh_navigation_safety_test.dart` with six 320/1440 px Saved, Inbox and Track cases that attach a `NavigatorObserver`, click the labelled keyed Refresh control at its centre, verify a second repository read, and assert no new Flutter route was pushed. Tests use injected read-only loaders and synthetic empty data, not customer records.
- New checks guard Flutter routing, **not** browser-level mis-targeting, focus, cache, overlay or Chrome navigation. The earlier inadvertent vendor-onboarding navigation is not assigned an unproven root cause.

## Verification performed

1. EAGLT02 device ping PASS. Five local applications :3000/:3100/:3200/:3300/:3400 returned HTTP 200.
2. `scripts/qa/verify-cx1-local.ps1 -CheckAndroid` **CX1_RELEASE_QA_PASS**, exit 0. Main/staging Client JS SHA-256 `2207D8BBCCC5BE261B7C7A77498F4E801829E0D7B13378F56B61A06F3E3B2E66`. Technical JS SHA-256 `1D0E6DE096EC54D7D189A798B756A23EAE4F4B7CD32C4AAFE4E30DB905AD67A1`; Taxi/Public Services shared imagery byte parity. Emulator `emulator-5554` installed Android `io.wantok.service` versionCode 4010, firstInstallTime unchanged.
3. Isolated detached worktree `D:\Wantok_CX1_Refresh_Narrow_QA_20261011` at CX1 baseline `735452c`: 16 Saved/Inbox/Track tests PASS with additional 320 px scenarios; six separate route-safety tests PASS.
4. Complete `scripts/flutter/check.ps1` on clean original CX1 baseline PASS: all seven Flutter analyses, Client (132), Operations (33), Technical (12) widget tests.
5. Attempt on the actively served main checkout after E6A: source analysis and Client/Operations tests completed, but Technical's test runner was blocked by Windows access to `apps/wantok_tech/build/unit_test_assets`; NOT a failing widget assertion. Did not delete, unlock or force-reset any build directory.
6. NEW clean integration worktree `D:\\Wantok_CX1_Refresh_E6_Integration_QA_20261011`, based on E6A commit `e6c8594` with these three CX1 test files: **PASS**, exit 0, all seven analyses, **132 Client + 34 Operations + 12 Technical** widget tests. This validates the changes together without touching the locked main build.

## Browser boundary

The Windows input desktop subsequently reported `Default` (normal) and an identified dedicated Chrome Client window displayed the Public Services screen. The browser foreground/window identity then changed to a separate Chrome session. No Refresh button on Saved, Inbox or Track was visually opened or clicked in this attempt. Private window-only evidence remains in ignored `.wantok/cx1-browser-dedicated-initial-20261011.png`, never Git. No credentials, browser tokens, user data, form submissions or customer mutations were accessed.

**OPEN:** actual signed-in browser button display, focus, click and no-misnavigation at desktop/phone viewport; cross-login Saved; signed-in Android and physical HONOR; six individually approved inactive-category photographs and Technical category image CRUD.

**Safety boundaries:** CX1 IN PROGRESS; T2.4 (Diagnostics, Logs and Jobs) DEFERRED; online VM deployment NOT authorised. Existing E6 Operations scoped compliance code and `supabase/snippets/` preserved.

**Rollback/recovery:** Test-only change; revert this CX1 test commit without changing shipped apps if required. Existing Web rollback `D:\Wantok_Project_Backups\wantok-client-web-pre-labeled-refresh-20261011` and build-4010 APK remain untouched. An independent complete-history Git bundle will be recorded under `D:\Wantok_Project_Backups` with adjacent SHA-256 verification after commit.
