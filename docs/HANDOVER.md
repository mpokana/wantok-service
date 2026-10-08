# Wantok Services — Living Handover

**Updated:** 2026-10-09
**Repository:** `D:\Project-M.2\wantok-service-recovery`
**Branch:** `feature/flutter-platform-v1`

## NEW LOCAL SECURITY CHECKPOINT — 9 October 2026 (signature freshness gate)

- After the one-time metadata claim checkpoint `3c0b42a`, the internal synthetic-candidate quarantine path now defaults to `scanWithFreshClamd` from `packages/evidence_scanner/src/freshness.mjs`. Before sending bytes, it queries the local ClamAV `zVERSION` response, checks parseable UTC signature time within **48 hours** (72-hour hard configurable ceiling; 5-minute future clock-skew allowance), and rejects outages, invalid replies, remote hosts and stale definitions. The clock used for the live probe comes from the backend, not caller parameters. The original generic scanner simulator remains available for unit coverage; injected scanner test doubles are **not production admission**.
- Local test validation: `npm run test:evidence` **57/57 PASS**, `npm run test:evidence:real` **5/5 PASS** with real ClamAV including EICAR and encrypted synthetic quarantine. See `docs/EVIDENCE_SIGNATURE_FRESHNESS.md`. This is an additional **antivirus preflight**, not a durable quarantine custody pipeline or live upload permission.
- Full regression checkpoint: `npm run db:test` **34 files / 736 assertions PASS**; `scripts/flutter/check.ps1` **7 analysis targets clear, 68 Wantok app + 3 Operations Admin + 1 Technical Control tests PASS**; `git diff --check` clean. Git HEAD and GitHub feature-branch SHA must be verified after committing. **Current client roadmap still CX1 OPEN**; signed-in Web QA blocks T2.4. No change to Flutter theme, category photos, s-marked fixtures, user accounts, storage policy, production systems or PostgreSQL schema.

## CURRENT IMPLEMENTATION UPDATE — 9 October 2026 (supersedes prior handover snapshot)

- **Starting Git HEAD:** `4bf2647` (following implemented code `73ea82f`). Resolve the **new** checkpoint with `git log -1 --oneline` and verify its remote using `git ls-remote origin refs/heads/feature/flutter-platform-v1`.
- **Implemented in EAGLT02 only:** `packages/evidence_scanner/src/admission.mjs` now provides an INTERNAL, loopback-only GoTrue `/auth/v1/user` verification step. Applicant identity comes solely from the authenticated GoTrue response, never from Flutter parameters, locally decoded JWTs or a caller-supplied verifier. A separately held server `service_role` credential then calls a restricted, one-time database claim RPC. No HTTP upload listener or Flutter integration has been enabled.
- **Local additive migration:** `20261009043000_evidence_one_time_claim.sql` applied, introducing `claimed_for_quarantine`, a unique claim UUID/timestamp, private receipt and applicant withdrawal even after claim. The RPC rechecks applicant/application/check/planned requirement/category eligibility, and atomically claims once. A duplicate, foreign actor, changed check or withdrawn intent is rejected. Claim success is metadata only, **not evidence storage permission or informed consent**.
- **Validation:** `npm run db:test` **34 files / 736 assertions PASS**; `npm run test:evidence` **46 PASS** (11 additional synthetic GoTrue/HTTP/claim response tests); real ClamAV `npm run test:evidence:real` **4 PASS**. Existing Flutter UI/theme, service-category photos and opt-in `s`-marked smoke fixtures were untouched. Full Flutter checkpoint re-run: **7 analysis targets clear, 68 Wantok app tests + 3 Admin + 1 Technical tests PASS**. The first Flutter subprocess lacked the process `ProgramFiles(x86)` variable; the successful rerun restored it **only for that process**, with no machine configuration or emulator changes.
- **Backups before schema migration:** private restricted full PostgreSQL archive `D:\Wantok_Project_Backups\Private_Supabase_20261008\wantok-pre-one-time-claim-20261009.dump` (TOC checked; restore not rehearsed). Post-migration private PostgreSQL archive verified: `D:\Wantok_Project_Backups\Private_Supabase_20261008\wantok-post-one-time-claim-20261009.dump` (1,265,136 bytes, SHA-256 `9069B72BC4515E140C311F793710299A1CDEAA8864DCC73DC01D404B1D8DBE9E`, only Mansfield and SYSTEM ACL). A TOC validation is **not** a restore rehearsal. Retain a local Git bundle and push/verify the existing GitHub feature branch.
- **Crucial open gates:** no live Auth/claim joined flow, no concurrency stress or crash replay, no approved consent, protected NTFS ACL acceptance/dedicated Linux volume, mature KMS/key custody, durable ciphertext-linked manifest, scanner-signature age gate, hardened PDF/image decoding, privacy/retention/erasure, separate reviewer release or restore exercise. Existing `quarantine.mjs` uses an injected callback in synthetic tests and is **not linked** to this new claim adapter. Never enable real applicant uploads or provider approval.
- **Engineering design and limits:** `docs/EVIDENCE_AUTH_AND_CUSTODY_DESIGN.md`. Continue from that document and `docs/EVIDENCE_QUARANTINE_ADMISSION.md`; old 73ea82f snapshot below remains as historical context. Production/GVE/Wantok Neurons untouched.

