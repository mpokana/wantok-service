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