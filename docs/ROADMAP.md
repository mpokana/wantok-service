# Wantok Services — Living Roadmap

**Updated:** 2026-10-07

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

- [ ] searchable discovery for active verified providers registered on Wantok Services
- [ ] searchable discovery for approved active provider services across categories
- [ ] provider/service cards show 1–5 star rating and review count
- [ ] provider detail/storefront surface shows approved categories/services and business/individual identity
- [ ] category/location filters use structured service coverage where available
- [ ] organic top-rated provider/service surfaces use rating quality plus review confidence/relevance rather than raw average alone
- [ ] rotate/randomise a small display set from the qualified top-ranked pool so the same providers are not permanently fixed
- [ ] keep paid placement out of organic rating scores

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

### CX1I — Wantok AI Agent Foundation — PLANNED

- [ ] client placeholder/entry point for **Wantok AI Agent** without adding a sixth bottom-navigation tab
- [ ] provider-agnostic backend AI gateway/API contract with replaceable model/provider configuration
- [ ] controlled tools for service/provider/product search and authorised booking/order/status lookup
- [ ] provider assistance for category selection and drafting service/product listings
- [ ] assist users when normal search cannot find a service and prepare a controlled request where appropriate
- [ ] human hand-off to support conversation/case with user consent and concise conversation summary
- [ ] AI cannot approve providers, move money, grant roles or bypass workflow approvals
- [ ] Wantok Neurons may later provide intelligence only through this API boundary; Wantok Services remains transaction authority

### Later CX1 options

- [ ] optional achievements/rewards after core consumer workflows are stable
- [ ] social follow/follower metrics only after privacy/moderation design is approved

### Remaining CX1 gate evidence

- [x] fresh signed-in Android **Client → Services** shell/navigation visual QA on the existing development session; locked Home / Services / Track / Wallet / Inbox layout renders without visible overflow
- [ ] remaining signed-in Android/Web visual QA using existing development sessions/accounts
- [ ] live read-only journey checks, especially Taxi map/location/history and populated Track/Inbox/account records
- [ ] live QA of Account privacy/linked/saved/trusted/review pages, Services bookmark interaction/recommendations/Explore PNG live data, Track reviews and Wallet preview
- [ ] complete gate evidence review and full checkpoint before T2.4

Acceptance evidence and initial findings: `docs/CX1_CLIENT_EXPERIENCE_GATE.md`.

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

- PNG payment rails/providers
- cards/mobile money/bank integration
- cash boundary
- wallet scope
- provider settlement
- commissions/fees
- refunds/disputes
- reconciliation
- custody/regulatory boundary
- secrets/key management

After those decisions, implement payment adapters behind a common interface and technical permissions.

## Checkpoint discipline

Every meaningful phase ends with:

1. full validation;
2. update `docs/HANDOVER.md`;
3. update this roadmap;
4. Git checkpoint;
5. leave the working tree clean.