## NEW CHAT RESUME CHECKPOINT — 9 October 2026

**Latest implemented-code checkpoint (before this documentation-only update):** `73ea82f71b784d098a3782cb383f40e6b8da9cff` (`feat: add sealed account-bound evidence intent and encrypted quarantine core`). Local HEAD and `origin/feature/flutter-platform-v1` match; working tree was clean before this handover-only documentation update. Repository: `D:\Project-M.2\wantok-service-recovery`, on EAGLT02. The project remains Wantok Services, separate from GVE and Wantok Neurons.

**Resume task:** Continue the **provider-evidence intake security architecture**, not live uploads. The next engineering gate is a trusted, authenticated server-side admission service that verifies Supabase JWT/account/app/check/intent associations and atomically claims an intent before encrypted quarantine; ensure proper Windows ACLs or a dedicated Linux volume, managed encryption keys, durable integrity/audit, revocation, retention, scanner health and legitimate privacy consent. Audit, design and test locally before enabling a network route. The current `quarantine.mjs` verification callback in tests is injected, **not** real JWT/Supabase authority. Do not imply live upload readiness or connect Flutter to the sealed bucket.

**Implemented & validated (local dev only):**
- Official ClamAV 1.5.4 on EAGLT02, container `wantok-clamav-scanner`, loopback-only `127.0.0.1:3310`, persistent signature volume, 4 GiB/2 CPU caps; signatures **28147** at last recorded check. Run `scripts/clamav-local.ps1 -Action Status` then `-Action Test` and monitor signature freshness.
- `staged-provider-evidence` Supabase Storage bucket remains PRIVATE with **no client object policies**. The `staged_evidence_intake_intents` migration `20261009024500_evidence_intake_intents.sql` records only revocable, applicant-bound **non-uploading** intents. Draft notice marker is **not valid consent**. `quarantine.mjs` encrypts synthetic scanned bytes to temporary AES-256-GCM candidates; exclusive creation is **not** a complete atomic custody or immutable storage solution.
- Latest tests: `npm run db:test` **33 files / 711 assertions PASS**; `npm run test:evidence` **35 PASS**; `npm run test:evidence:real` **4 PASS**; `scripts/flutter/check.ps1`: seven analysis targets clear, **68 app / 3 Admin / 1 Technical tests PASS**. Android emulator `emulator-5554` retained, with **no reinstall or data reset** for this backend-only phase.
- Backups: verified GitHub feature-branch SHA above; verified local Git bundle `D:\Wantok_Project_Backups\wantok-services-encrypted-quarantine-73ea82f-20261009.bundle`; private PostgreSQL archive `D:\Wantok_Project_Backups\Private_Supabase_20261008\wantok-evidence-intents-20261009.dump` (archive TOC checked; **restore rehearsal not done**). The local ClamAV Docker image/container/signature volume are **not** included in Git bundles.
- Approved image-rich service category theme, unified category pictures across screens, opt-in `SMOKE_20261008_*` fixtures and visible small **s** indicators must be preserved. No fake live vendors, approvals, bookings or payments. Production remains untouched. Existing CX1 signed-in Web QA gate and later T2.4 dependency remain open, independent of the evidence-work milestone.

**Read next (in this order):** root `AGENTS.md`, this handover, `docs/ROADMAP.md`, `docs/ROADMAP_FILLERS.md`, `docs/EVIDENCE_QUARANTINE_ADMISSION.md`, `docs/CLAMAV_LOCAL_RUNTIME.md`, and the relevant architecture documents. Inspect `git status --short --branch`, exact GitHub branch SHA and real scanner health before modifying anything. Follow additive migrations, full test gate, **GitHub plus local bundle and private DB backup** for changed database phases.

**Do NOT assume complete:** public upload/JWT gateway, one-time atomic intent claim, key custody/rotation, protected filesystem ACLs, MIME/PDF decoder isolation, production-grade malware controls/retention/audited reviewer release, consent/privacy compliance, admin provider approval, Web CX1 gate or restore drill. Never make the `staged-provider-evidence` bucket publicly writable or reuse owner-editable `provider-documents`.

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

## Sealed admission intent + encrypted quarantine candidate — 2026-10-09

