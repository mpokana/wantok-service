# Wantok Services — Living Roadmap

**Updated:** 2026-10-10

## CX1 primary acceptance revised: category-first provider discovery — 10 October 2026

- [x] **Category-first source QA repeated:** 7 Flutter analyses, 94 Client / 15 Admin / 1 Technical tests, PostgreSQL 35 SQL / 767 assertions PASS, plus real signed-in Android read-only interaction. No code changes or database records introduced.
- [x] **Android authenticated category-first PASS (no keyword):** EAGLT02 `emulator-5554`, Services → Browse providers → Specialist Services → Morobe → Lae → provider details, leaving free-text search **empty**; genuine eligible **Wantok QA Plumbing Services** card, sourced 5.0 (1), detail with approved **QA Plumber & Maintenance**, Lae/Morobe and Quote listing. This is category-filter functionality and does NOT restrict the whole category to plumbers. No booking/Saved/review/data mutations.
- [x] **Distinguish workflows:** Home → Specialists opens **Describe the job / Post request** (inspected but never submitted); Services → Browse providers opens the **provider directory/filter**. Do not merge or relabel one as the other without a separate UX decision.
- [x] **Keyword-specific regression remains SECONDARY:** `plumber` + category/location was already Android-tested. Future text queries for electrician/mechanic/ICT, etc. require legitimately discoverable approved records; do not manufacture them.
- [ ] **Primary Web CX1F sign-off:** at signed-in Client `:3000`, navigate Services → Browse providers → Specialist Services → Morobe → Lae **without query**, open provider detail, inspect existing read-only Saved state, then Account/Inbox/Track/Wallet/Wantok Agent. Record actual found/empty/error and authorised RLS behaviour. **Android PASS is not Web PASS.**
- [ ] **Category matrix (additional evidence, not prerequisite synthetic data):** Taxi & Transport, Home Services, Food & Restaurants, Groceries, and other current service families: confirm correct category navigation and realistic loaded/empty/unavailable states; do not infer there are approved providers. HONOR physical responsive checks remain OPEN.
- [ ] CX1 remains IN PROGRESS; T2.4 and money/approval/evidence upload/live staff reply/model gateway gates stay deferred.

## CX1I owner browser evidence and read-only queue reliability — 10 October 2026

- [x] **Authenticated Support & Inquiries queue DISPLAY PASS:** owner screenshot at `:3200` confirms signed-in page, 1 real existing Open CX1 QA handoff, UTC submission date, five filter chips and Refresh button. Neither active filter switching nor Refresh click is established by the screenshot.
- [x] **Refresh/Retry Flutter assertion FIXED:** replace Future-returning `setState` callback with synchronous assignment, ensuring errors can retry without assertion; correct 1-request singular grammar. Eight Support widget tests cover widths 390/850/1440, all five status filters, refresh re-fetch, retry recovery, previous failure/error state. No RLS/schema/business writes.
- [x] **Source validation PASS:** seven Flutter analysis targets, 94 Client + 15 Admin + 1 Technical widget tests, 35 SQL/767 pgTAP assertions, and clean source changes. No live data mutations.
- [x] **Admin-only deployment COMPLETE:** verified GitHub source commit `a69d366` and independent full-history bundle, advanced the clean detached `D:\Wantok_Web_Admin_20261010` worktree from `3342ac0` to `a69d366`, gracefully quit its original Flutter server and restarted only loopback `:3200` with the original local backend defines and sample fixtures OFF. Admin, Client `:3000` and Technical `:3100` all returned HTTP 200; emulator `emulator-5554` remains connected. Browser hard-refresh is needed to see the corrected counter; live click-through post-restart has not been observed.
- [ ] **Remaining CX1:** authenticated Client **Web** primary category-first QA (Services → Browse providers → Specialist Services → Morobe → Lae, **blank search**, provider detail/Saved/Account/Inbox/Track/Wallet/Agent); independent `plumber` text search is SECONDARY; HONOR physical/full Android visual check. Staff responses/assignments, model chat, approval/money/evidence movement remain gated; T2.4 deferred.

## CX1 functional Android evidence + Admin browser shell — 10 October 2026

- [x] **Authenticated browser Admin shell/sidebar PASS** at `127.0.0.1:3200`: live Operations overview, existing signed-in session, Support & inquiries navigation visible; private screen evidence local-only.
- [x] **Real signed-in Android CX1F provider-discovery PASS:** `plumber` search, Specialist Services → Morobe → Lae, QA provider 5.0 (1), provider detail, approved `QA Plumber & Maintenance` Quote listing. No Saved, booking or other user-data writes. Existing emulator userdata preserved.
- [x] **Other Android read-only journey PASS:** Inbox Services (0) / Help & support (1), Track retained completed Specialist booking/Edit review entry, Wallet K0.00 inactive preview, and Profile My Settings/Wallet/Vendor menu. No sensitive request details read or edited. Installed Android Wallet is **blue**, while the newly approved Web style is **green**; update Android only through a verified, non-destructive detached-worktree build and retain this parity as an open check.
- [x] **Admin queue browser DISPLAY acceptance:** owner-provided authenticated screenshot proves the existing 1-open handoff renders; filter and Refresh controls are visible. Interaction through each filter/Refresh remains an optional browser follow-up, although all controls pass synthetic Flutter tests. Private requester text and cookies are not captured or exported.
- [ ] **Still pending Client Web CX1F:** personally signed-in browser search/filter/detail/read-only Saved and Account/Inbox/Track/Wallet/Wantok Agent, then tablet/handset acceptance. Android PASS cannot close Web gate. Real staff replies/assignments, live model gateway and all payment/provider-approval/evidence-intake gates remain disabled.
- [ ] T2.4 starts only after CX1 acceptance, not merely after this evidence.

## CX1I deployment checkpoint — 10 October 2026

- [x] **Read-only Operations Admin Support & Inquiries** deployed on EAGLT02 `http://127.0.0.1:3200/` from source `3342ac0` with original RLS/auth; HTML and Flutter bootstrap HTTP 200, backend read-only request count reports 1 pre-existing open handoff, 7 clean analysis targets, 94 Client + 12 Admin + 1 Technical widget tests and 35 SQL files/767 assertions PASS. `:3000` Client and `:3100` Technical Control still HTTP 200. No schema/role/payment changes.
- [x] **Authenticated queue rendering** accepted from owner screenshot later on 10 October 2026 (see top); HTTP success alone was insufficient at the older checkpoint. Full CX1F authenticated Client Web search/filter/detail/Saved/Account/Track/Inbox/Agent QA and physical HONOR acceptance remain OPEN; T2.4 deferred.

## CX1 owner visual acceptance + support triage foundation — 10 October 2026

- [x] **Owner-approved responsive Client presentation:** after reviewing live, signed-in EAGLT02 Client screenshots at `127.0.0.1:3000`, owner approved the updated enterprise **Home, Services, Explore, Track, Wallet and Inbox** desktop styling and responsive design direction on 10 October 2026; tablet/mobile have automated layout coverage but not physical-device sign-off. The previous visual-approval checkbox in the historical section is superseded by this PASS; it is not proof of authenticated end-to-end provider discovery, OAuth, payment, every populated state, or actual HONOR acceptance.
- [x] **CX1I read-only Operations support intake:** (verified: 7 clean Flutter analyses, 94 Client + 12 Admin + 1 Technical tests, 35 SQL/767 assertions) an authenticated Admin-only **Support & Inquiries** navigation destination queries `ai_agent_handoff_requests` under existing Supabase RLS, shows a bounded recent queue, open/assigned/resolved/closed status filters and safe retry; no new users/roles/schema, no staff responses, no status mutations and no impersonation. Existing agent-owner Inbox remains separate. Local Admin browser QA and staff workflow acceptance remain pending.
- [ ] **CX1 functional gate (updated):** authentic signed-in Web **Services → Browse providers → Specialist Services → Morobe → Lae with the keyword search blank** → sourced existing QA provider detail + read-only Saved state; keep `plumber` text search as a separate secondary check; Account privacy, Inbox Help & support, Track completed booking/review, Wallet preview and Agent entry/handoff; capture verified real browser evidence without exporting any Chrome cookies or writing new records. **CX1 IN PROGRESS; T2.4 DEFERRED.**
- [ ] **CX1I further step:** authorised staff assignment/status update with audit, responses to owner Inbox, and approved live human-chat capability remain unimplemented. Model chat and payment rails remain disabled.

## Unified signed-in Client desktop pages — 10 October 2026 (source PASS; browser review pending)

