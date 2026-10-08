# Wantok Services — Living Handover

**Updated:** 2026-10-08
**Repository:** `D:\Project-M.2\wantok-service-recovery`
**Branch:** `feature/flutter-platform-v1`

## Resume here

The current working phase is **CX1 client-experience completion**; the **CX1 gate remains open before T2.4**. Android evidence is now complete for every retained client state currently available locally; the principal evidence blocker is **signed-in Web QA**, which must not be bypassed by cloning Android session tokens or fabricating credentials. Delegated booking is checkpointed across every currently implemented client service family. The active CX1 extensions now include **CX1F provider/service discovery with ratings** and the **CX1I Wantok Agent capability/human-handoff foundation**. General Marketplace/fulfilment (CX1G), sponsored promotion (CX1H) and model-backed AI/tool execution (remaining CX1I) are still planned. A separate future first-party **ADS1 Wantok Ads** module is approved for managed external social/video advertising. Product scope is now explicitly **global**: PNG is the launch/home market, not the platform boundary. Future **GLOB1 Global Market Foundation** and **TRV1 Global Travel + Itinerary** streams cover country/currency/time-zone foundations, flights/accommodation/transport and Wantok Agent travel orchestration. These are planned architecture only and do not bypass the current CX1/T2.4 sequence. **Wantok Operations Admin is the future ADS1 commercial/approval/campaign authority; Wantok Technical Control owns only integration credentials/health and does not inherit campaign approval authority.** Run:

`git log -1 --oneline`

to resolve its exact commit hash.

Before any new task, read root `AGENTS.md`, this file, `docs/ROADMAP.md`, and **`docs/ROADMAP_FILLERS.md`**. For global/travel work also read **`docs/GLOBAL_TRAVEL_ARCHITECTURE.md`**. The filler file carries Mansfield's incremental additions without rewriting the main roadmap.

## Product identity

- Product: Wantok Services
- Scope: **global multi-service + travel platform; Papua New Guinea is the launch/home market**
- Domain: **wantokservices.com**
- Stack: Flutter + Supabase
- Public app: `apps/wantok_app`
- Operations administration: `apps/wantok_admin` / `admin.wantokservices.com`
- Technical administration: `apps/wantok_tech` / `tech.wantokservices.com`

Operations and Technical authority are separate server-side. One does not imply the other.

## Verified implemented state

Checkpointed platform includes:

- Client/Vendor account model and service catalogue
- provider onboarding/verification boundaries
- resource availability/reservations
- open requests and quotes
- taxi dispatch lifecycle
- Food/Groceries commerce
- Events
- scheduled water passenger transport
- booking-scoped Realtime messaging/read receipts
- Account/Profile management and preferences
- Technical Control Plane T1
- T2.1 Technical Staff & Module Access Management
- T2.2 versioned typed module configuration and Technical Control editor
- T2.2 PNG-rich client experience polish across Home, Food/Groceries, Track, Inbox and Wantok Pay preview
- T2.3 module health/dependency reporting, scoped probe execution and impact previews
- CX1 reliability/discovery baseline plus richer client account/privacy, delegated booking, Saved/media/recommendations/Explore PNG, provider/service search with ratings, Top Wantoks organic discovery, and Wantok Agent capability/handoff foundation (gate open)

### Technical Control T1

- 19-module registry
- module/platform permission catalogue
- Technical Platform Administrator authority
- Technical Administrator / Module Administrator / Support / Auditor levels
- per-user/per-module assignments
- effective permission RPCs
- permission-driven module navigation
- secure module enable/disable/maintenance
- audited module state/access changes
- separate Flutter Web Technical Control Panel

### T2.1 staff/access management

- Technical Access workspace appears only where the actor has `module.permissions`
- controlled staff list per module
- controlled account search by name/email
- minimum 2-character search
- assign/change/revoke module access
- assignable levels limited below the actor's authority
- peer/higher assignments shown as protected
- peer downgrade/revoke blocked server-side
- Module Administrator/Support/Auditor cannot delegate access
- Operations Admin cannot use Technical staff search
- Technical Platform Administrators remain global and are not ordinary module assignments

### T2.2 typed configuration

- versioned per-module configuration schemas
- typed fields with server-side validation
- schema defaults plus controlled overrides
- `module.view` read-only inspection and `module.configure` editing
- batched schema-versioned updates with audit history
- secret references only (`env://`, `vault://`, `external-secret://`, `supabase://`), never secret values
- secret references redacted from audit metadata
- initial schemas for Taxi, Water Transport, Messaging, Food, Groceries, Delivery and Notifications
- typed Technical Control editor with reset/discard/save workflows
- refreshed public service grid with category-specific colours and stronger lightweight icons

### T2.2 PNG-rich client experience polish

