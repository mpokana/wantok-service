# CX1 — Saved read-only refresh checkpoint

**Date:** 11 October 2026
**System:** EAGLT02; Client Web 3000 / staging 3300; Android offline demo handled separately

## What is delivered

The existing Account → Saved screen now exposes **Refresh saved items** in the AppBar. It reloads existing saved items through `ClientExperienceRepository.loadSavedItems` (unchanged RLS) and leaves existing bookmark changes exclusively behind the original explicit Remove action. A `_refreshing` guard prevents overlapping requests; loading, error and Retry states remain in the existing `FutureBuilder` and pull-to-refresh. This is a non-transactional UX enhancement, not permission/role or database work.

## Source and verification

- `apps/wantok_app/lib/src/home/client_account_tools.dart`
- `apps/wantok_app/test/cx1_saved_read_only_test.dart`
- Isolated QA worktree `D:\Wantok_CX1_Saved_Refresh_QA_20261011` based on previous `dd0a24d`, copied ONLY two Client files; no parallel vendor working files copied.
- Six focused widget cases PASS: 390/1240 px saved provider, 390/1240 px toolbar refresh, empty collection and failed read/Retry.
- Full `scripts/flutter/check.ps1` PASS: seven Flutter analysis targets, all Client/Operations/Technical suites. This is source/widget acceptance, **not** live Saved persistence.

## Deployment and recovery

- Client release built with local Web environment and smoke fixtures disabled. JS SHA-256: `2DE1432750358A432FA32FCDCDC71DB03534B12A95BD162547EEC5C50C507033`.
- Staging `:3300` and main Client `:3000` updated and validated with HTTP 200, exact JavaScript sizes and a shared category-image HTTP check.
- Pre-deployment full copy: `D:\Wantok_Project_Backups\wantok-client-web-pre-saved-refresh-20261011`.
- Verified immutable candidate: `D:\Wantok_Project_Backups\wantok-client-web-saved-refresh-candidate-20261011`.
- Technical `:3100`, Operations `:3200`, Technical staging `:3400` untouched.
- Android offline-demo x64 build **4008** successfully built, backed up at `D:\Wantok_Project_Backups\wantok-client-cx1-saved-refresh-android-preview-4008-20261011.apk`, file SHA-256 `93FBE7C5FF01DC52AF9113943BF99124C2D7BC3763BC0CEE4FFA2F72327B15A8`. `adb install -r` returned Success, installed versionCode 4008, original firstInstallTime 2026-10-05 23:44:14 preserved, app launched; no uninstall or data reset. Not a signed-in phone or physical HONOR acceptance.

## Open gates

Actual signed-in Web Account → Saved content and cross-session persistence still needs read-only click-through. No bookmark toggle or removal has been performed. Inbox, Track, Wallet, Wantok Agent, physical HONOR, and approval of six PNG/Pacific category image drafts remain open. CX1 **IN PROGRESS**; T2.4 **DEFERRED**.