Resumed from `a19ef02`, audited the existing handover, Storage policy and healthy local ClamAV (`ClamAV 1.5.4 / signatures 28147`). The EAGLT02 **local development database only** now has additive migration `20261009024500_evidence_intake_intents.sql`: an authenticated applicant can prepare one **non-uploading, revocable intent** for a planned checklist item belonging to their `in_review` application in one of the permitted staged categories. The `consent_notice_version` is a **draft technical handshake only**, not actual approved informed consent. Auth identity comes from `auth.uid()`; RLS restricts cross-account reads; direct table writes are denied; withdrawn intents cannot be silently recreated. Test `033_evidence_intake_intents.test.sql` passes with full local database suite **33 files / 711 pgTAP assertions**. The `staged-provider-evidence` bucket remains sealed, and no signed upload URL or external gateway exists.

Added `packages/evidence_scanner/src/quarantine.mjs`: local-only **AES-256-GCM encrypted** candidate quarantine requiring a 256-bit key and a separately verified account/app/check/intent tuple, plus positive ClamAV verdict; it stores exclusive-write ciphertext and non-document receipt with SHA-256 as authenticated data, never provides decrypted reviewer content. Tampering, duplicates, wrong keys, absent verification and scanner failure block admission in synthetic tests. A real-ClamAV integration test scans synthetic in-memory PDF-like data, creates and verifies only an isolated encrypted temporary candidate, then deletes it. The test's `verifyIntent` callback is *injected*, not a production JWT/Supabase authority; **do not claim a live end-to-end authenticated intake system**. Windows `mode=0600` is not a replacement for protected ACLs and the file/metadata pair is not yet atomic with the database. Formal consent, encrypted key management, immutable storage, retention, a trusted gateway, scanner-monitoring and reviewer release require later gated work; no app screens, sample records or production services were altered. See `docs/EVIDENCE_QUARANTINE_ADMISSION.md`.

**Acceptance so far:** additive migration applied ONLY to EAGLT02 local Supabase, **33 database files / 711 pgTAP checks PASS**; **35 isolated scanner/quarantine tests PASS** and **4 real-ClamAV integration tests PASS**, including encrypted temporary candidate integrity. New private PostgreSQL 17 custom-format backup saved to `D:\Wantok_Project_Backups\Private_Supabase_20261008\wantok-evidence-intents-20261009.dump` (1,254,848 bytes; SHA-256 `F08F836EF4D101E105CB8AC2D5C78C4AF13260E5DD7AD1BB2935A2B8380B20E8`). Archive TOC and restricted file ACL verified; **no restore test performed**. **Full Flutter acceptance PASS:** seven analysis targets clean, 68 Wantok app tests, 3 Admin tests and 1 Technical smoke test all PASS; existing `emulator-5554` online without any APK reinstall or data reset (no Flutter changes in this phase). GitHub/local source checkpoint follows. Real application uploads, provider activation and evidence review remain disabled.

## Real ClamAV on EAGLT02 — refreshed signatures and live EICAR acceptance — 2026-10-09

The previously local test-double-only scanner was converted into a **real scanner integration on EAGLT02**, after C: space increased from approximately 7.6 to **51.2 GiB free**. Pulled the official `clamav/clamav:stable` image, started isolated `wantok-clamav-scanner` with persistent `wantok-clamav-signatures` volume, 4 GiB RAM cap, 2 CPU cap and **127.0.0.1:3310** binding (no public ClamAV TCP listener). No Supabase containers/Docker root location/Flutter app changed. The initial automatic FreshClam update failed (403); a single **scanner-only restart** restored version DNS/update path. Verified **ClamAV 1.5.4 / daily signatures 28147 (8 Oct UTC)**, valid database signature and `clamd` reload of about 3.63m signatures; scanner using about 1.1 GiB RAM.

Added **reusable, separate** `npm run test:evidence:real` command and `packages/evidence_scanner/test/real-clamd.test.mjs`. All **3 live tests PASS**: clean in-memory PDF-like payload receives candidate_clean, the **harmless EICAR 68-byte AV test string** is rejected as `MALWARE_FOUND`, and clean results never unlock storage/reviewer access/provider approval. The original **24 protocol/unit tests** remain independent of the real scanner. Safe operations `scripts/clamav-local.ps1` (Status/Start/Stop/Test) and exact architecture/limitations are documented in `docs/CLAMAV_LOCAL_RUNTIME.md`. This verifies live EICAR detection, not complete arbitrary document safety. Definitions must be monitored; the initial 403 warning has been documented.

**Strict boundary:** the staged-provider-evidence bucket still has no ordinary Storage object grants; no API, upload path, quarantine release, clinical/financial onboarding or production migration was enabled. No real documents submitted. Existing approved imagery and `s`-marked sample data unchanged. Previous local PostgreSQL custom-format backup remains valid because database unchanged; full restore still outstanding. GitHub feature branch and independent local Git source bundle to be verified at final checkpoint.

## Scanner component prototype — local-only, sealed intake — 2026-10-09