- product-facing name standardised as **Wantok Services** while native package IDs remain unchanged
- PNG scenic visual language implemented with lightweight custom Flutter painters: mountain forms, tropical accents and abstract bird-of-paradise treatment
- bilum-inspired custom bottom navigation replaces Material/Grab-like navigation
- original four-tab layout was superseded by **Home · Services · Track · Wallet · Inbox**
- richer Home hierarchy with scenic hero, compact **Quick access** shortcuts, service spotlights and PNG purpose banner; Wantok Pay is kept in the dedicated Wallet tab instead of duplicating Home
- Food/Groceries now use scenic commerce heroes, search/filter surfaces and richer local-vendor discovery cards
- Track and Inbox have dedicated scenic headers and polished empty states
- Wantok Pay remains a visual preview only with **Kina (K)** display; no payment movement is enabled
- visible PGK-facing customer amounts use Kina-style `K` formatting where appropriate
- live Android emulator QA completed for Home, Food, Track and Inbox without visible overflow
- client primary navigation finalised as **Home · Services · Track · Wallet · Inbox**
- dedicated searchable Services hub added instead of duplicating the Home surface
- Wantok Pay preview embedded directly as the Wallet tab without a nested app bar
- Account/Profile moved out of primary navigation and remains accessible from the Home hero profile button
- live Android emulator QA completed for Home, Services, Wallet and Account/Profile with no visible bottom-navigation overflow

### T2.3 health and dependencies

- explicit acyclic dependency graph with required/optional failure effects
- reported health from registered probes; effective health includes module state and transitive dependencies
- current report/state stores and status transition history
- built-in `control.state` probe reports control-plane state only, not end-to-end runtime availability
- external reporter contract exists; runtime/integration adapters remain later work
- `module.view` reads, separate `module.health_run` execution; auditors cannot run probes
- dependency identities/descriptions outside visible scope are redacted
- Technical Control Health & dependencies page and pre-action impact confirmations
- four migrations `20261006120000` through `20261006123000` already applied locally; do not replay/reset

### CX1 implementation and evidence

- **Client navigation is locked as Home · Services · Track · Wallet · Inbox.** Do not rename it to Grab-style Discover/Activity/Payment/Messages.
- Home search selects Services; profile route has an app bar/back button.
- Services owns the complete enterprise catalogue and rich discovery: search/clear, Saved controls, **Recommended for you**, **Explore PNG**, provider discovery, **Top providers**, a preferred **Popular categories** strip, and a grouped **All Wantok Services** catalogue opened from **See all**. Client-facing services are organised through a shared taxonomy: **Move & travel · Food & shopping · Send & errands · People & skills · Book & events**. The default catalogue groups services under those families; compact filters reuse the same taxonomy. Provider discovery searches active verified providers through approved active services, shows real 1–5 star rating/review counts, exposes approved services on provider detail, supports saving providers, and exposes category/province/town client filters backed by structured server-side coverage. Organic ranking is confidence-aware so a 5.0/1-review provider does not automatically outrank an established high-quality provider. Top Wantoks is a daily rotating subset from the qualified organic pool; paid placement is not mixed into the score.
- Account/Profile now includes bio/avatar URL foundation, privacy/share controls, linked-account management, Saved, Trusted people, My reviews and separate Business/Vendor profile presentation under one login.
- Supabase identity linking is used for Google/Facebook; no parallel customer account is created by UI design.
- owner-scoped `client_saved_items` and secured bookmark RPC validate that only discoverable entities can be saved.
- owner-scoped `trusted_people` feeds the delegated-booking contract. Vehicle/Boat/Venue reservations, Delivery/Errands/Specialist/Labour requests, Taxi/Ride, Events/ticketing, Food/Groceries commerce and scheduled Boat/Ship passenger transport support **Who is this for?**. Taxi keeps the signed-in account as `passenger_id`/payer while driver-facing RPCs resolve the selected Trusted person as the actual rider and retain a separate `booked_by_name`. Events keep the signed-in customer as registration/payment/cancellation owner while snapshotting the selected Trusted person as primary attendee for customer/organiser views. Beneficiary snapshots preserve history and do not grant account access.
- existing `service_reviews` is extended with title/photo URL/visibility fields; review writes use a secured RPC limited to completed customer bookings; provider rating aggregation remains the existing trigger.
- Track offers Review/Edit review for eligible completed generic service bookings and retains specialised ride/order/event/water shortcuts.
- Wallet remains preview-only but now frames Top up/Scan/Send/Receive, verification, PNG-oriented planned services and future transaction history. No money movement exists.
- The user-facing assistant is **Wantok Agent**. It remains outside the five-tab navigation and now appears as a compact **Ask Wantok** discovery shortcut rather than occupying the permanent app header or a large Home card. Home/Services are service-and-goods-first marketplace surfaces; the profile circle owns the conventional top-right header position and Client/Vendor mode switching moved inside Account. The authenticated capability API reports model/chat/handoff state; model chat is deliberately disabled until a controlled gateway is configured. The Agent surface can use real provider-search fallback and create owner-private human-help requests. Support/Operations/Admin can later triage those requests; live human chat and support triage UI are not yet implemented. Internal compatibility identifiers such as `WantokAiAgentRepository` and `wantok_ai_agent` remain unchanged.
- retry failures stay in the view rather than escaping callbacks; Events/departures/order/registration/water-trip failures do not masquerade as empty records.
- 48 focused client regressions plus the configuration smoke total **49 app tests**; they use in-memory/unconfigured backends and do not replace local account data.
- entry/back navigation coverage includes 11 categories. Signed-in Android Account read/write/media, categorised Inbox/support, map-first Taxi runtime, Services/Wallet and the existing Food/Groceries empty-market commerce journey are now live-verified within the documented evidence limits; signed-in Web and other unavailable populated journeys remain open.
- do not call CX1 complete from widget/database tests alone; see its evidence document.