- [x] **Consistent responsive shell:** `ResponsiveClientCanvas` centres all six signed-in Client destinations on wider screens; Home, Services, Explore and Wallet have a 1480 px maximum; activity/Track and Inbox use a 1160 px reading width. Below 700 px the original handheld flow remains unchanged, and tablet uses available width.
- [x] **Services:** the canonical category grid uses a maximum 245 px tile width within the same centred desktop canvas (not four stretched columns). Existing catalogue search, filters, service navigation, genuine provider data and demo-mode safeguards unchanged.
- [x] **Explore, Track, Inbox, Wallet:** Explore now has a photographic 3/2/1-column editorial grid using original local PNG assets; content is clearly **inspiration, not live bookable listings**. Track and Inbox have green/gold enterprise headers with real booking/conversation views and empty states intact. Wallet's preview hero follows green/gold branding but remains **K0.00 preview, rails inactive**; no fictitious transactions.
- [x] **Focused validation:** `enterprise_client_pages_test.dart` covers 1800 px Services tile width, 1600 px Explore, 390 px Explore/text scaling, 1560 px Track+Inbox, and 1600 px Wallet. New layout has no role, Supabase, payment, review, approval, messaging or transaction mutations.
- [x] **Owner visual review (approved 10 Oct 2026):** reviewed refreshed signed-in Client at `127.0.0.1:3000` following the validated Client-only restart. Technical `:3100`, Operations `:3200` and emulator intentionally unchanged. Full CX1 client journey sign-off still separate, T2.4 remains gated.

## Responsive desktop Client Home correction — 10 October 2026 (source PASS, browser acceptance pending)

- [x] **Desktop Chrome issue addressed:** at 1600 px, the existing three-column mobile photo grid previously stretched to enormous landscape strips. Client Home now uses a **centred maximum 1480 px content region**, photographic tiles with maximum cross-axis size **205 px**, and a desktop-only **Venenssa** provider hero before popular categories. Desktop >=1120 px moves Home/Services/Explore/Track/Wallet to the header; the mobile bottom navigation remains at narrower widths.
- [x] **Mobile/tablet retained:** 390 px maintains original two-/three-column pinch/gesture surface; 900 px shows the width-conscious photographic grid and standard touch navigation; the connected categories/booking links, provider results and Account/Inbox/Wallet routes remain unchanged.
- [x] **Regression:** seven Flutter analysis targets PASS; **88 client + 7 Operations Admin + 1 Technical Control tests** PASS; database **35 SQL/767 pgTAP assertions** PASS. New `enterprise_home_responsive_test.dart` covers 390/900/1600 px and header navigation at 1500 px. Untracked developer-created `supabase/snippets/` is explicitly **out of scope and untouched**.
- [x] **Owner desktop visual acceptance (10 Oct 2026):** loopback Client Web `http://127.0.0.1:3000/` was restarted from the verified source and owner approved the layout; this is not full CX1 functional or physical-device acceptance. Technical `:3100` and Operations Admin `:3200` retain the user's confirmed logins, separate roles and code. Continue remaining desktop Explore/Track/Wallet/Inbox polish later; payment and real vendor actions remain gated.

## Enterprise responsive catalogue and Operations dashboard — 10 October 2026 (source PASS; device review pending)

- [x] **Services desktop/tablet catalogue:** on existing signed-in Services, widths >=700 px now display an enterprise marketplace banner, local service-photo grid (4 desktop / 3 tablet / 2 compact columns), functional category-search/filter chips and a provider discovery panel. Tap destinations still pass through the original `ServicesHubPage`/approved backend routes; missing categories remain informational, not invented providers. Narrow mobile preserves the existing pinch-adaptive entry and the approved **Venenssa** hero photograph (legacy bundled asset filename intentionally unchanged).
- [x] **Operations Admin frontend/backend integration:** existing RLS-protected, role-gated AdminShell now has green desktop sidebar, tablet rail and mobile drawer; overview uses read-only Supabase provider applications, listing reviews, active bookings, recent booking categories and audit events. Financial figures, regional analytics and scheduled modules are clearly labelled **not available**. No sample income/provider records, schema migrations, role grants, upload access or payment activation.
- [x] **Source regression PASS:** 7 clean Flutter analyzer targets; 84 client + 7 Operations Admin + 1 Technical Control widget tests PASS; 35 pgTAP SQL files / 767 assertions PASS; responsive widget tests at Services 840/1440 px and Operations 390/900/1440 px, plus 150% text-scale client regression fixed. `git diff --check` required for commit.
- [ ] **Live visual acceptance / further desktop Home, Explore, Track, Wallet, Inbox polish:** owner-provided PNG reference mockups guide subsequent client UI milestones; these are not yet a pixel-perfect full-screen implementation. Test signed-in browser and admin account against permitted local Supabase before marking CX1 acceptance. Emulator AVD `Medium_Phone_API_36.1` was restarted in active Windows Session 2 without resetting data; rebuilding refreshed client code in a detached worktree is pending after initial main-checkout Gradle asset-lock failure.

## CX1 signed-in Web QA on EAGLT02 — 9 October 2026 (GATE OPEN)

