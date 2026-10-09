# HONOR Android ARM64 — OFFLINE Visual Preview Beta

Date: 9 October 2026. Environment: EAGLT02 Windows only. **Phone-preview source checkpoint: `c983cfb`** on `feature/flutter-platform-v1`; final APK from a detached and locally customised build-only worktree. Not yet tested on the physical HONOR handset.

## Why there are two Android beta types

The prior `wantok-android-prior-explore-20261009.apk` is a **debug-signed, emulator x86_64 Flutter engine** build using `SUPABASE_URL` host `10.0.2.2`. It cannot serve as a functioning real-Android handset beta; it is also the PRE-Explore version.

A **functional Android beta** needs an approved reachable **HTTPS staging** Supabase Auth/API URL (not `10.0.2.2`), a non-production test account and data, correct mobile sign-in redirects, network/TLS checks, and app signing/distribution decisions. Do not expose EAGLT02's local Supabase or its developer keys to the Internet or use the physical phone to test privileged provider review/payment routes.

### Safe first deliverable — offline visual beta

An opt-in compile-time `WANTOK_PHONE_PREVIEW=true` entry in `apps/wantok_app/lib/main.dart` starts `WantokPhonePreviewApp` **before calling `WantokBackend.initialize()`**. Without the flag, normal production/development flows remain unchanged. This mode intentionally has **no backend credentials, Supabase connection, auth, real providers, submitted booking, live chat, location request or payment movement**.

The visual shell displays a conspicuous **OFFLINE PREVIEW** warning; approved green/gold brand and original Vanessa/scenic/category images; five navigation destinations Home / Services / Explore / Track / Wallet; header Inbox/Profile buttons that explain the disabled state; photo-only sample service categories; and the **existing** Explore page with its original 12 `S`-marked Reference Screen Samples. Track and Wallet explicitly say their real features require secure staging. Clicking category/sample content never submits real bookings or approvals.

The preview is only an illustrative UX review. It is **not equivalent to the full authenticated Wantok Services app**, cannot verify live use, and must not be distributed as a release. The final isolated build's **merged Android manifest was verified to request neither Internet nor location permissions**; those source overlays are worktree-only, NOT changes to the normal app manifest. The debug signing key is development-only.

## Reproduce the verified offline ARM64 preview

The final verified artifact lives at:

`D:\Wantok_Project_Backups\WantokServices-HONOR-OfflinePreview-arm64-20261009.apk`

Build from the existing **detached** `D:\Wantok_ARM64_Build_20261009` worktree at source SHA `c983cfb` on EAGLT02. The main feature branch and normal Android source are unchanged. The isolated worktree has these **build-only** adjustments (not committed to the main repository):