## Android continuation evidence — 2026-10-07

- Resumed clean `feature/flutter-platform-v1` at `b69656b`. Prior debug APK build confirmed complete by Gradle daemon Success at 08:32:04 PGT and matching APK/SHA-1 artifacts. Installed it with `adb install -r` on the preserved emulator; Success, unchanged first-install timestamp and existing Mansfield sign-in. New rebuild attempts with `.wantok/local-android.json` failed with Java loopback IOException, including the IPv4 retry; do not report those attempts as PASS.
- Home/Services retain locked five-tab navigation. Services → Find providers, Agent → plumber search, clear/Top Wantoks empty state and category/province menus verified. Local DB has **0 provider profiles / 0 provider services**; menus contain only All, town disabled. Populated filter/rating/save/detail evidence remains open and needs real approved service coverage; no fixtures/approvals were created.
- Wantok Agent capability status and disabled model input verified. Android Talk to a person submission showed success and created one `open` request owned by the existing Mansfield profile, ID `640eded2-0367-402a-8555-1252b306acb0`, with internal source `wantok_ai_agent` and `chat_enabled=false`. It is explicitly labelled QA with no operational assistance required; retained for evidence. Staff response/live human chat and Web handoff remain unverified.
- Existing Auth/Profile counts remain **2/2**. No app/Supabase/AVD reset or role changes. Screenshots/XML and fresh build/check logs are retained locally under ignored `.wantok/`; full evidence and APK hash are in `docs/CX1_CLIENT_EXPERIENCE_GATE.md`.
- Fresh full Flutter checkpoint PASS: seven analysis targets, 34 app tests, Admin/Technical smoke tests. Database PASS: 27 files / 598 tests. CX1 remains open, T2.4 deferred, CX1G not started. Resolve the documentation checkpoint hash with `git log -1 --oneline`.

## Populated provider continuation — 2026-10-07

- The zero-provider state above is historical evidence from `4fe0a34`. One deliberately labelled **non-commercial local QA provider** now exists so CX1F can be exercised with real lifecycle data. It was created through the normal authenticated provider application → Admin approval → provider listing → review submission → Admin activation flow; Mansfield was not granted Operations/Admin authority and no verified-provider row was inserted directly.
- **Wantok QA Plumbing Services** is verified/active with active **QA Plumber & Maintenance**, category **Specialist Services**, structured coverage **Morobe / Lae**. One non-commercial QA booking was completed through the normal provider transition RPCs and reviewed through `submit_service_review`, producing **5.0 (1 review)** without payment movement.
- Signed-in Android CX1F populated evidence PASS: `plumber` search, **Specialist Services → Morobe → Lae** filters, rating card, provider Saved persistence (live control changes to **Remove from saved**) and provider storefront/approved-service detail.
- Local ignored evidence includes `cx1-populated-provider-workflow.sql/.log`, populated search/filter captures, Saved-state evidence and provider-detail captures under `.wantok/`.
- Emulator crash investigation isolated the prior unstable path to a software-rendered/audio-enabled run that later reported Windows layered-window and DirectSound failures. The replacement visible run with host GPU, `-no-audio`, cold boot and snapshots disabled remained responsive throughout populated QA and the full Flutter checkpoint. AVD defaults now use cold boot, Fast Boot off, 4 cores, host GPU and audio input off; `.wantok/start-wantok-emulator.ps1` carries the stable launch flags. Userdata, installed app and sign-in were preserved.
- Retaining the QA provider and prior AI handoff exposed fixture-isolation assumptions in pgTAP tests 025–027. Their affected counts/updates are now scoped to deterministic fixture rows so ordinary preserved local data does not invalidate the suite. Fresh database result: **27 files / 598 tests PASS**.
- Fresh Flutter checkpoint remains PASS: seven analysis targets, **34 app tests**, Operations Admin smoke and Technical Control smoke.
- Android CX1F is now PASS; **Web CX1F remains open**. CX1 overall remains open, T2.4 stays deferred and CX1G has not started.

## Enterprise client hierarchy continuation — 2026-10-07