Following `e3cab04`, built a dependency-free isolated Node scanner component in `packages/evidence_scanner/` and a root `npm run test:evidence` gate. It checks filename/path safety, 5 MiB limit, declared MIME against extension and basic PDF/JPEG/PNG content signature, PNG structure/pixel limits, and produces SHA-256 metadata. It implements the local-only ClamAV `zINSTREAM` TCP protocol in 64 KiB chunks, requires exact `stream: OK`, rejects `... FOUND`, and fails closed on timeouts, errors, unknown replies and scanner absence. **A clean scan yields `candidate_clean` only; `storagePermitted=false`, `reviewerAccessPermitted=false`, `approved=false` always.** No HTTP listener, upload token, storage, user-facing flow or database migration has been added.

EAGLT02 audit: C: approximately **7.6 GiB free** and D: **96.6 GiB free**; Supabase Docker services running. To avoid breaking working systems or exhausting C:, **did not pull an antivirus image or reconfigure Docker's data root**. There is **no verified real ClamAV engine scan**: **24/24 Node tests PASS** using a loopback TCP protocol test double, not proof of malware-detection efficacy. Retested the unchanged platform: **32 files / 688 pgTAP assertions PASS; seven Flutter analysis targets clean, 68 Wantok app tests, 3 Admin tests and 1 Technical test PASS**. Existing emulator `emulator-5554` still online, with no APK rebuild or data reset necessary (no Flutter changes). The existing `staged-provider-evidence` bucket remains sealed. No real files or Supabase smoke/identity data were uploaded. Full release prerequisites and limitations: `docs/EVIDENCE_SCANNER_CORE.md`. Require real scanner provisioning, health/signature updates, true malicious-test-signature detection, isolated decoder, authenticated ingestion/quarantine/versioning/retention and separate reviewer security controls before opening intake. Production untouched.

## Sealed evidence boundary and future requirement planning — 2026-10-09

Starting from source checkpoint `76b8911`, audited Storage object policies: the original `provider-documents` bucket permits account owners to update/delete uploaded files, so it must **not** be used for sensitive staged verification evidence. Built additive migration `20261009011500_evidence_vault_boundary.sql`: new `staged-provider-evidence` private bucket (5 MiB, PDF/JPEG/PNG MIME declarations) with **no ordinary Storage object policies**; therefore clients cannot upload/read/replace/delete. No documents are collected and malware scanning is NOT active. The separate RLS tables `staged_evidence_requirements` and `staged_evidence_requirement_audit` track admin-only *future evidence planning*, not document custody. `plan_staged_evidence_requirement` requires an admin and a reviewed staged application, and is idempotent; `cancel_staged_evidence_requirement` cancels a plan with audit. No provider activation, notifications, final approval, booking/payment or legacy Storage rule changes. Restricted regulated categories remain closed.

Operations Admin's preliminary checklist now includes **Evidence planning**, confirmation and status history; an applicant's submitted preliminary application shows a read-only notice that secure upload is unavailable and identity/licence/financial documents should **not** be sent. UI uses the existing design tokens and does not touch the approved photo categories or `s`-marked sample fixtures. See `docs/PROVIDER_EVIDENCE_VAULT.md`. **Acceptance:** local Supabase **32 files / 688 pgTAP PASS**, including denied authenticated Storage object INSERT, planning ownership RLS, other-account isolation and denied cancellation, admin-only audit, idempotent plan and cancellation. `scripts/flutter/check.ps1` complete with seven analysis targets clean, **68 app tests**, **3 Admin tests** and **1 Technical test PASS**. Smoke-enabled x86-64 Android debug APK built and installed in place on preserved `emulator-5554`; `firstInstallTime=2026-10-05 23:44:14`, updated `lastUpdateTime=2026-10-09 01:34:01`. Visual QA screenshot `.wantok/wantok-evidence-vault-services.png` confirms the reference-picture Services grid and unchanged tabs. The applicant read-only evidence warning and the Admin plan/cancel confirmation were exercised via injected-data widget tests; **no live document-upload pathway or populated real Admin evidence queue was exercised**. Full PostgreSQL custom-format local backup `D:\Wantok_Project_Backups\Private_Supabase_20261008\wantok-evidence-vault-boundary-20261009.dump` (1,243,534 bytes, SHA-256 `4C463AE3983CE864D5489FAB04410E73B17DF040082CB3EF12311E65E30773E8`) has a structurally valid TOC and private ACL; **no restore test performed**. Source GitHub and local Git bundle checkpoint follows. **Production remains unchanged.**

## Staged verification checklists and admin-only audit — 2026-10-08