1. `apps/wantok_app/android/gradle.properties`: append `kotlin.incremental=false` to avoid Kotlin plugin source roots differing between `C:\Users\Mansfield\AppData\Local\Pub\Cache` and the `D:\` worktree.
2. `apps/wantok_app/android/app/build.gradle.kts`: set the **debug** `applicationIdSuffix = ".offlinepreview"`.
3. `apps/wantok_app/android/app/src/main/AndroidManifest.xml`: label `Wantok Preview` and use `tools:node="remove"` on Internet, coarse-location and fine-location permissions.
4. `apps/wantok_app/android/app/src/debug/AndroidManifest.xml`: remove the default debug-build Internet permission, including its hot-reload capability. The merged final APK manifest has **no Internet or location permission**. Do not modify the production/release manifest to achieve this.

Build in the isolated worktree with existing Flutter/SDK:

```powershell
[Environment]::SetEnvironmentVariable('ProgramFiles(x86)', 'C:\Program Files (x86)', 'Process')
[Environment]::SetEnvironmentVariable('ProgramData', 'C:\ProgramData', 'Process')
Set-Location 'D:\Wantok_ARM64_Build_20261009\apps\wantok_app'
& 'D:\Development\flutter\bin\flutter.bat' build apk --debug --target-platform android-arm64 --dart-define=WANTOK_PHONE_PREVIEW=true --dart-define=WANTOK_SMOKE_DATA=true
```

Never supply `--dart-define-from-file=.wantok/local-android.json` or any secret credential. S-marked sample/reference imagery is deliberately ON and read-only; normal builds default OFF.

The generated file is `build\app\outputs\flutter-apk\app-debug.apk`. Verify with Android `aapt`, `apksigner`, ZIP engine inspection and SHA-256 before distribution. The final APK has `lib/arm64-v8a/libflutter.so` but not an x86_64 Flutter engine; some other plugin libraries still have multiple ABIs. This is **not** a signed release and has **not** been accepted on an actual HONOR handset.

## Verified build checkpoint — 9 October 2026

- **Source tests PASS:** focused offline phone-preview widget tests 4/4 in both default and sample modes; full Flutter suite **7 clean analysis targets, 75 client + 3 Operations Admin + 1 Technical Control tests PASS**; PostgreSQL **35 files / 767 assertions PASS** at commit `c983cfb`.
- **Packaging PASS on EAGLT02:** isolated worktree avoided the main checkout's generated-folder locks. The first new build exposed Kotlin incremental-cache root mismatch (`C:` Pub Cache vs `D:` worktree); adding worktree-only `kotlin.incremental=false` fixed the failure. A separate preview package with Internet/location permissions removed also builds successfully. No original project configuration, account, Supabase data or emulator app was overwritten.
- **Final file:** `D:\Wantok_Project_Backups\WantokServices-HONOR-OfflinePreview-arm64-20261009.apk`, **105209491 bytes**, SHA-256 `8C9C135659AABF6010B13E580E69511673B7CDF11524B4897E2C936A150B6BCE`. Independent checksum sidecar: `WantokServices-HONOR-OfflinePreview-arm64-20261009.sha256`. Exact detached-worktree Gradle/Android manifest build-only diff retained at `D:\Wantok_Project_Backups\WantokServices-HONOR-OfflinePreview-build-only-20261009.patch` (SHA-256 `AE5E8D2EAA15CD73308854340D82C50F8BC1251F746699815A753330C1B464AD`). Main source branch never adopted these experimental build settings.
- **Archive/security checks:** Android package `io.wantok.service.offlinepreview`, label `Wantok Preview`, minSdk **24**, targetSdk **36**, signed with Android **debug** certificate and verified via `apksigner`. Includes `lib/arm64-v8a/libflutter.so` with **no x86_64 Flutter engine**. Preserves the original Vanessa/scenic photo assets. Merged manifest requests **no Internet/coarse/fine-location permission**. Targeted scans of the compiled Dart kernel did not find `10.0.2.2`, `127.0.0.1:54321`, `localhost:54321` or `192.168.121.`; no .env, emulator settings or secret-key files were packaged. Such checks do not replace a professional security review.
- **Historic x86_64 emulator APK remains backed up** as `D:\Wantok_Project_Backups\wantok-explore-emulator-current-1ccd640-20261009.apk` (SHA-256 `15DDB5FA4892AA121C8AE783C6DB8EF10D7707163CAC38481134DA1731D4C16D`). **Do not transfer that emulator APK to the HONOR handset.**

**HONOR installed, initial visual-display check PASS (owner screenshots, 2026-10-09):** six screenshots from the real phone show Home, Services, scrolled Explore photographic gallery, Track, Wallet, and the `Service Listing (Food)` sample detail. The green/gold branding, original Vanessa/scenic/category artwork (where pictured), five bottom tabs, S-labelled sample cards, and offline-only disclaimer display. The screenshots are retained in the conversation, not embedded into GitHub. **Open device QA:** category labels `Home Services` and `Water Transport` truncate in the three-column grid; nav labels are crowded at the observed scaling; inspect bottom SafeArea/scroll inset on the Food Listing sample detail. Complete Home footer and all twelve gallery tiles not evidenced in this set, and phone Android version/permission prompts not verified. No user-facing redesign or source adjustment has yet been approved. Functional sign-in still requires an approved HTTPS staging backend. The offline app is deliberately **not** a functional beta.

## HONOR phone installation precautions

Transfer the **offline ARM64 preview APK** (not the emulator `wantok-android-prior-explore-20261009.apk`) by trusted USB or local transfer. Check its SHA-256. Open from Files and, if prompted, allow installing an unknown app **for that file manager only**; disable that permission afterwards. Use only the developer-produced APK, and do not defeat system security warnings.

The final APK is Android debug signed, but intentionally uses **a DIFFERENT package ID**, `io.wantok.service.offlinepreview`, and app name **Wantok Preview**. It can coexist with `io.wantok.service` without replacing normal app data. Do not uninstall or clear an existing Wantok installation. Updates to this preview must retain its distinct package ID and signing identity; a later proper release will have a separate approved signing/distribution process.

## Outstanding acceptance

- [ ] Actual HONOR handset ARM64 installation/launch, screen widths, Android version, memory, display cutouts and permission prompts.
- [ ] Approved reachable, TLS-protected **staging** backend and test account.
- [ ] **Functional** signed-in phone/Web provider discovery/ratings/Saved, Account, Inbox, Track, Wallet preview, Wantok Agent handoff acceptance, with no money movement.
- [ ] Official mobile package identity, debug-to-release signing migration, update/distribution policy.
- [ ] CX1 consolidated acceptance before T2.4; general goods marketplace, sponsored promotions, ads, global market, travel and real document uploads remain separately gated.