- The public assistant is now **Wantok Agent**. The previous large Agent card was removed from Home and replaced by a compact sparkle action in the client app bar, available across client tabs without creating a sixth primary destination. Internal API/database identifiers remain unchanged for compatibility.
- Home is now intentionally shortcut-first: scenic search hero, six high-frequency **Quick access** services, **See all** into Services, then lightweight service spotlights. The duplicate Wantok Pay Home card was removed; **Wallet** is the authoritative Wantok Pay surface.
- `service_catalog_taxonomy.dart` centralises the client-facing service families as **Move & travel · Food & shopping · Send & errands · People & skills · Book & events**. Services uses the same taxonomy for horizontal filters and grouped full-catalogue panels while individual backend service categories remain independently managed.
- Fresh debug APK built successfully after resolving the known generated `cleanMergeDebugAssets` lock by stopping Gradle and clearing only `apps/wantok_app/build`. The APK was installed in-place with `adb install -r`; existing sign-in, Supabase data and AVD userdata were preserved.
- Live Android visual QA PASS: simplified Home, grouped Services catalogue, Top Wantoks/provider discovery, locked five-tab navigation and renamed Wantok Agent page render without visible overflow. Evidence is retained under ignored `.wantok/`.
- Track now normalises PostgREST embedded to-one and to-many quote/review relationships before rendering, preventing completed-booking review/quote data from disappearing when PostgREST returns an object instead of a list. A dedicated regression covers both shapes.
- Track records are grouped into **Ongoing · Scheduled · Completed** sections. Future non-terminal bookings are Scheduled, already-due/in-progress/non-scheduled active work is Ongoing, and completed/cancelled/rejected/expired records are retained under Completed history. Live Android QA with the retained plumbing QA booking verifies the Completed (1) section, provider/location details, messaging and Edit review action without creating new bookings.
- Fresh full checkpoint PASS: all seven Flutter analysis targets, **40 Wantok app tests**, Operations Admin smoke, Technical Control smoke, and **27 files / 598 pgTAP tests**.

## Account and Inbox continuation — 2026-10-07

- Signed-in Android Account QA covers the Account shell, **Privacy & sharing**, **Linked accounts**, **Saved**, **Trusted people** and **My reviews**. Privacy mutation PASS: Personalised recommendations was toggled true → false through the real UI, persisted server-side, then restored to true while the other original privacy values remained unchanged.
- Linked accounts shows Email & password Connected with Google/Facebook Connect actions. Live provider OAuth linking is environment-blocked: the local Supabase project has no usable Google/Facebook provider configuration, so no live-link PASS is claimed.
- Account Saved renders the retained Wantok QA Plumbing Services provider; My reviews renders the retained 5-star public QA review. Trusted people live CRUD/delegation PASS: a temporary QA person was added through the UI, persisted, appeared in Taxi **Who is this for?**, then removed through the UI and the table returned to 0. This exposed a stale-list defect caused by Future-returning `setState` refresh callbacks in Saved/Trusted/Reviews and the booking selector; all four callbacks now use void block updates and Trusted add/delete refresh immediately. Review mutation PASS: the retained QA title was changed and restored, then one temporary review image was uploaded through managed storage and removed; final rating/title/comment/visibility/photo array match the original. Avatar mutation PASS: one temporary QA PNG was uploaded through the system picker to owner-private `client-media`, then removed through Account and both `avatar_url` and the storage object returned to empty.
- Inbox now separates **Services** booking-linked provider conversations from **Help & support** owner-private Wantok Agent handoff requests. The two sources load independently so a service-messaging failure does not suppress support requests, and support failure does not remove service conversations.
- Signed-in Android Inbox QA PASS with retained data: **Services (0)**, **Help & support (1)**, persisted owner QA request, OPEN status and detail sheet. The detail explicitly states live human chat is not enabled and that authorised Support/Operations staff may handle the request.
- Responsive Inbox regressions cover compact/enlarged-text layouts plus source fault isolation. The current full Flutter checkpoint is **45 Wantok app tests PASS**; database remains **27 files / 598 pgTAP tests PASS**. Debug APK installs preserve account/session/AVD/Supabase data; when the retained emulator carried local version code 4003, the newer debug source build used `adb install -r -d` to permit the local debug downgrade without uninstalling or wiping data.
- Taxi/Ride signed-in Android read-only QA PASS without creating a new ride: location service enabled, fine/coarse permission already granted, Pickup resolved to **Current location**, delegated-beneficiary selector remained on Myself, Request ride was not submitted, and the retained Mansfield cancelled ride renders under **Recent rides** with its K8.68 fare. Taxi presentation separators were normalised to plain text for clean accessibility output.

## Enterprise marketplace dashboard baseline — 2026-10-07