After source checkpoint 0bc3014, audited the original `provider-documents` bucket: owner update/delete privileges mean it is **not suitable as immutable provider-identity evidence**. No staged credential uploads were enabled or existing storage policies changed. Instead, migration `20261008234500_staged_verification_progress.sql` introduces per-application policy-snapshot checklist records and a separate admin-only status-change audit. RLS permits users to read only their own checklist; applicants have no write access or admin audit visibility. The admin-only `update_staged_verification_check` RPC permits `pending`, `under_review`, `needs_followup` **only when a preliminary application is in_review**. It rejects `approved`, never grants roles/provider status or publishes services. Admin's Preliminary onboarding queue now opens a dedicated checklist with confirmed progress actions and read-only audit activity. Applicants can view their status but not change it. No identity/licence/medical/financial documents or actual provider approvals are collected. The legacy provider approval implementation remains unchanged. See `docs/STAGED_VERIFICATION_PROGRESS.md`.

Local-only database migration and `031_staged_verification_progress.test.sql` added. Local pgTAP gate **31 test files / 659 tests PASS** (including cross-user isolation, auth, idempotency, audit, denial of `approved` and no provider activation). **Acceptance PASS:** `scripts/flutter/check.ps1` clean across 7 analysis targets; **68 Wantok app tests**, **2 Admin tests** (including confirmed review/audit status workflow), **1 Technical console smoke test** all PASS. Local Supabase **31 test files / 659 pgTAP assertions PASS**. Built a fresh smoke-enabled x86-64 debug APK and installed it in place on EAGLT02 `emulator-5554` using `adb install -r`; original `firstInstallTime=2026-10-05 23:44:14`, updated `lastUpdateTime=2026-10-08 23:54:29`; user data preserved. Visual regression `.wantok/wantok-verification-progress-nav2.png` confirms the Home Services photo and preliminary application entry point remain correct. No actual applicant or regulated identity data submitted. The new applicant checklist and Admin-only audit UI are verified by deterministic injected widget data; a populated live Admin review queue was not visually checked. A **full local PostgreSQL 17 custom-format backup** was saved to ACL-restricted `D:\Wantok_Project_Backups\Private_Supabase_20261008\wantok-verification-progress-20261008.dump` (1,225,799 bytes, SHA-256 `EB0F19A5D278EE9638A586892DF337A4F309B14009564DBD9E8C3A31A90BE54E`), and archive listing verified. A restore test was not performed. Document processing, protected storage, malware scanning, expiry, retention, reviewer separation and licensed-provider approval remain future gated milestones. Production untouched.

## Preliminary provider applications and controlled triage — 2026-10-08

Following checkpoint 3ba8ca9, audited the legacy `review_provider_application` function: approving an existing application automatically marks a provider verified/active. Therefore **do not reuse that function for the new verticals**. Migration `20261008231500_staged_provider_onboarding.sql` introduces `provider_onboarding_policies` for seven categories and a separate RLS-controlled `staged_provider_applications` table. Initial preliminary intake is staged for **Shopping & Retail, Home Services and Beauty & Wellness only**. **Health & Medical, Financial Services, Travel & Flights, Education & Training remain explicitly restricted** until legal, licensing, safeguarding and supplier obligations are designed/verified. This is a design safety restriction, not a completed regulatory assessment.

Flutter `CategoryInformationPage` fetches policy and conditionally offers the preliminary application button; missing policy or older backend fails closed. `StagedProviderApplicationPage` shows a future verification checklist and captures only basic applicant name/type, province/town and service summary, with no protected-document upload or booking/payments. Existing duplicate submissions display current status. Operations Admin → Providers includes a separate preliminary review queue. Admin `triage_staged_provider_application` accepts only manual **in_review** or **declined**, never **approved**, and does not change provider permissions. Existing provider-interest queue and legacy applications remain intact. Full design and release guards: `docs/PROVIDER_STAGED_ONBOARDING.md`.

Migration applied locally on EAGLT02 **only**, not to production. Database tests include `030_staged_provider_onboarding.test.sql`: **30 files / 635 tests PASS**, including regulated gates, RLS, duplicate protection, ordinary-user denial, admin review and explicit rejection of admin approval attempts. Focused Flutter tests for staged forms, category availability and read-only info pass. The first emulator inspection identified a pre-existing routing mismatch: the photo-grid **Home Services** tile still pointed to `specialist-services`. Corrected its route to `home-services` in `reference_services_gallery.dart` while retaining **Professional Services → specialist-services**, with a new explicit regression assertion. **Final acceptance:** full Flutter gate: 7 analysis targets PASS, **67 Wantok app tests PASS** plus Admin/Technical console smoke PASS. Local Supabase suite **30 files / 635 pgTAP PASS**. The corrected x86-64 debug APK was installed in place using `adb install -r`; emulator preserved the original `firstInstallTime=2026-10-05 23:44:14` with updated `lastUpdateTime=2026-10-08 23:10:06`. Visual captures under ignored `.wantok/wantok-corrected-home-services.png` and `.wantok/wantok-staged-application-form.png` confirm the separate Home Services information/readiness page, active preliminary-application CTA, and future verification checklist/basic form. No real preliminary application was submitted. **Local database recovery:** a PostgreSQL 17.11 consistent, full custom-format archive was created directly from local `supabase_db_wantok-service`, then copied to the ACL-restricted `D:\Wantok_Project_Backups\Private_Supabase_20261008\wantok-staged-onboarding-20261008.dump` (1,209,383 bytes, SHA-256 `1EEA64C5DC0E5DAD4B6CAF792AE8E8980FD73ABC38A9BBA158E39B9FDB674F79`). `pg_restore --list` returned success with 1,895 TOC entries; **an actual restore was not attempted**. Separate public-schema and data-only SQL dumps in the same private folder supplement the archive; the data-only dump warned about circular category FKs, so use the full archive for recovery planning. ACL explicitly grants only `EAGLT02\Mansfield` and SYSTEM. GitHub/local source checkpoint follows this acceptance note.

