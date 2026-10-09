# HONOR Full Emulator-Interface Demo — Offline Visual Review

**Owner request, 9 October 2026:** use the complete emulator screen layout on the HONOR with demonstration data, not the former simplified six-category preview.

## Design

- Main screen widgets reused unchanged in appearance: ClientHome, ServicesHubPage, ExplorePage, ActivityPage, WantokPayPreviewPage, and MessagesPage. Top Inbox/Profile and Home / Services / Explore / Track / Wallet navigation preserved.
- Vanessa's original photograph, scenic PNG Home footer, all standard category artwork, the existing 12 reference scene tiles and pinch-adaptive 2/3-column grids are preserved.
- The explicit WANTOK_PHONE_PREVIEW flag is OFF by default for the normal Flutter app. Offline preview boot skips Supabase initialisation entirely. WANTOK_SMOKE_DATA=true is used only for explicitly labelled S-marked demonstration screens.
- OfflineDemoCatalogue supplies 17 in-memory category examples derived directly from ReferenceServiceCategories. All identifiers use SMOKE_20261008_ prefixes. No database writes, real provider approval, booking, payment, ad creation or bank balance occur.
- Opt-in demoMode for real Home and Services intercepts service/provider/saved navigation before repository access, replacing it with clearly marked photo reference detail pages and harmless explanations. ActivityPage uses an injected empty reservations loader and read-only timeline, and MessagesPage injected empty threads/help loaders and an offline Agent explanation.
- Existing VendorHome is used in either explicitly fake applicant or SAMPLE approved-vendor layout for owner visual assessment. This does not grant vendor status, expose role-protected data, approve accounts, enable listings or payments.
- Genuine emulator screens requiring backend data will still differ in content: real providers and ratings, account security, authenticated Inbox/support, live reservations, advanced Agent, and vendor jobs/payment/advertisements cannot be demonstrated as real without separately approved HTTPS staging.

## Safety, tests, distribution

- Run focused widget tests in default and smoke-enabled modes, full scripts/flutter/check.ps1, npm run db:test, and git diff --check.
- Build only in a detached EAGLT02 worktree from validated committed source; use the previously verified worktree-only Kotlin incremental compiler workaround and Android offline manifest/package override. Do NOT modify regular production Gradle signing or Internet permissions.
- The HONOR preview uses io.wantok.service.offlinepreview rather than io.wantok.service, remains debug signed, and must have no Internet or location permissions, no emulator-only 10.0.2.2 backend address, and an ARM64 Flutter engine.
- Preserve prior APK and original emulator session, publish only reviewed code/docs on the existing feature branch, and archive APK/checksum/local Git bundle independently at D:\Wantok_Project_Backups.
- Physical HONOR side-loading/visual acceptance and signed-in Web CX1 remain distinct outstanding checks.
## Verified ARM64 build — 9 October 2026

- Tested source SHA `a6b164a9305741c2e210134bd4055e79d1507ee3`, isolated build worktree `D:\Wantok_ARM64_FullInterface_20261009` with build-only Kotlin/Android debug patch; normal repository configuration unchanged.
- Verified preview APK: `D:\Wantok_Project_Backups\WantokServices-HONOR-FullEmulatorInterface-OfflineDemo-arm64-20261009.apk`, **105229563 bytes**, SHA-256 **`755F08A5A5B8B6F052D348A682E85671936225FF01F59CCD77BC5AFE228920AB`**. `.sha256` file and `WantokServices-HONOR-FullEmulatorInterface-build-only-20261009.patch` (SHA-256 `AE5E8D2EAA15CD73308854340D82C50F8BC1251F746699815A753330C1B464AD`) are archived beside it.
- Package name `io.wantok.service.offlinepreview`, app label `Wantok Preview`, Android 7+ (minSdk 24), valid debug signature, ARM64 Flutter engine, no Internet/location permission or inspected emulator-local backend string/secret config assets in APK, original Vanessa/scenic images preserved.
- Flutter regression: seven analysis targets clean, **81 client tests + 3 Operations Admin + 1 Technical Control** PASS. All **35 SQL files / 767 assertions** PASS. Six dedicated phone demo tests PASS with and without sample mode.
- The APK has **not yet been installed or accepted on the physical HONOR handset**. Its sample providers have explicitly marked names and zero fabricated reviews. Authenticated features remain disabled. Install this new preview over the previous Wantok Preview package without uninstalling the separate main application. After installation, inspect full Home (including the scenic footer), Services, Explore, Track, Wallet, Inbox, sample Account and Vendor, and the 2/3-column pinch behaviour. Real authenticated functionality requires approved HTTPS staging.