- Home and Services now use the approved service-and-goods-first enterprise marketplace hierarchy: prominent search, compact category discovery, local-provider promotion, real provider/rating surfaces and the locked **Home · Services · Track · Wallet · Inbox** navigation.
- Client chrome is intentionally quieter: one conventional profile circle owns the top-right header position. Client/Vendor mode switching moved into Account, and **Wantok Agent** moved to a compact **Ask Wantok** discovery shortcut rather than permanently consuming header/search space.
- Home renders real catalogue categories and real provider-discovery data; no mock stores/providers or fabricated ratings were introduced. The canonical Home now also exposes **Travel & Flights** and **Hotels** as clearly planned global entry points, and **Pay your way** previews Wantok Pay, Visa, Mastercard, PayPal, Google Pay and Bank Transfer without enabling money movement. Services follows the approved hierarchy with **Popular categories → Top providers → Recommended for you**, retains Saved/Explore PNG/provider filters/search, and exposes a grouped **All Wantok Services** catalogue from **See all**.
- The approved Local Providers promotion keeps `apps/wantok_app/assets/images/vanessa_local_provider.jpg` as its current image asset; ordinary dashboard work must not replace it. The signed-in Android debug APK was rebuilt and installed in-place with `adb install -r`; Home and Services were visually verified on the preserved emulator with no visible overflow. Evidence is retained under ignored `.wantok/dashboard-redesign-*.png` and `.wantok/dashboard-redesign-*.log`.
- Fresh full checkpoint PASS: all seven Flutter analysis targets, **45 Wantok app tests**, Operations Admin smoke, Technical Control smoke, **27 files / 598 pgTAP tests**, and `git diff --check`.
- 2026-10-08 live Android continuation rebuilt the current dashboard APK and installed it in-place with `adb install -r` at 10:07:37 while preserving the original 2026-10-05 first-install timestamp, sign-in and app data. The preferred Home layout is live with the top-right profile, global hero copy, Vanessa local-provider promotion, Travel & Flights/Hotels, real Top providers and the compact **Pay your way** strip. Wantok Pay, Visa, Mastercard, PayPal and Google Pay are visible in the standard viewport; Bank Transfer remains the next readable item in the same horizontal row. The emulator required cache trimming only (`pm trim-caches`) to free staging space; no app clear/uninstall, AVD wipe or Supabase reset was used.

## Food/Groceries commerce UX continuation — 2026-10-08

- Existing **Food/Groceries commerce authority is unchanged**: approved provider storefronts, real catalogue items, quantities, checkout, fulfilment choice, delegated beneficiary and order creation remain backed by the existing commerce repository/RPCs.
- The customer marketplace presentation now follows the approved Wantok enterprise style: **Delivery or pickup context → prominent search → branded commerce hero → filters → Featured approved vendors → Browse all vendors**.
- Storefront feature cards use real backend media from provider-service metadata when supplied; catalogue product rows use the existing `commerce_catalog_items.image_url`. Missing/failed media falls back to Wantok-branded icons rather than invented product imagery.
- Vendor feature ordering is derived only from existing rating average/review count for presentation; persisted ratings and organic provider ranking are not modified.
- Empty markets remain explicit and truthful. The preserved local database currently has **0 active Food/Groceries storefronts and 0 available commerce catalogue items**, so live Android QA verifies the polished **No approved shops in this market yet** state. The populated layout is covered by injected widget-test vendor data only; no fake database stores, discounts or inventory were created.
- Live Android QA used the same preserved AVD. A stuck graphical Quick Boot path was replaced with a headless cold boot using `-no-snapshot-load`; app/userdata were not wiped. Because the retained QA build had local version code 4003 and the current debug APK reports code 3, installation used `adb install -r -d` to preserve the existing app data/session.
- Fresh client checkpoint: all seven Flutter analysis targets PASS; Wantok app **45 tests PASS**, including compact empty-market and populated-vendor commerce regressions; Operations Admin and Technical Control smoke tests PASS. Database remains **27 files / 598 pgTAP tests PASS** and `git diff --check` is clean.
- This is **existing Food/Groceries UX alignment only**. **CX1G General Marketplace remains PLANNED**; no general-product schema, vendor-expansion or fulfilment architecture was activated by this continuation.

## Web sign-in and narrow-screen audit — 2026-10-08