## Controlled provider interest and category-scoped discovery — 2026-10-08

Completed next safe milestone after checkpoint 930bf9d. Reused the existing verified-provider search in ProviderDiscoveryPage, now supporting an initial category ID/name from CategoryInformationPage. Verified-active provider filtering and category ID restrictions remain server-side. The seven catalogue-only categories offer an explicit account-bound **Register provider interest** action and display the existing registration state; no auto-approval, provider role assignment, notification promise, payment or booking.

Additive local-only Supabase migration 20261008223000_provider_category_interest.sql creates the private provider_category_interests table with authenticated identity, category, fixed received status, created time, RLS for the account owner/admin and **no direct user insert/update/delete grants**. Registering interest is possible only through RPC register_provider_category_interest(text), which validates active information-only categories with catalogue_only/onboarding_disabled metadata; repeat submissions are idempotent. Medical and financial formal onboarding stays closed. Test 029 checks cross-account isolation, grants, repeated submissions, and categorical restrictions. Operations Admin → Providers → Interest queue provides **read-only** administrative visibility without approval actions. See docs/PROVIDER_CATEGORY_INTEREST.md.

No modifications to real provider_applications, provider_profiles, provider_services, service_bookings, payment tables, production database, or smoke records. EAGLT02 local-only migration complete and pgTAP baseline **29 files / 617 tests PASS**. Flutter check includes **65 app tests PASS**, all seven analysis targets, Admin/Technical smoke tests; update exact checkpoints after Android QA. **Runtime acceptance:** after full Flutter PASS (65 app widget tests and Admin/Technical smoke) and local pgTAP PASS (617 checks), built a smoke-enabled, x86-64 APK and installed over preserved `emulator-5554` using `adb install -r`. Android reports the same original `firstInstallTime=2026-10-05 23:44:14`, updated `lastUpdateTime=2026-10-08 22:19:01` and 755 MB free. Inspected `.wantok/wantok-provider-interest-top.png` and `.wantok/wantok-provider-category-search.png`: Health & Medical correctly shows the non-transactional registration prompt and the verified-provider search pre-selects Health & Medical with a truthful no-matching-providers result. No real account interest was submitted in UI testing.

Release of registration CTA requires backend migration deployment and an approved release plan; the CTA is hidden for categories not returned by an older backend.

## Expanded reference service catalogue — 2026-10-08

Mansfield approved **direct Flutter/backend implementation with no new image generation**. The existing text-free twelve category pictures already in `apps/wantok_app/assets/images/categories` remain the canonical reference artwork, shared through `WantokCategoryStyles`, `WantokCategoryPicture` and `WantokCategoryTile` across Home, Services and headers. The Services landing now uses the reference heading **All Services**, three-column image cards and each name **beneath** its corresponding picture. A separate provider-catalogue action and search remain accessible. The earlier twelve category identities are preserved and six additional cards were inserted before More: **Delivery**, **Hotels**, **Education & Training**, **Financial Services**, **Water Transport**, **General Labour**. The extended cards reuse existing approved local image assets; no new pictures were generated for this task.

New additive Supabase migration `20261008214500_client_category_expansion.sql` adds **seven actual catalogue-only** backend categories: Shopping & Retail (`shopping-retail`), Home Services (`home-services`), Beauty & Wellness (`beauty-wellness`), Health & Medical (`health-medical`), Travel & Flights (`travel-flights`), Education & Training (`education-training`), and Financial Services (`financial-services`). All seven are **information-only** with metadata flags `rollout_status=catalogue_only`, `transactions_enabled=false` and `provider_onboarding_enabled=false`. Medical and financial entries explicitly require licensed/regulated provider verification. The migration inserts **no fake providers, user profiles, payments, offers, availability or bookings**, and does not re-enable the existing disabled `accommodation` booking service.

