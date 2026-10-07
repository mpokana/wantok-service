# Wantok Services — Living Handover

**Updated:** 2026-10-07
**Repository:** `D:\Project-M.2\wantok-service-recovery`
**Branch:** `feature/flutter-platform-v1`

## Resume here

The current working phase is **CX1 client-experience completion**; the **CX1 gate remains open before T2.4**. Delegated booking is checkpointed across every currently implemented client service family. The active CX1 extensions now include **CX1F provider/service discovery with ratings** and the **CX1I Wantok AI Agent capability/human-handoff foundation**. General Marketplace/fulfilment (CX1G), sponsored promotion (CX1H) and model-backed AI/tool execution (remaining CX1I) are still planned. Run:

`git log -1 --oneline`

to resolve its exact commit hash.

Before any new task, read root `AGENTS.md`, this file, `docs/ROADMAP.md`, and **`docs/ROADMAP_FILLERS.md`**. The filler file carries Mansfield's incremental additions without rewriting the main roadmap.

## Product identity

- Product: Wantok Services
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
- CX1 reliability/discovery baseline plus richer client account/privacy, delegated booking, Saved/media/recommendations/Explore PNG, provider/service search with ratings, Top Wantoks organic discovery, and Wantok AI Agent placeholder/handoff foundation (gate open)

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
- richer Home hierarchy with scenic hero, service discovery, Wantok Pay preview strip, service spotlights and PNG purpose banner
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
- Services owns rich discovery: family filters/search/clear, safe loading/error/empty states, Saved controls, **For you**, **Explore PNG**, **Find providers**, and **Top Wantoks**. Provider discovery searches active verified providers through approved active services, shows real 1–5 star rating/review counts, exposes approved services on provider detail, supports saving providers, and exposes category/province/town client filters backed by structured server-side coverage. Organic ranking is confidence-aware so a 5.0/1-review provider does not automatically outrank an established high-quality provider. Top Wantoks is a daily rotating subset from the qualified organic pool; paid placement is not mixed into the score.
- Account/Profile now includes bio/avatar URL foundation, privacy/share controls, linked-account management, Saved, Trusted people, My reviews and separate Business/Vendor profile presentation under one login.
- Supabase identity linking is used for Google/Facebook; no parallel customer account is created by UI design.
- owner-scoped `client_saved_items` and secured bookmark RPC validate that only discoverable entities can be saved.
- owner-scoped `trusted_people` feeds the delegated-booking contract. Vehicle/Boat/Venue reservations, Delivery/Errands/Specialist/Labour requests, Taxi/Ride, Events/ticketing, Food/Groceries commerce and scheduled Boat/Ship passenger transport support **Who is this for?**. Taxi keeps the signed-in account as `passenger_id`/payer while driver-facing RPCs resolve the selected Trusted person as the actual rider and retain a separate `booked_by_name`. Events keep the signed-in customer as registration/payment/cancellation owner while snapshotting the selected Trusted person as primary attendee for customer/organiser views. Beneficiary snapshots preserve history and do not grant account access.
- existing `service_reviews` is extended with title/photo URL/visibility fields; review writes use a secured RPC limited to completed customer bookings; provider rating aggregation remains the existing trigger.
- Track offers Review/Edit review for eligible completed generic service bookings and retains specialised ride/order/event/water shortcuts.
- Wallet remains preview-only but now frames Top up/Scan/Send/Receive, verification, PNG-oriented planned services and future transaction history. No money movement exists.
- Home now exposes a **Wantok AI Agent** entry without adding a sixth bottom-navigation tab. The authenticated capability API reports model/chat/handoff state; model chat is deliberately disabled until a controlled gateway is configured. The Agent surface can use real provider-search fallback and can create owner-private human-help requests. Support/Operations/Admin can later triage those requests; live human chat and support triage UI are not yet implemented.
- retry failures stay in the view rather than escaping callbacks; Events/departures/order/registration/water-trip failures do not masquerade as empty records.
- 33 focused client regressions plus the configuration smoke total 34 app tests; they use in-memory/unconfigured backends and do not replace local account data.
- entry/back navigation coverage includes 11 categories; Taxi map/location/runtime behaviour and the new CX1A surfaces still require live QA.
- do not call CX1 complete from widget/database tests alone; see its evidence document.

## Android continuation evidence — 2026-10-07