- Resumed EAGLT02 on the preserved Android emulator `emulator-5554`, local Docker/Supabase volumes and clean Git checkpoint `6a30f3b`. No reset, reseed, account removal or Android reinstall occurred.
- Local Flutter Web is served at `http://127.0.0.1:3000` using ignored `.wantok/local-web.json`; Web uses the host `127.0.0.1:54321` Supabase URL, not Android's `10.0.2.2` bridge.
- Live guest Web browser testing exposed a genuine narrow-width sign-in brand-row RenderFlex overflow at 320 px. `apps/wantok_app/lib/src/auth/sign_in_page.dart` now constrains the brand copy with `Expanded`, uses the product name **Wantok Services** and its established **People. Places. Possibilities.** tagline. `apps/wantok_app/web/index.html` now explicitly defines `width=device-width, initial-scale=1.0` for mobile Web.
- Added `apps/wantok_app/test/sign_in_responsive_test.dart`: sign-in widths 320, 390 and 800 at 1.5x text, plus narrow-width Sign in -> Create account -> Sign in navigation; **four tests PASS**. The full checkpoint now passes all seven Flutter analysis targets, **49 client app tests**, Operations Admin and Technical Control smoke tests, and **27 files / 598 pgTAP tests**.
- Live Chrome DevTools Protocol emulation was performed with an isolated, unauthenticated Chrome profile. After warm-up, 320 px and 390 px screenshots show the complete sign-in form/branding without overflow, the browser viewport equals the requested device width, and no browser JavaScript exceptions were recorded. Ignored evidence: `.wantok/cx1-cdp-320.png`, `cx1-cdp-390.png`, `cx1-web-cdp-warm-mobile.log`, `cx1-signin-full-flutter-check-20261008.log` and `cx1-signin-db-test-20261008.log`.
- **This is guest Web visual PASS only. Signed-in Web provider search/filter/save/detail, Account, Track, Wallet, Inbox and Wantok Agent evidence remain OPEN.** Continue only after a legitimate browser login; do not clone Android session tokens, manufacture authentication or close CX1 prematurely. T2.4 remains deferred.
- Separate non-blocking audit observation: `supabase_vector_wantok-service` restarts when its Docker-log collector attempts `192.168.65.254:2375` (connection refused), while local Auth, DB, REST, Storage, Realtime and Kong remain up. No Docker daemon/security setting was changed during this continuation.

## Validation baseline

At this checkpoint:

- all shared Flutter packages: analysis PASS
- Wantok app: analysis + **49 tests PASS** (48 client regressions + configuration smoke)
- required `scripts/flutter/check.ps1`: PASS; Desktop Commander shells on EAGLT02 currently need the standard `PROGRAMFILES(X86)=C:\Program Files (x86)` supplied per process for `flutter test`
- Wantok Operations Admin: analysis + smoke test PASS
- Wantok Technical Control: analysis + smoke test PASS
- database: **27 files / 598 pgTAP tests PASS** (all fixtures roll back), including confidence-aware provider discovery and Wantok AI capability/handoff security coverage
- signed-in Android QA through 2026-10-08 confirms locked **Home · Services · Track · Wallet · Inbox** navigation without visible overflow; populated CX1F provider discovery, **Recommended for you**, **Explore PNG**, map-first Taxi, Track Completed history, Account mutation/media, categorised Inbox/support, **Wallet/payment preview**, and the truthful Groceries empty-market commerce layout are PASS within the evidence limits. OAuth is environment-blocked; local commerce has no live stores/items for populated Android evidence; other populated journeys and signed-in Web evidence remain open
- production Docker Compose parse PASS was recorded at T2.2; deployment files unchanged
- `git diff --check`: PASS

## Development environment

Primary workstation: **EAGLT02**

Project:
`D:\Project-M.2\wantok-service-recovery`

Local Supabase: Docker.

Android emulator uses ignored:
`.wantok/local-android.json`

and reaches the host through `10.0.2.2:54321`. Do not replace browser/web configuration with the emulator bridge address.

For the current EAGLT02 AVD, use ignored `.wantok/start-wantok-emulator.ps1` if a manual restart is needed. It cold-boots `Medium_Phone_API_36.1` with snapshots disabled, host GPU and audio disabled; the AVD defaults also keep Fast Boot off, 4 CPU cores, host GPU and audio input off. These settings preserve userdata and replace the software-rendered/audio path that crashed during 2026-10-07 QA.

The local Mansfield development account has `tech_platform_admin` only in the local database. This is not seeded by migration and must not be assumed in production.

Technical Control development server may be run on:

`http://127.0.0.1:3100`

## Security/architecture rules

- Use migrations for schema/security changes.
- UI hiding is never authorisation; enforce permissions server-side.
- Operations Admin cannot grant `tech_*` authority.
- Technical Platform Admin does not inherit Operations approval authority.
- Providers cannot self-verify/self-activate.
- Technical module/access changes are audited.
- Lower/equal module administrators cannot modify peer/higher assignments.
- Configuration writes must be schema-versioned and validated server-side.
- Secret-bearing configuration stores references only; never expose secret values in ordinary UI or audit metadata.
- Do not expose production secrets, arbitrary SQL or shell execution in ordinary control-panel UI.
- Keep services modular so one service can be repaired/disabled independently.
- Wantok Services and Wantok Neurons remain separate systems.

## Next phase

**Finish CX1 — Client Experience Completion Gate**, before **T2.4**.

T2.3 checkpoint: **`46d6208`**; prior CX1 reliability/discovery checkpoint: **`0c33a37`**. Required sequence: **finish CX1A/CX1 evidence → T2.4 diagnostics/logs/jobs**.

CX1 now covers reliability, richer client account/profile features, delegated booking across every implemented service family, Saved/media/recommendations/PNG discovery, provider/service search with ratings and Top Wantoks organic discovery, plus the Wantok Agent capability/handoff foundation. The navigation remains **Home · Services · Track · Wallet · Inbox**. Next product additions captured in `docs/ROADMAP_FILLERS.md` include **CX1G General Marketplace + logistics fulfilment**, **CX1H organic/sponsored ranking**, remaining **CX1I model gateway/tool execution/support triage**, **ADS1 Wantok Ads**, and the approved future **GLOB1/TRV1 global-market + international-travel** streams. Fresh signed-in Android/Web evidence is still required before CX1 closes.