The Flutter routing in `services_hub_page.dart` sends information-only backend categories (or not-yet-live catalogue entries) to `CategoryInformationPage`, which reuses each category's same photo and shows a non-transactional 'Provider listings coming soon' notice without any booking/payment controls. Existing live taxi, food, courier, event, labour and water routes keep their established implementations. Production DB remains untouched; migration executed **locally on EAGLT02 only**. `supabase/tests/028_client_category_expansion.test.sql` exercises catalogue metadata, retained original services, and absence of invented providers; the existing enterprise contract now asserts the correct expanded **22 total / 19 active** category baseline.

**Acceptance (same preserved EAGLT02 emulator):** Flutter analysis across all seven targets PASS, **64 Flutter app tests PASS** plus Admin/Technical console smoke tests PASS. Local Supabase test gate **28 files / 607 pgTAP PASS**, including the new category-expansion assertions. An x86-64 debug APK was installed in place using `adb install -r`; Android retained firstInstallTime `2026-10-05 23:44:14`, original userdata and 667 MB free storage. Emulator captures saved outside Git under `.wantok/wantok-18-services.png`, `.wantok/wantok-health-info.png`, and `.wantok/wantok-final-water-grid.png` verify the 18-card grid, Health & Medical information-only details and clean water transport thumbnail. Cropped a new water thumbnail from the existing local water photo after visual QA found baked-in lettering; no image generation. The six additional cards reuse approved assets until dedicated artwork is supplied. Do not confuse this local end-to-end acceptance with live production deployment.

The design screenshot is a *visual reference*, not a source of real provider records. All runtime smoke examples retain their own `SMOKE_20261008_*` IDs and small `s` badge, are still opt-in via `WANTOK_SMOKE_DATA=true`, and must be removed before production per `docs/SMOKE_DATA.md`. Do not conflate permanent category artwork with sample data.

## Generated category picture rollout — 2026-10-08

Mansfield approved replacing plain Material category icons with **realistic AI-generated service pictures, names beneath the photos, and consistent imagery on every screen**. On EAGLT02, the previously unfinished shared-category work in `wantok_category_ui.dart` was preserved and completed rather than overwritten. A newly generated Wantok Services visual reference was transferred to the authorised computer and cropped into **twelve text-free pictures** in `apps/wantok_app/assets/images/categories/` (288 × 192 WebP), plus a clean Delivery picture from existing approved local delivery artwork. Images are explicitly registered in Flutter `pubspec.yaml`. See `docs/CATEGORY_IMAGES.md`.

`WantokCategoryStyles.bySlug` is now the **single source of truth** for accent, fallback icon and image asset path. `WantokCategoryPicture` renders the same image within `WantokCategoryTile` (Services grid, Home shortcuts, real All Services) and `WantokCategoryBadge` (compact Home chips and real service-page headers). Home spotlight cards use the common picture with the label underneath. Saved buttons, service links, booking logic and Supabase schemas are preserved. Additional backend categories have stable contextual local images through the same registry. These illustrations are **permanent design assets**; the `s` badge remains reserved for removable demonstration records.

Regression repairs: when the older tile was replaced by the shared photo tile, `client_journeys_test.dart` was updated to find stable category keys rather than the old widget type while retaining original navigation assertions. A narrow-screen Water Transport AppBar title overflow was corrected using a flexible ellipsised label. Test and Android evidence is stored locally under ignored `.wantok/`. The Android build was installed in place with `adb install -r` and no local userdata reset.

## Reference Services 12-icon rebuild — 2026-10-08 continuation

The earlier coloured shortcut icons did **not** replace the main Services landing, and the provided Android screenshot demonstrated the old Top providers/Recommendations/Explore PNG hierarchy was still dominating. The canonical real-device Services entry is now the 12-category, **3-column pastel tile grid** from the 2026-10-08 screenshot, with visually corresponding Material icons and accents (Taxi, Food, Groceries, Shopping, Home Services, Beauty, Health, Flights, Events, Professional, Automotive, More). Categories uses the first tab and **All Services** explicitly reaches the preserved backend service catalogue, provider search and existing routing. Search submits into the existing catalogue. Live/approved service slugs open real service modules; currently unsupported category tiles can only open clearly marked, non-transactional samples in a development build and otherwise show 'coming soon'. Injection-based widget tests still exercise the original real catalogue surface.

A 12-screen, on-device reference example gallery appears below the category grid **only** under `--dart-define=WANTOK_SMOKE_DATA=true`; sample screens cover Splash, Sign In, Home, Categories, Food Listing, Restaurant Detail, Taxi, Travel/Flights, Bookings, Tracking, Wallet and Account. Each has a visible `s` badge and deterministic `SMOKE_20261008_SCREEN_001` to `_012` identifier. Additional sample records include Café Melanesia, The Noodle Place, Brisbane Flight and Hilton Brisbane, plus illustrative wallet history; the gallery uses existing high-resolution local PNG-themed imagery rather than claiming the collage's exact individual low-resolution photographs. See `docs/SMOKE_DATA.md`. No real providers/accounts/bookings/transactions are modified.