- Resumed clean `feature/flutter-platform-v1` at `b69656b`. Prior debug APK build confirmed complete by Gradle daemon Success at 08:32:04 PGT and matching APK/SHA-1 artifacts. Installed it with `adb install -r` on the preserved emulator; Success, unchanged first-install timestamp and existing Mansfield sign-in. New rebuild attempts with `.wantok/local-android.json` failed with Java loopback IOException, including the IPv4 retry; do not report those attempts as PASS.
- Home/Services retain locked five-tab navigation. Services → Find providers, Agent → plumber search, clear/Top Wantoks empty state and category/province menus verified. Local DB has **0 provider profiles / 0 provider services**; menus contain only All, town disabled. Populated filter/rating/save/detail evidence remains open and needs real approved service coverage; no fixtures/approvals were created.
- Wantok AI Agent capability status and disabled model input verified. Android Talk to a person submission showed success and created one `open` request owned by the existing Mansfield profile, ID `640eded2-0367-402a-8555-1252b306acb0`, with `source=wantok_ai_agent`, `chat_enabled=false`. It is explicitly labelled QA with no operational assistance required; retained for evidence. Staff response/live human chat and Web handoff remain unverified.
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

## Validation baseline

At this checkpoint:

- all shared Flutter packages: analysis PASS
- Wantok app: analysis + **34 tests PASS** (33 client regressions + configuration smoke)
- required `scripts/flutter/check.ps1`: PASS; Desktop Commander shells on EAGLT02 currently need the standard `PROGRAMFILES(X86)=C:\Program Files (x86)` supplied per process for `flutter test`
- Wantok Operations Admin: analysis + smoke test PASS
- Wantok Technical Control: analysis + smoke test PASS
- database: **27 files / 598 pgTAP tests PASS** (all fixtures roll back), including confidence-aware provider discovery and Wantok AI capability/handoff security coverage
- fresh Android signed-in QA on 2026-10-07 confirms **Client → Services** renders the PNG-rich discovery shell and locked **Home · Services · Track · Wallet · Inbox** navigation without visible overflow; populated CX1F provider search/filter/rating/save/detail is now PASS. Recommendation/Explore PNG live data, broader Account/Track/Wallet evidence and Web evidence remain open
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

CX1 now covers reliability, richer client account/profile features, delegated booking across every implemented service family, Saved/media/recommendations/PNG discovery, provider/service search with ratings and Top Wantoks organic discovery, plus the Wantok AI Agent placeholder/capability/handoff foundation. The navigation remains **Home · Services · Track · Wallet · Inbox**. Next product additions captured in `docs/ROADMAP_FILLERS.md` are **CX1G General Marketplace + logistics fulfilment**, **CX1H organic/sponsored ranking**, and remaining **CX1I model gateway/tool execution/support triage**. Fresh signed-in Android/Web evidence is still required before CX1 closes.

Preserve the local development accounts, roles and data. Do not reset/reseed Supabase or replace working modules/configuration. At resume there are two local auth users/profiles and one local `tech_platform_admin` grant.

T2.4 remains deferred until CX1 passes. CX1 migrations `20261006130000_cx1_client_experience_foundations.sql`, `20261006140000_delegated_booking_foundation.sql`, `20261006141000_taxi_delegated_booking.sql`, `20261006142000_event_delegated_booking.sql`, `20261006143000_commerce_delegated_booking.sql`, `20261006144000_water_delegated_booking.sql`, `20261006145000_client_media_storage.sql`, `20261007015000_client_media_ownership_hardening.sql`, `20261007062000_client_service_recommendations.sql`, `20261007063000_client_recommendation_acl_hardening.sql`, `20261007065000_png_service_place_discovery.sql`, `20261007071000_provider_service_discovery.sql`, and `20261007072000_wantok_ai_agent_foundation.sql` are already applied locally; do not reset/reseed Supabase to replay them. General Marketplace, promotions and real AI gateway integrations follow later.

Do not begin Wantok Pay transaction movement until payment-rail and settlement decisions are made.

## Recovery rule

If a future chat loses context:

1. open this repository;
2. read `AGENTS.md`, `docs/HANDOVER.md`, `docs/ROADMAP.md`, and `docs/ROADMAP_FILLERS.md`;
3. run `git status --short --branch` and `git log -5 --oneline`;
4. preserve a dirty tree until its purpose is understood;
5. continue the roadmap rather than reconstructing architecture from memory.