Preserve the local development accounts, roles and data. Do not reset/reseed Supabase or replace working modules/configuration. At resume there are two local auth users/profiles and one local `tech_platform_admin` grant.

T2.4 remains deferred until CX1 passes. CX1 migrations `20261006130000_cx1_client_experience_foundations.sql`, `20261006140000_delegated_booking_foundation.sql`, `20261006141000_taxi_delegated_booking.sql`, `20261006142000_event_delegated_booking.sql`, `20261006143000_commerce_delegated_booking.sql`, `20261006144000_water_delegated_booking.sql`, `20261006145000_client_media_storage.sql`, `20261007015000_client_media_ownership_hardening.sql`, `20261007062000_client_service_recommendations.sql`, `20261007063000_client_recommendation_acl_hardening.sql`, `20261007065000_png_service_place_discovery.sql`, `20261007071000_provider_service_discovery.sql`, and `20261007072000_wantok_ai_agent_foundation.sql` are already applied locally; do not reset/reseed Supabase to replay them. General Marketplace, promotions and real AI gateway integrations follow later.

Do not begin Wantok Pay transaction movement until payment-rail and settlement decisions are made.

## Reference-theme continuation — 2026-10-08

- Mansfield supplied **Wantok Services App Showcase (1).png** as an explicit visual reference and requested its white/blue, photo-led super-app design applied across the working Flutter app, **without new image generation** in that instruction. Treat mock-up restaurant names, fares, map routes, bookings, wallet balances and future travel screens as visual examples **only**, never genuine local records or live capabilities.
- Applied the reference visual language: blue primary/accent palette, bright-white app bar and flat five-tab bottom rail, vibrant Home category tiles, compact Home search, PNG scenic Home promotion, retained approved Vanessa provider promotion, lighter Services discovery, photographic Food/Groceries, Delivery/Errands, Specialist/Labour, Events, water/reservations hero cards, photographic login, a blue Wantok Pay **K0.00 preview** card, and simplified Track/Inbox headings.
- Kept the authorised client tabs **Home · Services · Track · Wallet · Inbox** and their existing navigation/actions; changing them to the mock-up's Home/Search/Bookings/Inbox/Account would be a separate information-architecture decision rather than a colour/theme change. Account remains top right and payment actions remain inactive.
- Reused **six existing image files** that had already been created in the preceding exploratory session. No new image generation was performed when applying the exact reference instruction. Registered all images through the existing Flutter asset directory and kept Vanessa's approved asset unchanged.
- Accessibility regression: the new scenic card initially overflowed at 150% text scale on 320/390/800 widths; fixed with a scale-responsive height. Fresh Flutter gate **7 analysis targets PASS, 49 Wantok app tests PASS, both Admin/Technical smoke tests PASS**. Database **27 files / 598 pgTAP PASS**. No migration, money movement, account edit or Supabase reset.
- Android full debug build **PASS**: `apps/wantok_app/build/app/outputs/flutter-apk/app-debug.apk` (~198 MB). **Earlier emulator deployment blocker (resolved by the subsequent x86-only build below)**: preserved `Medium_Phone_API_36.1` only has ~652 MB free under `/data`, and in-place `adb install -r -d` plus non-streaming attempts report `INSTALL_FAILED_INSUFFICIENT_STORAGE` / `Requested internal only, but not enough space`. Existing Wantok package/version 3 and original app data remain intact. Cache-only trimming reclaimed just ~11 MB. Do **not** uninstall or wipe the AVD to resolve this. An x86-only debug APK build was attempted but encountered Windows Gradle/Kotlin generated-cache cleanup locks; old split APK must **not** be installed as current code. Local build logs remain ignored under `.wantok/`.
- This checkpoint establishes a reference-style **code/test baseline**, not a claim of pixel-identical reproduction of all 12 illustrative mock-up screens or successful updated Android runtime QA at that earlier checkpoint. The later smoke-data pilot section documents the successful in-place Android installation and runtime screenshots; signed-in Web CX1 QA remains open.
- Store local/GitHub source checkpoint under the existing branch and verify the remote SHA. GitHub does not back up ignored SDK/emulator or Supabase data.

## Reference Services 12-icon rebuild — 2026-10-08 continuation

The earlier coloured shortcut icons did **not** replace the main Services landing, and the provided Android screenshot demonstrated the old Top providers/Recommendations/Explore PNG hierarchy was still dominating. The canonical real-device Services entry is now the 12-category, **3-column pastel tile grid** from the 2026-10-08 screenshot, with visually corresponding Material icons and accents (Taxi, Food, Groceries, Shopping, Home Services, Beauty, Health, Flights, Events, Professional, Automotive, More). Categories uses the first tab and **All Services** explicitly reaches the preserved backend service catalogue, provider search and existing routing. Search submits into the existing catalogue. Live/approved service slugs open real service modules; currently unsupported category tiles can only open clearly marked, non-transactional samples in a development build and otherwise show 'coming soon'. Injection-based widget tests still exercise the original real catalogue surface.