**Runtime evidence (same preserved emulator):** Rebuilt the Android x86-64 debug APK with `WANTOK_SMOKE_DATA=true` and installed using `adb install -r`, without uninstalling or clearing data; original first-install timestamp remained 2026-10-05 23:44. Real-device screenshot evidence under ignored `.wantok/`: `reference-services-grid-installed.png` verifies the 12 icons arranged in three columns with Categories/All Services; `reference-services-gallery-installed.png` verifies all twelve `s`-marked sample image cards; `reference-food-sample-installed.png` verifies a labelled food-listing preview with its `SMOKE_20261008_SCREEN_005` ID; `reference-gallery-cropped-installed.png` verifies photo framing without distracting baked-in lettering. Genuine services are still available via All Services; the screenshot's individual image originals were not provided separately, so existing photo assets were reused. No production account, provider, payment or order state was fabricated.

## EAGLT02 — repeatable Android emulator launch (2026-10-08)

The existing `Medium_Phone_API_36.1` AVD has been restarted in **Mansfield's active desktop session (Session 1)** without wiping userdata, and the installed `io.wantok.service/.MainActivity` has been started. A launch attempted directly from remote Desktop Commander can create invisible Session 0 emulator processes; use the registered interactive scheduled task `Wantok Services Emulator UI` when running remotely. An emulator was safely stopped with `adb emu kill` and restarted via this task, not re-created, uninstalled or reset.

Reusable launch scripts are tracked at `scripts/flutter/Start-Wantok-Emulator.ps1` and `scripts/flutter/Start-Wantok-Emulator.cmd`. A user-local desktop shortcut `C:\Users\Mansfield\Desktop\Start Wantok Emulator.lnk` points to the CMD launcher. The PowerShell script checks that the named AVD exists, reuses an already running emulator, otherwise starts it in the active desktop session (using the scheduled task when called from background Session 0), waits for Android's `sys.boot_completed=1`, then starts Wantok Services if installed. It never invokes `-wipe-data`, `adb uninstall`, or AVD recreation. Manual command:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "D:\Project-M.2\wantok-service-recovery\scripts\flutter\Start-Wantok-Emulator.ps1"
```

Validation: `adb devices -l` reports `emulator-5554 device`, Wantok `am start` returned the already-running top-most instance warning on a repeat run, and the original `/data` remained mounted with about 702 MB available. The existing offline AVD backup at `D:\Wantok_AVD_Backups\Medium_Phone_API_36.1_20261008_pre_resize` remains untouched.

## Reference screen-detail continuation — 2026-10-08

After checkpoint `20ab669`, the Services 12-category front door was correct but the 12 screenshot samples were still mostly generic photograph+list previews. A new isolated source file `apps/wantok_app/lib/src/home/reference_scene_details.dart` now renders differentiated development-only bodies: four photo-backed restaurant rows with rating/filter/location presentation, sample taxi vehicle-tier selection, flight/hotel/package tab and dummy itinerary fields, bookings status chips, driver/vehicle tracking card, inactive Wallet actions, sample account menu and colourful Home shortcuts. The existing Restaurant Detail sample menu, synthetic route drawing, inactive preview Wallet balance and actual Live All Services catalogue remain separate. No sample widget has a Supabase client or booking/payment/dispatch callback. New regression test `test/reference_scene_details_test.dart` validates the sample screens and that action buttons remain disabled. Food rows show a little `s` marker plus the canonical `SMOKE_20261008_FOOD_*` IDs; see `docs/SMOKE_DATA.md`.

**Privacy/production rule:** All data in the scene gallery is gated by `WANTOK_SMOKE_DATA=true`, false by default. Sample photos and values are illustrations, not real menus, taxi fares, flights, hotel inventory, wallet balances or tracking coordinates. Preserve the saved local database and signed-in app state. Validation: seven Flutter analysis targets PASS, **58 Flutter app tests PASS**, both console smoke tests PASS, database **27 files / 598 pgTAP PASS**; smoke-enabled focused tests PASS. Built x86-64 debug APK with `WANTOK_SMOKE_DATA=true` and installed it **in place** on preserved `emulator-5554` (original app first-install timestamp unchanged, update 2026-10-08 17:22). Emulator screenshots of the 12-icon Services landing, 12-screen gallery and refined Food Listing are stored locally under ignored `.wantok/resume-services.png`, `.wantok/resume-gallery.png`, `.wantok/resume-food.png`. Genuine Home remains separate. Remaining work: progressively apply comparable design polish to actual service booking/listing modules, replacing temporary previews only when capabilities are real, and finish signed-in Android/Web CX1 acceptance without changing payment state.

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
