# HONOR Android ARM64 — OFFLINE Visual Preview Beta

Date: 9 October 2026. Environment: EAGLT02 Windows only. Source checkpoint: `1ccd640` plus this additive phone-preview work on `feature/flutter-platform-v1`.

## Why there are two Android beta types

The prior `wantok-android-prior-explore-20261009.apk` is a **debug-signed, emulator x86_64 Flutter engine** build using `SUPABASE_URL` host `10.0.2.2`. It cannot serve as a functioning real-Android handset beta; it is also the PRE-Explore version.

A **functional Android beta** needs an approved reachable **HTTPS staging** Supabase Auth/API URL (not `10.0.2.2`), a non-production test account and data, correct mobile sign-in redirects, network/TLS checks, and app signing/distribution decisions. Do not expose EAGLT02's local Supabase or its developer keys to the Internet or use the physical phone to test privileged provider review/payment routes.

### Safe first deliverable — offline visual beta

An opt-in compile-time `WANTOK_PHONE_PREVIEW=true` entry in `apps/wantok_app/lib/main.dart` starts `WantokPhonePreviewApp` **before calling `WantokBackend.initialize()`**. Without the flag, normal production/development flows remain unchanged. This mode intentionally has **no backend credentials, Supabase connection, auth, real providers, submitted booking, live chat, location request or payment movement**.

The visual shell displays a conspicuous **OFFLINE PREVIEW** warning; approved green/gold brand and original Vanessa/scenic/category images; five navigation destinations Home / Services / Explore / Track / Wallet; header Inbox/Profile buttons that explain the disabled state; photo-only sample service categories; and the **existing** Explore page with its original 12 `S`-marked Reference Screen Samples. Track and Wallet explicitly say their real features require secure staging. Clicking category/sample content never submits real bookings or approvals.

The preview is only an illustrative UX review. It is **not equivalent to the full authenticated Wantok Services app**, cannot verify live use, and must not be distributed as a release. Android manifests may still declare internet/location permissions from the shared normal app, although this mode does not invoke those services. The debug signing key is development-only.

## Reproduce the offline ARM64 preview

From `apps/wantok_app` on EAGLT02 with the existing tested Flutter and Android SDK:

```powershell
[Environment]::SetEnvironmentVariable('ProgramFiles(x86)', 'C:\Program Files (x86)', 'Process')
[Environment]::SetEnvironmentVariable('ProgramData', 'C:\ProgramData', 'Process')
& 'D:\Development\flutter\bin\flutter.bat' build apk --debug --target-platform android-arm64 --dart-define=WANTOK_PHONE_PREVIEW=true --dart-define=WANTOK_SMOKE_DATA=true
```

**DO NOT supply** `--dart-define-from-file=.wantok/local-android.json`; the emulator config contains `10.0.2.2` and local dev settings. Smoke/reference samples are deliberately ON here, with visible `S` markers and read-only details; default OFF for normal builds.

Once built, copy the APK to an independent dated folder under `D:\Wantok_Project_Backups` and verify: archive has `lib/arm64-v8a/libflutter.so` and does NOT include an x86_64 Flutter engine; hash and size; no configured local Supabase URLs, sensitive developer file, service-role secrets or signing keystore. Do not assume compatibility with a specific model/OS until tested on the handset.

## Current source/build checkpoint — 9 October 2026

**Source/tests PASS, downloadable ARM64 APK NOT YET BUILT.** Focused tests 4/4 pass both with samples ON and OFF; 7 Flutter analysis targets, 75 client + 3 Admin + 1 Tech widget tests and 35 SQL files/767 database assertions passed. Three cautious local ARM64 build attempts were blocked by Windows Gradle-generated output locks: `cleanMergeDebugAssets`, then `mergeDebugNativeLibs` and again `cleanMergeDebugAssets`. Only generated intermediates were cleared after stopping the Gradle daemon; no security settings, AVD, Supabase data or source imagery were altered. This README specifies the **future** successfully built artifact, not an existing downloadable APK.

The full Explore x86_64 emulator APK is preserved independently at `D:\Wantok_Project_Backups\wantok-explore-emulator-current-1ccd640-20261009.apk` (SHA-256 `15DDB5FA4892AA121C8AE783C6DB8EF10D7707163CAC38481134DA1731D4C16D`), but **MUST NOT** be supplied as an ARM64 phone beta. Next: investigate file locks and create an isolated clean Gradle output, rebuild, inspect ARM64 engine/no emulator URLs and archive the actual APK before attempting physical HONOR acceptance.

## HONOR phone installation precautions

Transfer the **offline ARM64 preview APK** (not the emulator `wantok-android-prior-explore-20261009.apk`) by trusted USB or local transfer. Check its SHA-256. Open from Files and, if prompted, allow installing an unknown app **for that file manager only**; disable that permission afterwards. Use only the developer-produced APK, and do not defeat system security warnings.

The APK is debug signed and may share the normal Wantok application ID. If another Wantok build is installed with a different signing certificate, **do not uninstall or clear its data** simply to make this preview install: first plan an isolated application ID/signing migration or back up app data with informed approval.

## Outstanding acceptance

- [ ] Actual HONOR handset ARM64 installation/launch, screen widths, Android version, memory, display cutouts and permission prompts.
- [ ] Approved reachable, TLS-protected **staging** backend and test account.
- [ ] **Functional** signed-in phone/Web provider discovery/ratings/Saved, Account, Inbox, Track, Wallet preview, Wantok Agent handoff acceptance, with no money movement.
- [ ] Official mobile package identity, debug-to-release signing migration, update/distribution policy.
- [ ] CX1 consolidated acceptance before T2.4; general goods marketplace, sponsored promotions, ads, global market, travel and real document uploads remain separately gated.