A 12-screen, on-device reference example gallery appears below the category grid **only** under `--dart-define=WANTOK_SMOKE_DATA=true`; sample screens cover Splash, Sign In, Home, Categories, Food Listing, Restaurant Detail, Taxi, Travel/Flights, Bookings, Tracking, Wallet and Account. Each has a visible `s` badge and deterministic `SMOKE_20261008_SCREEN_001` to `_012` identifier. Additional sample records include Café Melanesia, The Noodle Place, Brisbane Flight and Hilton Brisbane, plus illustrative wallet history; the gallery uses existing high-resolution local PNG-themed imagery rather than claiming the collage's exact individual low-resolution photographs. See `docs/SMOKE_DATA.md`. No real providers/accounts/bookings/transactions are modified.

**Runtime evidence (same preserved emulator):** Rebuilt the Android x86-64 debug APK with `WANTOK_SMOKE_DATA=true` and installed using `adb install -r`, without uninstalling or clearing data; original first-install timestamp remained 2026-10-05 23:44. Real-device screenshot evidence under ignored `.wantok/`: `reference-services-grid-installed.png` verifies the 12 icons arranged in three columns with Categories/All Services; `reference-services-gallery-installed.png` verifies all twelve `s`-marked sample image cards; `reference-food-sample-installed.png` verifies a labelled food-listing preview with its `SMOKE_20261008_SCREEN_005` ID; `reference-gallery-cropped-installed.png` verifies photo framing without distracting baked-in lettering. Genuine services are still available via All Services; the screenshot's individual image originals were not provided separately, so existing photo assets were reused. No production account, provider, payment or order state was fabricated.

## Reversible emulator smoke-data pilot — 2026-10-08

Mansfield approved emulator preservation/expansion and instructed that temporary/sample data be easily identifiable and removable, **with a small visible lowercase `s`**. The implementation uses one isolated, compile-time enabled fixture source at `apps/wantok_app/lib/src/home/smoke_data.dart`; IDs all start `SMOKE_20261008_`, records show an `s` icon beside each item, and tapping reveals the full ID. These are **presentation-only** samples in Home, Services, Food/Groceries, Track, Wallet and Inbox. They make no Supabase writes or live orders/payments/messages; the genuine Wallet balance remains a `K0.00` inactive preview. Build with `--dart-define=WANTOK_SMOKE_DATA=true` only for local demo/QA. The default is false. See `docs/SMOKE_DATA.md` for the complete fixture manifest and removal checklist.

**Emulator recovery:** Full offline AVD backup at `D:\Wantok_AVD_Backups\Medium_Phone_API_36.1_20261008_pre_resize` (1,114 files, ~10.425 GB, Robocopy zero errors). SHA-256 of the original and backup `userdata-qemu.img.qcow2` matched: `8307F175E62E95FFE297BBF54139BA4D9A3BBE0DC13C10B267AFAE478974737C`. Direct config partition expansion proved incompatible with the internal QCOW2 snapshot; a separate experimental flattened copy to D: failed and was never substituted. Original AVD setting restored to 6 GB and emulator booted successfully with preserved Wantok data. **Safer solution:** built x86-64-only debug APK (~91 MB) with smoke mode on and installed it **in place** using `adb install -r`; Android kept the original `firstInstallTime` and updated `lastUpdateTime` to 2026-10-08 16:22. Screenshots in ignored `.wantok/smoke-*-20261008.png` show Home, Services, Track, Wallet and Inbox. Do not wipe the AVD or delete the verified backup.

## GitHub and local backup rule — 2026-10-08

Mansfield has requested **both local Git and GitHub backups after meaningful validated project changes**. The verified project remote is `origin` → `https://github.com/mpokana/wantok-service.git`; working branch `feature/flutter-platform-v1`. Local checkpoint `e04c640` was already found on the remote feature branch during this session. Follow root `AGENTS.md`: audit staged paths for secrets, push the current feature branch without force, and compare the remote branch commit to local `HEAD` after each checkpoint. Never mistake Git for a backup of Supabase volumes, user uploads, or ignored local configuration.

## Recovery rule

If a future chat loses context:

1. open this repository;
2. read `AGENTS.md`, `docs/HANDOVER.md`, `docs/ROADMAP.md`, and `docs/ROADMAP_FILLERS.md`; for global/travel work also read `docs/GLOBAL_TRAVEL_ARCHITECTURE.md`;
3. run `git status --short --branch` and `git log -5 --oneline`;
4. preserve a dirty tree until its purpose is understood;
5. continue the roadmap rather than reconstructing architecture from memory.