- [x] **Local Web and guest responsive baseline verified:** EAGLT02 clean `feature/flutter-platform-v1` at source `67cad66`. Local Supabase stack responding; real Flutter Web app served **loopback-only** on `http://127.0.0.1:18108/` from a detached `D:\Wantok_CX1_Web_QA_20261009` worktree. An isolated Chrome DevTools guest profile (not the user's existing Chrome profile) rendered the actual sign-in page at **320, 390 and 1280 px** with the approved Wantok Services/Vanessa imagery, green brand, email/password form and create-account link. Human-reviewed screenshots under ignored `.wantok\cx1-guest-cdp-{320,390,1280}.png` show no visible clipping; narrow text wraps rather than overflowing. This is **guest visual-only**, NOT sign-in or provider QA. Baseline checkpoints **PASS**: 7 Flutter analyses clear, 81 client tests + 3 Operations Admin + 1 Technical Control tests, PostgreSQL 35 files / 767 assertions; no app code or schema changes.
- [ ] **Signed-in Web CX1F and client journeys:** a separately isolated **headed Chrome QA browser** is open at `http://127.0.0.1:18108/` pending owner manual sign-in. Do not collect credentials/cookies, copy existing Chrome profile, create test accounts, mutate Saved/reviews or send human-help messages to bypass login. Then perform provider `plumber` query, Specialist Services → Morobe → Lae, rating/save/detail (read-only Saved inspection), Account, Inbox, Track, Wallet, Wantok Agent/handoff, and responsive desktop/mobile authenticated screenshots. Record PASS/FAIL/BLOCKED individually in `docs/CX1_CLIENT_EXPERIENCE_GATE.md`; **CX1 stays IN PROGRESS, T2.4 deferred**.
- [ ] **Development-network containment review:** the local Supabase Docker stack currently reports host listeners on `0.0.0.0` for some development ports (e.g. API/Studio/Postgres). No external reachability was tested and no firewall/container setting was changed. Review host firewall and restrict binding to loopback **only after explicit owner approval**; do not expose Studio/PostgreSQL publicly or disrupt existing data.

## CX1 complete emulator-interface HONOR offline demonstration — 2026-10-09

- [x] **Owner-approved scope:** replace reduced six-category HONOR-only layout with the **real** emulator Home, Services, Explore, Track, Wallet and Inbox Flutter widgets using opt-in, read-only sample data. Preserve Vanessa/scenic PNG cards, original category photography, all twelve S-marked Explore reference scenes, green/gold brand, five bottom tabs and header Inbox/Profile including 2↔3 finger-pinch density.
- [x] **Safety design:** demo fixture category catalogue in memory, injected service/Track/Inbox loaders, no Supabase initialization or developer backend URL. Real component navigation into provider search, booking, saved items, messages and Agent is intercepted to S-marked sample/detail or harmless explanatory pages. Existing VendorHome applicant and illustrative approved-vendor views are for visual review ONLY, without role assignment. Full authenticated provider records, real prices, service orders, ad sales, payment movement and approvals still need separately authorised HTTPS staging.
- [x] **HONOR full-interface offline ARM64 debug build VERIFIED:** detached worktree `D:\Wantok_ARM64_FullInterface_20261009` from commit `a6b164a`; verified APK `D:\Wantok_Project_Backups\WantokServices-HONOR-FullEmulatorInterface-OfflineDemo-arm64-20261009.apk` (105229563 bytes, SHA-256 `755F08A5A5B8B6F052D348A682E85671936225FF01F59CCD77BC5AFE228920AB`). Separate `io.wantok.service.offlinepreview` package and `Wantok Preview` label, minSdk24, verified debug signing, ARM64 Flutter engine, original photographs, no Android Internet/location permissions or checked emulator URL literals / config assets. The standalone build-only Gradle patch and SHA-256 sidecar are archived beside the APK; no regular Android build config or existing phone/emulator data modified. Full source checkpoint: **7 Flutter analyses clean, 81 client + 3 Operations Admin + 1 Technical Control tests PASS; 35 SQL files / 767 assertions PASS; six focused demo tests pass with samples OFF/ON**.
- [ ] **Real HONOR visual acceptance of this NEW full-interface build:** owner installs over the previous Wantok Preview and reviews all six real widget layouts, 17 in-memory example category entries, two S-labelled sample provider cards with zero fabricated reviews, original Vanessa/scenic imagery, sample service details, sample Account/Vendor preview and pinch-dynamic grids. This is NOT a working connected app; CX1 signed-in Web QA and authorised HTTPS staging are separate gates before T2.4. See docs/HONOR_FULL_INTERFACE_DEMO.md.

## CX1 shared pinch-adaptive grids and Profile/Vendor entry — 2026-10-09

- [x] **Owner-approved shared interaction:** category/photo/icon grids in Home, Services (catalogue and See all), Explore reference gallery, and sample preview screens adapt to exactly **2 or 3 columns**; default density follows usable width and large-text scaling. Two-finger pinch **in** selects 3 compact columns, spread **out** selects 2 larger columns. A common notifier shares the choice across grid screens in one client session. One-finger scrolling and regular card taps are unchanged. Detail/forms/lists are not forced into columns. Category text supports two lines. Distinct app build/test still required before HONOR acceptance.
- [x] **Profile dropdown:** the icon beside Inbox now offers **My Settings** (existing account/preferences/security), **Wallet** (Wantok Pay preview only) and **Vendor**. Signed-in, server-authorised providers/drivers go to their existing vendor dashboard; unapproved users go to existing provider application. No automatic approval or bypass of backend RBAC. The offline HONOR design-preview displays same menu with explanatory, nonfunctional My Settings/Vendor sheets and visual Wallet navigation.
- [x] **Vendor panel clarity:** approved vendor dashboard includes entry to existing provider verification/profile details; existing Jobs, Listings, Food/Groceries commerce and industry consoles remain governed by existing authorisation. General-product storefront/sales CX1G, in-app sponsored promotion CX1H, managed external Wantok Ads ADS1 and real earnings/payouts remain **PLANNED / DISABLED**, shown as informational non-action cards rather than fake functioning controls. No real money movement, ad charges, inventory approval, applicant uploads or database role changes.
- [x] **Source regression:** 7 Flutter analysis targets clean, **79 client + 3 Operations Admin + 1 Technical Control widget tests PASS**, 35 PostgreSQL files / **767 pgTAP assertions PASS**; focused pinching 2↔3 and unauthorised Vendor entry checks pass. No DB/schema or permissions changed.
- [x] **HONOR updated visual beta APK verified:** separate detached clean-build source `340f1fa260a4f131f5d0a1c1c9ac449820a841f7` in `D:\Wantok_ARM64_Build_20261009_v2` with the saved build-only patch (Kotlin incremental off, separate `io.wantok.service.offlinepreview` package, `Wantok Preview` label, removed network/location permissions), `android-arm64`, `WANTOK_PHONE_PREVIEW=true`, `WANTOK_SMOKE_DATA=true`, **no emulator/backend credential defines**. New APK `D:\Wantok_Project_Backups\WantokServices-HONOR-PinchProfile-OfflinePreview-arm64-20261009.apk`, **105218839 bytes**, SHA-256 `F1CCFFA22C7F8DE03BD26918DAC189C87AD8D5C58D6709A8D27CA328BB4E2A6B`. `apksigner` verified, ARM64 Flutter engine and original photo assets confirmed; signing certificate matches prior offline preview, and no Android INTERNET/location permission. Debug-only, no backend and no money movement; previous preview retained.
- [ ] **Next acceptance:** owner updates existing `Wantok Preview` on HONOR **without uninstalling**, verifies two-finger pinch 2↔3 on Home, Services and Explore, shared grid density, My Settings/Wallet/Vendor menu, long-scrolling/safe-area and responsive text. Signed-in Web CX1 and approved HTTPS staging remain separate. CX1 stays **IN PROGRESS**; T2.4 later.

## CX1 new responsive grid, Profile menu and updated HONOR build (2026-10-09)

- [x] **Pinch-adaptive categories:** shared two-/three-column photo/icon grid across applicable Home/Services/Explore/HONOR visual-preview surfaces, auto-responsive to width and text size; two-finger pinch inward selects 3, spread outward selects 2 for the app session. Single-finger scroll/tap preserved. Approved photo assets remain unchanged; widget tests verify both gestures.
- [x] **Profile dropdown:** My Settings goes to existing profile/security, Wallet goes to Wantok Pay preview, Vendor goes to existing application/status if unapproved or role-gated vendor dashboard if authorised. Vendor dashboard links to existing jobs/listings/commerce and **labels** ads, general-goods sales and settlements as pending gates; no permissions, approvals, transactions or real ads activated.
- [x] **New isolated HONOR debug offline-preview APK built/verified:** `D:\Wantok_Project_Backups\WantokServices-HONOR-OfflinePreview-PinchProfile-arm64-20261009.apk` SHA-256 `F1CCFFA22C7F8DE03BD26918DAC189C87AD8D5C58D6709A8D27CA328BB4E2A6B`, size 105218839 bytes. Distinct `io.wantok.service.offlinepreview` package; verified ARM64 Flutter engine and APK signature; no Internet/location permissions or emulator-only backend configuration. Build patch and hash sidecar backed up; normal emulator not reinstalled. Git source at `340f1fa` validated 7 analysis targets, 79 client + 3 Admin + 1 Tech Flutter tests and 767 SQL assertions.
- [ ] **Updated HONOR handset visual acceptance:** install this new APK *over the existing Wantok Preview package only* (never uninstall the real Wantok app), verify pinch on actual hardware at 2/3 columns, Profile menu, vendor sample explanation, text scaling and Android bottom safe-area; earlier six phone screenshots predate these changes. Full functional client QA and signed-in Web CX1 are still open; T2.4 remains gated.

## CX1 next milestone — HONOR Android ARM64 visual beta and Web acceptance (2026-10-09)

- [x] **Approved scope:** EAGLT02 source checkpoint `1ccd640` completed Home/Services/Explore separation, photo gallery relocation, green/gold design, Inbox beside Profile and five bottom tabs `Home · Services · Explore · Track · Wallet`; vendor registration remains inside Profile. Android emulator checked with opt-in S-marked samples.
- [x] **Device-build diagnosis:** prior `wantok-android-prior-explore-20261009.apk` is an x86_64 Flutter debug engine build for an emulator, compiled with backend host `10.0.2.2`. It is NOT a working physical-phone build; default Android production signing remains unconfigured and debug-signed. The existing local development Supabase must not be exposed to enable a phone test.
- [x] **HONOR offline phone-preview source and tests:** explicit `WANTOK_PHONE_PREVIEW=true` boot branch **before** Supabase init, approved photographic Home / Services / Explore, S-marked opt-in gallery, five tabs and conspicuous read-only warnings; no backend config, sign-in, bookings or payments. 4 focused phone tests PASS in both sample modes, 7 Flutter analyses clean, 75 client + 3 Admin + 1 Technical tests PASS, database 767/767 PASS.
- [x] **HONOR offline ARM64 packaging — COMPLETE on EAGLT02:** detached clean worktree at `D:\Wantok_ARM64_Build_20261009` from checkpoint `c983cfb`. Resolved the actual Kotlin compiler `C:` Pub Cache / `D:` project different-root error with **worktree-only** `kotlin.incremental=false`; built debug `android-arm64` with explicit `WANTOK_PHONE_PREVIEW=true`, `WANTOK_SMOKE_DATA=true` and **NO** emulator backend config. Final isolated build-only manifest/package adjustments create **Wantok Preview**, ID `io.wantok.service.offlinepreview` (coexists with normal app) and remove Internet/location permissions. APK contains ARM64 Flutter engine, authentic photographs and verified debug signature; local compiled snapshot scans found no listed emulator/loopback endpoint literals or sensitive file paths. SHA-256 `8C9C135659AABF6010B13E580E69511673B7CDF11524B4897E2C936A150B6BCE`, 105209491 bytes. Stored at `D:\Wantok_Project_Backups\WantokServices-HONOR-OfflinePreview-arm64-20261009.apk`. See `docs/HONOR_ARM64_PHONE_PREVIEW.md`. Normal source and emulator unchanged.
- [x] **Physical HONOR offline-preview installation and initial visual QA — 2026-10-09:** owner supplied six screenshots taken on the HONOR showing Wantok Preview Home, Services, Explore gallery (scrolled), Track, Wallet and an opened `Service Listing (Food)` sample detail. APK launches; green/gold brand, Vanessa photo and category imagery render; five client bottom destinations visible; sample `S` markers and **OFFLINE PREVIEW** warning persist; Track/Wallet remain explicitly inactive. This is a **physical-device launch and initial screen-display PASS only**, not a full functional or interaction acceptance; screenshots are evidence in the conversation, **not copied into public GitHub**.
- [ ] **HONOR responsive visual follow-up:** category labels `Home Services` and `Water Transport` truncate in the three-column phone grid; bottom-nav text looks tightly spaced at observed phone scaling; verify bottom/system navigation safe-area on scrolled Food Listing sample detail (last visible card partially behind navigation region). Obtain full Home scroll showing scenic Explore footer, reference gallery full set and small/large text scroll/interaction evidence. Propose two-column categories and adapted navigation labels, but **do not alter the approved UX without owner confirmation**. Confirm Android version and exact device details separately (screenshots do not establish these).
- [ ] **Final physical visual acceptance:** after agreed spacing fixes and screenshot recheck; still **offline-design-only**, debug signed and not a real account/booking/payment release.
- [ ] **Functional physical-phone beta gate:** obtain/approve a dedicated reachable HTTPS staging API/Auth endpoint (not local emulator `10.0.2.2`), signed mobile test accounts and non-production dataset, TLS/network controls, safe mobile signing/update/distribution and end-to-end tests. No public Supabase Studio, PostgreSQL, unrestricted Storage or real money movement. No secrets in Git.
- [ ] **Close CX1:** signed-in Web provider search/filter/rating/save/detail, Account/Inbox/Track/Wallet/Agent handoff, final Android/Web screenshots and documented acceptance in `docs/CX1_CLIENT_EXPERIENCE_GATE.md`. CX1 is still **IN PROGRESS**; T2.4 diagnostics follows acceptance, while CX1G/CX1H/ADS1/GLOB1/TRV1 remain planned.

## CX1 approved Explore restructuring (2026-10-09) — distinct destination and de-duplicated Home

- [x] **Bottom navigation update:** add fifth client tab **Explore** between Services and Track; resulting **Home · Services · Explore · Track · Wallet**; keep Inbox icon beside Profile. Provider registration stays in Profile, vendor navigation unaffected.
- [x] **Home:** move the existing photographic `Explore PNG and beyond` banner to the very bottom of the Home list, separated from Vanessa's existing green/gold provider card; clicking scenic card opens Explore, while Vanessa's card continues to open provider search.
- [x] **Services / Explore:** leave functional Services Categories and search on Services. Relocate all twelve S-marked photographic Reference Screen Samples to the new Explore page without duplicating previews on Services; preserve original assets and sample-detail previews. The gallery is still **opt-in developer-only**. Explore remains available with `WANTOK_SMOKE_DATA=false` through a photographic header, `Browse services` link and non-misleading placeholder copy.
- [x] **Regression gate:** focused tests in default and `WANTOK_SMOKE_DATA=true` modes PASS; **7 clean Flutter analysis targets, 71 client + 3 Operations Admin + 1 Technical Control tests PASS**; **35 SQL files / 767 assertions PASS**. Assets unchanged.
- [ ] **Remaining acceptance:** signed-in emulator and Web visual QA (especially navigational scrolling/small displays), rollout of real Explore experiences only when approved. CX1 remains in progress before T2.4. No live ads, applicant uploads, payment rails or provider approvals enabled.

## CX1 approved interface adjustment (2026-10-09) — green/gold navigation and Home consolidation

- [x] **Global design tokens:** replace bright-blue primary with forest green `#075D3F` / dark `#06482F` and use gold `#FFBD2F` accent; retain original photographic categories and Vanessa portrait/promo card unchanged.
- [x] **Owner-approved navigation placement:** Inbox button beside Profile in the header, **Home · Services · Track · Wallet** in the client bottom navigation; vendor bottom **Dashboard · Jobs · Listings · Me**, Inbox in header. Existing Account/Profile provider-registration and mode switching retained. No route removed.
- [x] **Reduced Home repetition:** remove horizontal category-chip rail (Popular Categories already provides navigation); keep distinct scenic PNG discovery and Vanessa local-provider photo promo, with the latter opening provider search. Services Categories remain functional catalogue navigation; the 12-screen photo Reference Gallery remains development-only, marked `S` and controlled by opt-in `WANTOK_SMOKE_DATA`.
- [x] **Local Android QA:** `Medium_Phone_API_36.1` session 1; new in-place debug APK built with developer-only photo `S` samples on, `MainActivity` foreground with Home/Services/Track/Wallet/Inbox/Profile accessibility labels. Existing emulator sign-in data not wiped or app uninstalled. Source tests 7 analysis targets, 72 Flutter tests and 767 pgTAP assertions PASS.
- [ ] **Remaining CX1 acceptance:** review visual details on signed-in Android and the signed-in Web search/filter/account/wallet/inbox journeys; T2.4 still deferred. Evidence uploads, reviewer access, approvals and money movement remain unchanged/disabled.

## Current security increment (2026-10-09) — read-only custody snapshot consistency, uploads SEALED

- [x] **Synthetic-only offline comparator:** WQE2 encrypted scratch candidate checked against separately supplied SQL-shaped manifest snapshot and claimed/withdrawn status. Flags file/metadata absence, claim mismatch, hash/tamper mismatch, withdrawn claims and interrupted states. A perfect match remains `snapshot_matches_still_pending_independent_reconciliation`, **not proof of custody or authority**. `npm run test:evidence` **85 PASS**, real ClamAV **6 PASS**, local PostgreSQL **35 files / 767 assertions PASS**.
- [x] **Android emulator preserved:** existing `Medium_Phone_API_36.1` launched without data wipe, installed Wantok Services `io.wantok.service` confirmed foreground by ADB. Docker Desktop process-environment issue fixed without system settings or volume changes. See `docs/EVIDENCE_CUSTODY_RECONCILIATION_DRYRUN.md`.
- [ ] **Still required:** authentic restricted server-side database snapshot query and claim-state verification, independent manifest-to-file outbox reconciliation, dedicated service identity/storage, managed keys/rotation, content sandbox, consent/privacy, retention/erasure, off-host audit, restore drills, authorised reviewer access. CX1 signed-in Web QA remains open before T2.4. Live applicant uploads remain disabled.

## Current security increment (2026-10-09) — metadata-linked custody and protected ACL lab, uploads SEALED

- [x] **Local schema only:** single-write, claim-receipt-bound custody manifest capturing bounded plaintext/ciphertext SHA-256 and file metadata under service-role-only RPC; all records remain `pending_independent_reconciliation`, without applicant grants, reviewer access, upload ability or provider approval. Local migration `20261009060000_custody_manifest_metadata.sql` applied; **35 SQL files / 767 pgTAP assertions PASS**.
- [x] **Offline synthetic bridge and ACL validation:** WQE2 synthetic envelope verifies digests and builds non-submitted manifest arguments (no database or Auth service connection). New read-only Windows verifier accepts an empty, inheritance-disabled NTFS lab with exactly SYSTEM/current EAGLT02 account FullControl; rejects the inherited project repository ACL. **73 unit tests + 6 real ClamAV tests PASS**. See `docs/EVIDENCE_CUSTODY_MANIFEST_AND_ACL_LAB.md`.
- [ ] **Not completed:** production-safe ACL/service account, real file/DB transaction and reconciliation outbox, interrupted-write recovery, KMS, actual consent, sandboxed PDF/image validation, off-host audit, retention/erasure and Operations Admin reviewer release. The manifest is **not proof that a file is held**, and the NTFS lab is not a production vault. CX1 signed-in Web QA remains open; T2.4 deferred.

## Current security increment (2026-10-09) — claim-bound offline crash-state prototype, uploads SEALED

- [x] **Local synthetic-only custody:** AES-256-GCM single-envelope authenticated claim/intent/account/application/check/key-ID metadata; exclusive non-overwriting hard-link publish, file `sync()` and read-only inspection of lock/pending/held crash states. Concurrent claims and injected stops before/after publishing tested: **71 scanner/custody unit tests PASS, 6 actual ClamAV integration tests PASS**. Pure local temporary fixtures only; see `docs/EVIDENCE_CUSTODY_OFFLINE_RECOVERY.md`.
- [ ] **Remaining release gates:** verified GoTrue claim-to-file execution, durable DB manifest/outbox, controlled retry after failures, independently accepted dedicated NTFS ACLs/Linux vault, KMS/key rotation and recovery, content normaliser sandbox, consent/privacy/legal holds/erasure, immutable off-host audit, authorised reviewer separation, power-loss and actual restore rehearsal. Scratch hard-link+file sync is not proof of durability/immutability and **does not permit actual applicant uploads**. CX1 stays open; signed-in Web QA precedes T2.4.

## Current security increment (2026-10-09) — ClamAV freshness preflight, uploads SEALED

- [x] **Internal quarantine default gate:** require loopback ClamAV `VERSION` to report signature age at most **48 hours** before `INSTREAM`; reject stale/missing/malformed/version responses, overlong replies, health failures and excessive clock skew before bytes are scanned. 72-hour absolute maximum policy; original injection seam remains test-only. Scanner freshness alone is not content sanitisation or approval. Unit **57 PASS** and actual ClamAV **5 PASS**, including EICAR. See `docs/EVIDENCE_SIGNATURE_FRESHNESS.md`.
- [ ] **Still blocked:** Auth/claim-to-file connection, safe retry/recovery, managed keys, explicit ACL/dedicated volume, durable ciphertext+DB manifest, decoder sandbox, explicit legal/privacy consent, reviewer authorisation, retention/erasure, off-host audit and full restore rehearsal. Uploads, Storage object policies and provider approval stay disabled.

## Current engineering checkpoint (2026-10-09) — server-only one-time claim, uploads SEALED

- [x] **Implemented EAGLT02 locally:** loopback GoTrue account verification adapter, locked-to-`service_role` one-time claim RPC and claimant/check/application eligibility revalidation, atomic state/receipt transaction, and post-claim applicant withdrawal. Local migration `20261009043000_evidence_one_time_claim.sql` and 34-file pgTAP suite **736/736 PASS**; synthetic admission/scanner suite **46/46 PASS**; real ClamAV **4/4 PASS**. No public route, no client account UI changes, no file intake.
- [ ] **Next separate gates:** verified live GoTrue-to-claim end-to-end test and concurrency/crash recovery; real consent/withdrawal notice; dedicated protected storage/ACLs and immutable digest-bound encrypted custody; KMS rotation/recovery; document content normalisation; ClamAV signature freshness and resource quotas; off-host audit; retention/erasure/holds; least-privilege reviewer release; restore rehearsal and authorisation. `docs/EVIDENCE_AUTH_AND_CUSTODY_DESIGN.md` defines scope and limitations. Never activate `staged-provider-evidence` Storage policies or real uploads prematurely.
- [x] **Preservation:** category photographs/unified taxonomy, Flutter theme, `SMOKE_20261008_*` `s` fixtures, emulator/session, existing Operations/Technical role separation and all client journey controls unchanged.

## Prior engineering checkpoint (2026-10-09) — historical 73ea82f baseline

- **Latest implementation source:** `73ea82f` on `feature/flutter-platform-v1`. EAGLT02 local + GitHub commit match; private DB archive and independent local Git bundle verified. Source-specific implementation/limitations in `docs/EVIDENCE_QUARANTINE_ADMISSION.md`.
- **Implemented locally:** account-bound, withdrawable **non-uploading evidence intent** RPC/RLS; sealed Supabase bucket; real ClamAV/EICAR detection; separately injected **AES-256-GCM encrypted quarantine candidate** and integrity checker using synthetic bytes. No live session-verified network gateway, approved consent or reviewer release.
- **Tests at checkpoint:** database **711/711** (33 files), scanner/quarantine **35/35**, real ClamAV **4/4**, Flutter **68 app + 3 Admin + 1 Technical**, seven analysis targets clean. No emulator reset required.
- **Next gated work:** trusted server JWT validation and atomic one-time intent claim, proven secure local filesystem ACLs or Linux isolated volume, KMS/secret recovery, ingestion limits/content normaliser/ClamAV freshness, durable receipts and transaction recovery, audit, data retention/consent, reviewer separation and restore rehearsal. **Do not enable uploads or approval/payment/booking until full end-to-end controls are independently tested and authorised.**
- **UX/fixtures:** approved photo-rich category grid with consistent assets and reversible s-marked fixtures remains unchanged. General CX1 signed-in Web QA and T2.4 are still open; work on evidence does not satisfy those gates.

## Completed platform phases

- [x] Flutter + Supabase target architecture
- [x] Client/Vendor account model
- [x] shared marketplace/service catalogue
- [x] RBAC authority baseline
- [x] provider onboarding
- [x] availability/resource reservations
- [x] open request + quote workflow
- [x] taxi dispatch lifecycle
- [x] Food/Groceries commerce
- [x] Events
- [x] scheduled water passenger transport
- [x] booking-scoped Realtime messaging
- [x] Account/Profile management
- [x] Operations Admin vs Technical Control separation

## T1 — Technical Control Plane foundation — COMPLETE

- [x] 19-module registry
- [x] technical permission catalogue
- [x] technical access levels/templates
- [x] per-user/per-module access
- [x] effective permission RPCs
- [x] separate Technical Platform Administrator authority
- [x] Operations/Technical role-grant separation
- [x] secure module enable/disable/maintenance
- [x] technical audit events
- [x] `apps/wantok_tech`
- [x] permission-driven module navigation
- [x] production `tech.wantokservices.com` deployment route
- [x] living handover/roadmap + root `AGENTS.md`

## T2.1 — Technical Staff & Access Management — COMPLETE

- [x] Technical Access workspace
- [x] manageable-module filtering
- [x] controlled module staff listing
- [x] controlled account search by name/email
- [x] minimum search-length protection
- [x] assignable access-level filtering
- [x] assign/change/revoke module access
- [x] lower-level delegation
- [x] peer/higher access protection
- [x] Operations/Technical directory separation
- [x] Platform Administrator global-role protection
- [x] pgTAP security coverage
- [x] served Technical Control UI verification

## T2.2 — Module Configuration Schema Registry — COMPLETE

- [x] versioned module configuration-schema registry
- [x] supported field types and server-side validation rules
- [x] safe non-secret configuration override storage
- [x] secret-reference fields without secret-value disclosure
- [x] configuration read/update RPCs
- [x] `module.view` read-only inspection
- [x] `module.configure` write enforcement
- [x] audit before/after configuration changes
- [x] secret-reference audit redaction
- [x] typed configuration editor in Technical Control
- [x] module-specific configuration grouping/help text
- [x] seven initial active module schemas
- [x] pgTAP validation and permission tests
- [x] richer category-specific public service visuals

### T2.2 client experience polish — COMPLETE

- [x] standardise customer-facing product name as Wantok Services
- [x] PNG scenic custom-painter visual language
- [x] bilum-inspired custom bottom navigation
- [x] distinct client navigation: Home / Track / Inbox / Me
- [x] richer Home hierarchy and service spotlights
- [x] richer Food/Groceries discovery, search and local-vendor cards
- [x] richer Track and Inbox headers/empty states
- [x] Wantok Pay visual preview using Kina (K), without payment movement
- [x] Android emulator visual QA with no visible overflow
- [x] final client five-tab navigation: Home / Services / Track / Wallet / Inbox
- [x] dedicated searchable Services hub
- [x] embedded Wallet tab using Wantok Pay preview
- [x] move Account/Profile access to Home hero profile button
- [x] emulator QA for five-tab layout, Services, Wallet and Account/Profile

## T2.3 — Module health and dependency reporting — COMPLETE

- [x] acyclic module dependency registry and transitive health evaluation
- [x] registered health reporters/probes and secured control-state probe execution
- [x] reported/effective health state and transition history
- [x] dependency-impact views before disable/maintenance actions
- [x] maintenance/degraded-state presentation in Technical Control
- [x] separate `module.health_run` permission; auditors remain read-only
- [x] restricted dependency identity/description privacy and pgTAP coverage

## CX1 — Client Experience Completion Gate — IN PROGRESS

Required sequence: **T2.3 checkpoint → CX1 → T2.4**. T2.4 must wait until the client gate is completed with recorded evidence.

### Navigation decision — CURRENT (supersedes earlier historical layouts)

**Owner-approved current bottom bar: Home · Services · Explore · Track · Wallet.**
**Inbox** is in the global header beside **Profile**; Account/Provider registration stays inside Profile. Vendor bottom navigation remains separate. The Home `Explore PNG and beyond` card opens Explore; photographic `Reference Screen Samples` are development-only on Explore, not Services.

Earlier four/five-tab entries lower in this historical roadmap reflect prior checkpoints and are superseded by the 9 October 2026 CX1 Explore decision. Do not rename navigation to another brand's labels. Product discovery lives in Services; PNG travel/experience design discovery starts in Explore; activity lives in Track.

### CX1 reliability and discovery baseline

- [x] automated five-tab navigation, Home search and profile entry/back checks
- [x] working service search/family filters and entry/back coverage for 11 service categories
- [x] replace inactive Home search/QR and family controls; clarify planned Wallet actions
- [x] distinguish load failures from empty records; retry safely after repeated failures
- [x] responsive scenic headers/grids, narrow mode menu and accessible selected-tab actions
- [x] automated 320/390/800-pixel layouts at 1.5x text across discovery and five client tabs
- [x] preserve Kina (K) amounts and Wantok Pay preview-only boundary
- [x] customer Client/Vendor switch does not grant provider/technical administration
- [x] add 31 focused offline client regressions and record their limitations

### CX1A — Consumer account, saved, reviews and delegated-service foundation

- [x] richer personal profile fields: avatar URL, bio and profile/privacy preferences
- [x] separate personal and Business/Vendor profile presentation under one login
- [x] linked-account UI backed by Supabase identity linking for Google/Facebook
- [x] owner-scoped Saved model with validated entities and Services-category bookmarks
- [x] Saved screen and Services shortcut
- [x] review title/photos/visibility foundation on the existing booking-linked review model
- [x] secured review RPC restricted to completed customer bookings
- [x] Review/Edit review action from Track for completed generic service bookings
- [x] group Track records into **Ongoing · Scheduled · Completed** sections with deterministic status/time classification and live retained-data verification of the Completed path
- [x] privacy controls for profile visibility, review visibility, saved-items privacy, recommendations and profile sharing
- [x] owner-scoped Trusted people model and Account CRUD for family/relative/staff beneficiaries
- [x] richer Wantok Pay preview including planned actions, verification, PNG services and recent-activity framing
- [x] database coverage: 25 pgTAP files / 564 tests PASS
- [x] client analysis PASS and 34 Flutter app tests PASS

### CX1B — Delegated Booking Foundation — COMPLETE FOR CURRENT SERVICE CATALOGUE

- [x] add beneficiary snapshot fields to shared `service_bookings`
- [x] keep signed-in customer as booking owner/payer; beneficiary never receives account authority
- [x] validate selected beneficiary is an active Trusted person owned by the signed-in customer
- [x] preserve historical beneficiary name/relationship/contact snapshot after Trusted-person edits/deletion
- [x] wire **Who is this for?** selector into Vehicle Hire, Boat Hire and Venue Booking reservations
- [x] wire **Who is this for?** selector into Delivery, Errands/Pabili, Specialist Services and General Labour requests
- [x] show delegated beneficiary in customer Track and vendor Jobs without exposing contact details in vendor list
- [x] delegated-booking security/regression coverage included in 22 files / 525 pgTAP tests
- [x] wire delegated booking into Taxi/Ride with actual-rider snapshot and separate booked-by identity
- [x] wire delegated booking into Events/ticketing with trusted primary-attendee snapshots and organiser visibility
- [x] wire delegated booking into Food/Groceries commerce/order flows with recipient snapshots and vendor visibility
- [x] wire delegated booking into scheduled Boat/Ship passenger transport with Trusted-person primary-passenger enforcement and manifest snapshots
- [ ] decide whether future accommodation/flights modules inherit the shared delegated-booking contract

### CX1C–CX1E — Saved, media, recommendations and PNG discovery — COMPLETE

- [x] extend Save controls from service categories to providers, resources/venues and events
- [x] add managed private Supabase Storage uploads for profile avatars and review photos, with stable storage references, signed reads and owner-bound media constraints
- [x] privacy-aware **For you** recommendations from saved/history and optional already-authorised cached location data, with server-side opt-out enforcement
- [x] PNG province/town/destination discovery from structured active service/resource/event/water-route coverage, without hard-coded destinations or free-text address inference

### CX1F — Provider & Service Search + Ratings — IN PROGRESS

- [x] searchable discovery for active verified providers registered on Wantok Services
- [x] provider search matches approved active service titles and categories
- [x] provider cards show 1–5 star rating and review count
- [x] provider detail/storefront surface shows approved active services plus business/individual/organisation identity
- [x] server-side category/province/town filters use structured service coverage where available
- [x] expose category/province/town filters in the provider-search client UI
- [x] organic top-rated provider surfaces use rating quality plus review confidence rather than raw average alone
- [x] daily rotate a small display set from the qualified top-ranked pool so the same providers are not permanently fixed
- [x] keep paid placement out of organic rating scores
- [x] Services hub exposes **Find providers** and a compact **Top Wantoks** organic surface
- [x] signed-in Android Services/Agent provider-search entries, plumber-query empty state, clear/Top Wantoks empty state and filter-menu presentation verified on 2026-10-07
- [x] populated signed-in Android provider QA: `plumber` search, Specialist Services → Morobe → Lae filters, 5.0 (1) rating card, Saved persistence and approved-service storefront/detail verified on 2026-10-07 using one clearly labelled non-commercial local QA provider created through the normal application/approval/service-review lifecycle
- [ ] Web provider search/filter/rating/save/detail QA

### CX1 client information architecture — IMPLEMENTED

- [x] keep the locked **Home · Services · Track · Wallet · Inbox** primary navigation
- [x] enterprise marketplace visual baseline: Home/Services prioritise **services and goods** with prominent search, compact category discovery, local-provider promotion, real top-provider surfaces and the locked five-tab navigation
- [x] conventional profile placement: one compact profile circle in the top-right app header; Client/Vendor mode switching moved inside Account so non-service controls no longer dominate the client header
- [x] remove the old standalone Wantok Pay promo card from Home; Wallet remains the authoritative Wantok Pay surface while Home may show the compact **Pay your way** rail-preview strip
- [x] expose the user-facing **Wantok Agent** as a compact **Ask Wantok** discovery shortcut rather than a permanent header control or large Home card
- [x] centralise client service taxonomy as **Move & travel · Food & shopping · Send & errands · People & skills · Book & events**
- [x] use the same taxonomy for Services filters and the grouped full catalogue
- [x] align Services to the approved service-first hierarchy: hero/search → local-provider promotion → **Popular categories → Top providers → Recommended for you**, while keeping deeper discovery/Explore/catalogue below
- [x] **See all** from Popular categories opens a real grouped **All Wantok Services** catalogue and routes each tile into its existing transaction module
- [x] upgrade Taxi/Ride to a map-first pickup/destination planning surface with current-location control while preserving dispatch, delegated-beneficiary and explicit Request ride authority
- [x] preserve backend service-category independence so new services can be mapped into client families without changing transaction modules
- [x] live Android visual QA confirms the enterprise marketplace Home/Services baseline, conventional top-right profile placement, Ask Wantok discovery action, map-first Taxi planning and locked navigation without visible overflow
- [x] canonical Home dashboard includes real Popular categories/Top providers plus clearly planned **Travel & Flights** and **Hotels** entry points without fabricating live travel inventory
- [x] canonical Home **Pay your way** strip previews Wantok Pay, Visa, Mastercard, PayPal, Google Pay and Bank Transfer; inactive rails remain non-transactional and clearly planned
- [x] Local Providers promotion retains the approved `assets/images/vanessa_local_provider.jpg` asset; ordinary dashboard work must not replace it
- [x] align the **existing Food/Groceries commerce browser** to the Wantok enterprise marketplace style: delivery/pickup context, search-first discovery, branded hero/filters, rating-based featured approved vendors, real backend storefront/product media where supplied, and truthful empty-market states. This is presentation work on the existing commerce core and **does not start CX1G**
- [x] signed-in Android Groceries empty-market QA verifies the new commerce layout with the preserved local dataset (**0 live Food/Groceries storefronts / 0 catalogue items**); populated vendor presentation is covered by deterministic widget tests rather than fabricated local inventory
- [x] guest Flutter Web login at true 320/390 px browser widths: correct mobile viewport, responsive **Wantok Services** branding/form without overflow, 320/390/800 enlarged-text sign-in widget regressions and narrow create-account/back flow. **Authenticated Web QA remains open**
- [x] implement Mansfield's supplied 2026-10-08 blue/white photographic Wantok reference theme across shared design tokens, Home/Services, login, Wallet preview, Track/Inbox and service heroes, without generating replacement images or fabricating real transactions/offers. Full app/database gates PASS and full Android debug APK built; **original full-size APK could not install because of limited AVD free space; later resolved with a smaller x86-64-only debug build installed in place**. Source/theme baseline completed, not a claim of pixel-identical recreation of the mock-up's unrealised modules

- [x] implement opt-in temporary `SMOKE_20261008_*` visual fixtures with a small visible blue `s` beside every sample, read-only preview dialogs, an itemised removal manifest (`docs/SMOKE_DATA.md`), and **no Supabase fixture writes**. Local emulator AVD backed up and SHA-256 verified; small x86-64 APK installed in place with original userdata preserved. Demo/smoke data must be removed or disabled before release.

- [x] rebuild the **main Services landing** to the supplied 12-category/3-column reference layout, now upgraded from plain Material icons to twelve realistic AI-generated, locally bundled service pictures with labels underneath. The same shared picture registry is used by **Home shortcuts, Home chips, spotlight cards, Services, real All Services and matching service headers**. Preserve genuine backend catalogue/provider routing, filters, saved buttons and the removable `s`-marked smoke layer. See `docs/CATEGORY_IMAGES.md`.
- [x] extend Services to **18 picture-first categories** (six more cards before More: Delivery, Hotels, Education & Training, Financial Services, Water Transport and General Labour). Add seven information-only backend category records for Shopping, Home Services, Beauty & Wellness, Health & Medical, Travel & Flights, Education and Financial Services through additive migration `20261008214500_client_category_expansion.sql`. Preserve the original 15 backend categories and existing enabled routes. New categories open an honest read-only information page; no fabricated providers, bookings, payment rails or provider onboarding. All new category imagery reuses existing local files; **no new images generated** for this continuation. Database regression 28 files / 607 tests PASS locally; production migration not yet deployed.
- [x] CX1 provider-readiness continuation: category-scoped verified-provider search, real logged-in **provider interest** for seven information-only verticals, private RLS-backed idempotent submission, and an **Admin read-only interest queue**; no formal application/approval, provider role, bookings, payments or auto-notifications. Migration 20261008223000_provider_category_interest.sql is local-only. See docs/PROVIDER_CATEGORY_INTEREST.md and pgTAP test 029.
- [x] implement a separate **preliminary provider application** stage for Shopping & Retail, Home Services and Beauty & Wellness: category-readiness policies, basic applicant/service intake, private RLS, duplicate protection, Admin manual **in_review/declined** triage, and deliberately **no provider verification/role/listing/payment activation**. Regulated and higher-risk Health/Medical, Financial, Travel/Flights and Education/Training remain restricted. See `docs/PROVIDER_STAGED_ONBOARDING.md` and migration `20261008231500_staged_provider_onboarding.sql`.
- [x] add **preliminary verification checklists with Admin-only audit trail** to the three staged provider application categories: policy-requirement snapshot, RLS, applicant read-only progress, Admin confirmed pending/under_review/needs_followup actions, reviewer/time tracking, authenticated audit and explicit rejection of approved. No real credential uploads or provider activation. See `docs/STAGED_VERIFICATION_PROGRESS.md` and migration `20261008234500_staged_verification_progress.sql`.
- [x] establish a **closed, private staged-provider evidence storage boundary** (5 MiB, PDF/JPEG/PNG MIME declarations, no client Storage access policies) and a minimal, RLS-controlled future evidence-planning register with admin-only idempotent plan/cancel RPCs and audit history. Applicant sees an explicit **uploads unavailable** notice; Admin can plan but cannot accept/approve evidence. No files uploaded and no scanning or verification claimed. See `docs/PROVIDER_EVIDENCE_VAULT.md`, migration `20261009011500_evidence_vault_boundary.sql` and test 032.
- [x] implement an **isolated local ClamAV INSTREAM scanner client and fail-closed content gate** (signature-based preliminary PDF/JPEG/PNG checks, SHA-256, 5 MiB cap, local-only scanner address, timeout and malware rejection). Tests use a TCP simulator, not real antivirus signatures. Even clean results are hard-coded **storagePermitted=false, reviewerAccessPermitted=false, approved=false**. No API/upload enabled. See `packages/evidence_scanner/`, `npm run test:evidence`, and `docs/EVIDENCE_SCANNER_CORE.md`.
- [x] provision an **isolated, resource-limited real ClamAV instance** on EAGLT02 after verifying C: had 51.2 GiB free; restrict TCP to loopback, persist signature database, verify FreshClam reloaded current daily signatures 28147, and pass real clean/EICAR tests (3/3). Keep the sample/protocol tests separate (24/24). Document safe operations in `scripts/clamav-local.ps1` and `docs/CLAMAV_LOCAL_RUNTIME.md`.
- [x] introduce an **account-bound but non-uploading intake-intent RPC** with eligibility/withdrawal RLS and a separate **AES-256-GCM encrypted candidate quarantine library** (SHA-256 AAD integrity, exclusive writes, fail-closed clean scanning, no reviewer access). Tests use synthetic document bytes and an injected admission verifier; the live ClamAV integration checks isolated temp-file quarantine. No actual JWT gateway, live consent, cloud upload or release exists yet. See `docs/EVIDENCE_QUARANTINE_ADMISSION.md`, migration `20261009024500_evidence_intake_intents.sql`, tests 033 and `packages/evidence_scanner/src/quarantine.mjs`.
- [ ] design and authorise **actual protected document intake**: trusted server JWT verification + one-time database claim, formally approved privacy notice/consent, filesystem ACLs or dedicated Linux volume, key management/rotation, atomic DB/file metadata, immutable/versioned storage, full decoder and malware controls, controlled reviewer access, retention/deletion/holds, regulated licence checks, tested restore and independent final provider/listing approval. The evidence bucket remains SEALED; do not repurpose the owner-editable `provider-documents` bucket. Existing approval workflow remains authoritative.
- [x] add an opt-in 12-screen **reference sample gallery** with registered `SMOKE_20261008_SCREEN_*` IDs, visible small `s` markers, sample food providers, booking/flight/hotel examples, a demonstration route, and wallet/account examples. All examples are read-only and disabled by default for non-smoke builds; the source screenshot's individual photographs are not separately present, so the examples use existing approved PNG-themed images.
- [x] refine separate smoke-only Food Listing, Taxi, Travel, Bookings, Tracking, Wallet, Account and Home preview layouts. Verify disabled payment/booking controls, smoke identifiers, Flutter analysis and tests; install the x86-64 QA build over the existing Android emulator without clearing saved data. Keep the genuine service modules separate.

### CX1G — General Goods Marketplace + Fulfilment — PLANNED

- [ ] activate a general **Marketplace / Products** commerce category beyond Food/Groceries
- [ ] allow verified individual/business/organisation vendors to create approved product storefronts under the same Wantok account
- [ ] product listings: category, title, description, SKU, price, availability/stock, images and approval state
- [ ] customer product/store search and browse with vendor ratings
- [ ] reuse the existing commerce order core rather than create a parallel cart/order system
- [ ] support fulfilment choices: self pickup, vendor drop-off and Wantok third-party Delivery/Courier
- [ ] preserve vendor ownership of the sale when a separate logistics provider performs delivery
- [ ] support customer/vendor selection or request of an approved delivery/logistics provider
- [ ] delivery quote/acceptance/status hand-off and later proof-of-pickup/proof-of-delivery
- [ ] 1–5 star post-completion ratings for the relevant sale/service/delivery relationship

### CX1H — Organic Ranking + Sponsored Promotion — PLANNED

- [ ] transparent organic ranking from rating quality, review volume/confidence, category/search/location relevance and reliability signals
- [ ] category front-page/top-service surfaces may rotate up to five eligible high-ranked results
- [ ] sponsored campaign model with approved provider/listing target, schedule, duration, category/location targeting and impression caps
- [ ] clearly label paid placements **Sponsored** / **Promoted**
- [ ] sponsored placement never changes stored organic ratings or bypasses provider/listing approval
- [ ] audit campaign activation/status and keep future billing references separate from Wantok Pay transaction movement

### CX1I — Wantok Agent Foundation — IN PROGRESS

- [x] user-facing **Wantok Agent** entry is a compact global client-header action without adding a sixth bottom-navigation tab; the former large Home card is removed
- [x] authenticated backend capability contract reports model/chat/handoff state and allowed/restricted tool classes
- [x] model-backed chat remains disabled until an approved provider/gateway is configured
- [x] provider-search fallback from Agent examples uses the real CX1F discovery API
- [x] secured owner-private human-help handoff queue with Support/Operations/Admin visibility/update rights
- [x] client **Talk to a person** form creates a concise human-follow-up request
- [x] signed-in Android capability/model-disabled status, real plumber-search fallback and human-handoff capture verified on 2026-10-07; compact header entry and renamed **Wantok Agent** page also verified live; success snackbar plus one owner-linked persisted QA request confirmed
- [ ] Web handoff QA and staff response/live human chat evidence
- [ ] provider-agnostic model gateway/Edge Function with replaceable provider/model configuration
- [ ] controlled AI tools for service/provider/product search and authorised booking/order/status lookup
- [ ] provider assistance for category selection and drafting service/product listings
- [ ] assist users when normal search cannot find a service and prepare a controlled request where appropriate
- [ ] support/operations UI for triaging AI handoff requests and returning the conversation to the client
- [x] AI foundation does not approve providers, move money, grant roles or bypass workflow approvals
- [ ] Wantok Neurons may later provide intelligence only through this API boundary; Wantok Services remains transaction authority

### Later CX1 options

- [ ] optional achievements/rewards after core consumer workflows are stable
- [ ] social follow/follower metrics only after privacy/moderation design is approved

## ADS1 — Wantok Ads / Managed Social Advertising — PLANNED

**Sequencing:** future first-party Wantok Services product module. It is not part of the current CX1 completion gate and does not replace CX1H in-app Sponsored/Promoted placement.

- [ ] first-party Wantok Ads customer campaign brief for legitimate products/services/businesses/events
- [ ] supported external networks through official adapters, initially Meta/Facebook/Instagram, TikTok and Google/YouTube where approved
- [ ] creative service catalogue for copy/text, static images, short social video, produced video and configurable add-ons/revisions
- [ ] configurable campaign-duration/service tiers without hard-coded PGK pricing in the client
- [ ] separate creative/production fee, campaign-management fee and external media/ad-spend accounting
- [ ] **Wantok Operations Admin** (`apps/wantok_admin`) is the authoritative ADS1 approval/operations surface for package catalogue, quotes, advertiser/product eligibility, creative review, customer-approval evidence, channel targeting, budgets/spend ceilings, scheduling, submission, pause/resume/cancel, incidents and reporting
- [ ] granular ADS1 permissions such as `ads.view`, `ads.quote`, `ads.creative_review`, `ads.compliance_review`, `ads.approve`, `ads.publish`, `ads.pause`, `ads.report`; do not collapse all authority into a generic admin flag
- [ ] high-value/risk publication and material spend increases support configurable dual approval/four-eyes control with immutable audit events
- [ ] customer approval of final creative before platform submission
- [ ] compliance/product/platform-policy review and auditable rejection/resubmission states
- [ ] campaign lifecycle: draft, waiting customer, waiting platform, scheduled, live, paused, rejected, completed/cancelled
- [ ] Admin browser actions call secured server RPC/API/job commands; no raw advertising credentials or direct browser-to-network publishing
- [ ] official OAuth/ad-account access; never collect social-media passwords
- [ ] secret references, OAuth/ad-account credentials, adapter health and callbacks remain behind **Technical Control**; technical integration authority must not imply campaign/commercial approval authority
- [ ] platform metrics ingestion with source/time/ad identifiers, spend, reach/impressions, views, clicks and authorised results/conversions
- [ ] customer campaign reporting and Operations reconciliation/audit
- [ ] Wantok Agent may help draft campaign briefs/copy later but cannot autonomously publish ads or spend money
- [ ] keep external media spend separate from Wantok organic ranking, CX1H in-app promotion and future Wantok Pay settlement

Detailed product rules: `docs/ROADMAP_FILLERS.md`, FILLER-2026-10-07-06.

## GLOB1 — Global Market Foundation — PLANNED

**Product decision:** Wantok Services is a worldwide platform launched from Papua New Guinea. PNG remains the home/launch market, but shared platform contracts must not assume one country, currency, time zone, address format or regulatory regime.

- [ ] country/subdivision-aware service availability and market capability configuration
- [ ] explicit currency on all monetary amounts; remove implicit single-currency assumptions from shared primitives
- [ ] IANA time-zone handling with UTC-normalised persistence
- [ ] locale/language preferences and international phone/address structures
- [ ] market-specific payment rails, provider requirements, tax/regulatory/consumer-protection configuration
- [ ] evolve **Explore PNG** into a global Explore model while preserving a first-class PNG launch experience
- [ ] preserve one Wantok account and common Track/Inbox/Wallet/Agent experience across markets
- [ ] do not rewrite working PNG verticals merely to add global capability

Detailed product rules: `docs/ROADMAP_FILLERS.md`, FILLER-2026-10-07-07.

## TRV1 — Global Travel + Itinerary — PLANNED

**Sequencing:** specialised future travel vertical built after the current CX1/T2.4 gates and global-market foundations. Travel reuses shared Wantok identity, Track, Inbox, Wallet/payment-intent, notifications, safety and audit primitives but has its own supplier/offer/order lifecycle.

- [ ] trip/itinerary container combining flights, accommodation, transfers, rail/bus/ferry where supported, vehicle hire, events and local Wantok services
- [ ] traveller model separate from account/payment authority, with dedicated protected-document boundary for passport/identity data
- [ ] provider-agnostic server adapters for airline direct/NDC, GDS/travel-content, hotel/accommodation and later transport suppliers
- [ ] ephemeral travel offers with source, expiry/revalidation, fare/cabin/baggage/stops, taxes/fees, currency and supplier conditions
- [ ] dedicated travel-order lifecycle; never show confirmed/ticketed until the supplier confirms that state
- [ ] explicit customer approval after offer revalidation and before purchase/ticketing; material price/itinerary changes require re-approval
- [ ] multi-currency payment/refund references separated into supplier amount, taxes/fees and Wantok service fees
- [ ] Track itinerary timeline and travel lifecycle; Inbox travel/supplier updates separated from provider/support conversations
- [ ] Operations Admin handles authorised booking exceptions, cancellation/refund/service incidents and support
- [ ] Technical Control handles supplier credentials, callbacks/webhooks, adapter health and diagnostics without inheriting commercial booking/refund authority
- [ ] disruption/change/cancellation/refund workflows with idempotency and audit correlation
- [ ] international destination-local orchestration: airport transfer, Wantok taxi/ride, vehicle hire, events and local providers

### Wantok Agent travel orchestration

- [ ] natural-language trip planning for origin/destination/dates/travellers/preferences
- [ ] authorised flight/accommodation/transport search through controlled tools
- [ ] compare valid returned offers and explain supplier-provided stops, baggage, duration, fare/change/refund conditions
- [ ] assemble multi-day itineraries spanning international travel and local Wantok services
- [ ] prepare a booking basket and explicit approval step; **Agent cannot autonomously spend money, ticket, change, cancel or refund**
- [ ] do not invent live fares, availability, entry/visa requirements or supplier policies
- [ ] material supplier/price changes after approval trigger re-approval rather than silent substitution

Detailed architecture: `docs/GLOBAL_TRAVEL_ARCHITECTURE.md`.

### Remaining CX1 gate evidence

- [x] fresh signed-in Android **Client → Services** shell/navigation visual QA on the existing development session; locked Home / Services / Track / Wallet / Inbox layout renders without visible overflow, Home/Services are service-and-goods-first marketplace surfaces, profile is top-right, and Wantok Agent is available from the discovery shortcuts
- [ ] **signed-in Web visual QA remains open**; Android Home/Services/provider discovery/Taxi/Track/Wallet/Inbox/Account and the existing Food/Groceries empty-market journey are verified on the preserved development session within available local data
- [ ] live read-only journey checks are complete for every retained populated client state currently available locally: Account, provider discovery/detail/Saved, Inbox/support, Track Completed, Taxi current-location/history, Services recommendations/Explore PNG and Wallet preview. Food/Groceries currently has no live storefront/catalogue data, so only truthful empty-market live evidence is possible without creating fixtures; other unpopulated verticals remain evidence-limited rather than failed
- [x] live Account mutation QA complete for privacy save, Trusted-person CRUD/delegation, review editing/review media and avatar media, with all temporary changes restored. **OAuth linking remains environment-blocked until Google/Facebook Supabase provider configuration exists**
- [ ] complete gate evidence review and signed-in Web evidence before T2.4

Acceptance evidence and initial findings: `docs/CX1_CLIENT_EXPERIENCE_GATE.md`.

2026-10-07 Android continuation from `b69656b`: prior debug APK build verified complete and installed in-place with `adb install -r`; existing sign-in/app/AVD/Supabase data preserved. New normal/IPv4 rebuild attempts failed with Java loopback IOException. Full Flutter checkpoint and 27-file/598-test database suite PASS. Local captures/logs remain in ignored `.wantok/`.

2026-10-07 populated-provider continuation after `4fe0a34`: one deliberately labelled **non-commercial local QA provider** was created through the existing authenticated application → admin approval → provider listing → review submission → admin activation workflow. One QA booking was accepted, advanced to completed and reviewed through existing secured RPCs solely to exercise rating aggregation; no payment or real service occurred. Signed-in Android now verifies populated `plumber` search, **Specialist Services → Morobe → Lae** filters, **5.0 (1)** rating, provider Saved persistence and provider storefront/approved-service detail. Android provider-discovery evidence is complete; Web evidence remains open. CX1 remains open overall; CX1G has not started and T2.4 remains deferred.

Use existing local development accounts/data. No Supabase reset, reseed, account replacement or payment movement is part of CX1.

## T2.4 — Diagnostics, logs and jobs — AFTER CX1

- [ ] diagnostics adapters
- [ ] central/module log adapters
- [ ] background job/queue visibility
- [ ] approved job actions
- [ ] richer technical audit views

## T2.5 — Integrations and high-risk controls

- [ ] integration status/configuration
- [ ] secret-reference model integration
- [ ] high-risk action confirmation/approval
- [ ] critical-action dual control where appropriate

## T3 — Operational hardening

- [ ] production observability
- [ ] alerting/escalation
- [ ] maintenance windows
- [ ] incident/status history
- [ ] backup/restore controls where safely appropriate
- [ ] technical runbooks

## Wantok Pay design gate

Do **not** implement payment movement until decisions are made for:

- market-specific payment rails/providers, with PNG as the launch market
- cards/mobile money/bank integration
- multi-currency amount, FX-display and settlement rules for global use
- cash boundary
- wallet scope
- provider/supplier settlement
- commissions/service fees
- taxes/fees and travel supplier amounts
- refunds/disputes, including partial supplier refunds
- reconciliation
- custody/regulatory boundary by market
- secrets/key management

After those decisions, implement payment adapters behind a common interface and technical permissions.

## Checkpoint discipline

Every meaningful phase ends with:

1. full validation;
2. update `docs/HANDOVER.md`;
3. update this roadmap;
4. Git checkpoint;
5. leave the working tree clean.
