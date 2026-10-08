# Wantok Services — Living Roadmap

**Updated:** 2026-10-08

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

### Navigation decision — LOCKED

Wantok Services keeps its own five-button client navigation:

**Home · Services · Track · Wallet · Inbox**

Do not rename the bottom bar to Grab-style **Discover / Activity / Payment / Messages**. Rich discovery belongs inside **Services**; lifecycle/activity belongs inside **Track**; profile remains outside the bottom bar and opens from Home/Account entry points.

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
