# Wantok Services — Roadmap Fillers & Product Additions

**Purpose:** This file captures incremental product ideas, mini-additions and clarifications that Mansfield introduces between major roadmap phases. It supplements, but does **not replace**, `docs/ROADMAP.md`.

Every ChatGPT, Codex, Desktop Commander or other AI coding session must read:
1. `AGENTS.md`
2. `docs/HANDOVER.md`
3. `docs/ROADMAP.md`
4. **this file**
5. the architecture document relevant to the task

## Rules

- Do not rewrite the main roadmap around a filler item without first mapping it into an existing or newly approved phase.
- Preserve completed checkpoints and working modules.
- Prefer additive changes and shared platform primitives.
- When a filler becomes implemented, mark it here and reflect the durable architecture/state in `ROADMAP.md` and `HANDOVER.md`.
- Keep the locked client navigation **Home · Services · Track · Wallet · Inbox** unless Mansfield explicitly approves a redesign.
- Product concepts may be inspired by other platforms, but Wantok Services must retain its own PNG identity, interaction model and branding.

---

## FILLER-2026-10-07-01 — Provider & Service Search + Ratings

**Status:** CX1F CLIENT FOUNDATION IMPLEMENTED; live Android/Web QA remains.

### Product intent

Customers must be able to search for:
- registered and approved service providers;
- approved services offered by those providers;
- providers by service category;
- provider/service name and relevant location/coverage.

Search results should show:
- provider/business name;
- individual/business/organisation type;
- approved service categories;
- service/listing title;
- 1–5 star rating;
- review count;
- verified/approved state;
- relevant location/coverage where available.

### Ranking

Organic discovery should favour:
- stronger rating average;
- sufficient review count/confidence;
- relevant service/category match;
- real service coverage/location;
- availability/activity where applicable;
- recent completed-service quality signals.

Do not rank a new 5.0/1-review provider automatically above an established 4.9/200-review provider purely by average.

Top-rated surfaces may show a rotating/randomised subset from the highest-quality eligible candidates so the same five providers are not permanently fixed.

---

## FILLER-2026-10-07-02 — General Goods Marketplace

**Status:** APPROVED — map to CX1G.

### Product intent

Add a general product marketplace beyond Food/Groceries, conceptually closer to an e-commerce marketplace while remaining Wantok-specific.

Provider/vendor accounts may be:
- individual;
- business;
- organisation.

After provider verification and category approval, vendors can:
- create a store/service listing;
- list approved products;
- set title, description, SKU, price, stock/availability, photos and category;
- advertise services as well as physical products;
- receive orders under the same signed-in Wantok account.

Customer experience:
- browse/search products and stores;
- view vendor ratings/review counts;
- add products to an order/cart;
- select fulfilment;
- rate completed transactions/service experience.

### Approval boundary

Provider verification does not mean every product/category is automatically approved. Category/listing approval remains server-authoritative and auditable.

---

## FILLER-2026-10-07-03 — Marketplace Fulfilment / Logistics Choice

**Status:** APPROVED — map to CX1G.

For general marketplace orders, customers/vendors should support:

1. **Self pickup** — customer collects from vendor.
2. **Vendor drop-off** — vendor performs delivery.
3. **Wantok logistics** — customer/vendor requests an approved Delivery/Courier provider from the platform.

Third-party logistics remains a separate service-provider relationship. The delivery provider does not become owner of the product sale.

Future fulfilment flow should support:
- platform-selected/recommended delivery providers;
- customer-selected delivery provider;
- vendor-selected/requested delivery provider where allowed;
- delivery quote/acceptance where pricing is not fixed;
- pickup/drop-off status hand-off;
- proof of pickup/delivery later;
- service rating after completion.

---

## FILLER-2026-10-07-04 — Organic Ranking & Paid Promotion

**Status:** APPROVED — map to CX1H.

### Organic ranking

Top services/products/providers may be surfaced from:
- rating quality;
- rating/review volume;
- relevance to category/search/location;
- verified active status;
- completion/reliability signals;
- current availability where applicable.

Top-category cards may draw a randomised subset (for example 5) from a qualified top-ranked pool.

### Paid promotion

Wantok Services may later offer paid advertising/boosting for approved providers/listings.

Promotions must:
- be clearly labelled **Sponsored** or **Promoted**;
- have start/end date/time;
- support controlled impression frequency/caps;
- target only approved categories/locations;
- never bypass provider/listing approval;
- not alter stored organic ratings;
- have auditable campaign status and billing references;
- be excluded where policy/regulatory rules require.

Do not silently mix paid ranking into organic rating scores.

---

## FILLER-2026-10-07-05 — Wantok Agent

**Status:** CX1I FOUNDATION IMPLEMENTED; model gateway/tool execution/support triage remain.

### Client role

Expose a visible **Wantok Agent** entry point without adding another permanent bottom-navigation tab. The implemented client UX uses a compact global header action so the Agent remains easy to reach without consuming Home content space.

The Agent should help customers:
- find a service/provider/product;
- explain available Wantok services;
- navigate service categories;
- surface matching providers/listings;
- assist when normal search does not find a result;
- prepare a service request where appropriate;
- explain order/booking status using authorised data.

The Agent should help providers:
- understand provider onboarding;
- choose the right category;
- draft service/product listing text;
- explain missing approval information;
- guide them to provider tools.

### Human hand-off

If the Agent cannot resolve the request, or the user requests a person:
- create/continue a support conversation or support case;
- pass a concise conversation summary;
- preserve the user's consent and authorised context;
- clearly tell the user that a human hand-off is occurring.

### Architecture boundary

Prepare a provider-agnostic AI API contract:
- Wantok Services owns users, bookings, products, permissions and transactions.
- The AI layer receives only authorised/minimised context.
- AI tools/actions must call controlled Wantok APIs; no direct arbitrary database access.
- Model/provider configuration must be replaceable.
- Wantok Neurons may later supply intelligence through APIs, but Wantok Services remains the transaction authority.
- No AI may approve providers, move money, change privileged roles or bypass workflow approvals.

### Initial placeholder

Frontend exposes a tasteful **Wantok Agent** guide with examples such as:
- “Find a plumber in Lae.”
- “Show top-rated vehicle hire near me.”
- “Help me list a product.”
- “I cannot find the service I need.”
- “Talk to a person.”

Actual model-backed chat should remain disabled until the AI gateway, safety/permissions, logging, privacy and human-handoff contract are implemented and tested.

---

## FILLER-2026-10-07-06 — Wantok Ads / Managed Social Advertising

**Status:** APPROVED — map to a separate future **ADS1** module. This is not part of the current CX1 completion gate and is distinct from CX1H in-app Sponsored/Promoted placement.

### Product intent

Add a first-party **Wantok Ads** service operated by Wantok Services. Customers can pay Wantok Services to prepare and manage advertising campaigns for their legitimate products, services, events or businesses across supported social/video advertising platforms such as:
- Facebook and Instagram through official Meta advertising channels;
- TikTok through official TikTok advertising channels;
- YouTube through official Google/YouTube advertising channels;
- additional approved platforms later through the same adapter boundary.

Wantok Ads is **not** an ordinary third-party provider listing. Campaign operations, approvals, billing references, platform integrations and reporting remain controlled by Wantok Services.

### Customer campaign brief

A customer should be able to provide:
- product/service/business being advertised;
- campaign objective such as awareness, traffic, messages, leads or sales where supported;
- target audience/location and optional age/interests where platform policy allows;
- supported platforms and placements;
- campaign start/end dates or duration;
- destination/link/contact action;
- supplied text, images and/or video assets;
- whether Wantok Services must create or edit the advertising creative.

### Creative and service levels

Pricing must be package/configuration driven rather than hard-coded into the client. The commercial model should support different service levels based on creative work and campaign duration, for example:
- **Copy/Text** — advertising copy/caption using customer-supplied product assets;
- **Static Image** — copy plus one or more prepared images/graphics;
- **Short Video** — vertical/social video creative for Reels/Shorts/TikTok-style placements;
- **Produced Video** — higher-effort edited video, narration, motion graphics or multiple versions;
- optional carousel/multi-image, resizing/reformatting, extra revisions and expedited-production add-ons.

Campaign-management duration may use configurable tiers such as short, weekly, fortnightly and monthly campaigns. Exact PGK prices, included revisions, platform limits and deliverables must be controlled in an Operations-managed package catalogue rather than embedded in app code.

### Pricing boundary

Keep the customer charge auditable as separate components:
1. **creative/production fee** — text, image, video and editing work;
2. **campaign-management fee** — setup, targeting, scheduling, optimisation and reporting;
3. **media/ad spend** — money allocated to the external platform advertising account;
4. optional approved add-ons such as extra creatives, revisions, rush work or extended reporting.

External media spend must not be silently treated as Wantok revenue. Platform spend, Wantok service fees, credits/refunds and campaign billing references need separate ledger/reconciliation treatment when payment movement is eventually enabled. Until the Wantok Pay design gate is approved, only quote/invoice/reference foundations may be implemented.

### Enterprise workflow

Campaign lifecycle should support:
- draft brief;
- advertiser identity/product/service eligibility review;
- creative preparation;
- customer approval of final copy/assets;
- compliance/platform-policy review;
- campaign build and platform submission;
- platform review/accepted/rejected state;
- scheduled/live/paused/completed/cancelled state;
- revision/resubmission where allowed;
- close-out performance report and retained audit history.

Operations staff need a controlled workspace for campaign queue, creative approvals, platform status, spend references, customer approvals, incidents and reporting. Customer-facing status should clearly distinguish **Waiting for Wantok**, **Waiting for customer**, **Waiting for platform review**, **Scheduled**, **Live**, **Paused**, **Rejected** and **Completed**.

### Operations Admin authority

The authoritative back-office surface for ADS1 is **Wantok Operations Admin** (`apps/wantok_admin` / `admin.wantokservices.com`). Customer campaign submission happens in the client, but a campaign must not be published, scheduled, resumed or allocated external media spend merely because the customer submitted or paid for it.

Operations Admin should own:
- advertiser/customer and advertised product/service eligibility review;
- package/tier selection, quote construction and approved commercial adjustments;
- creative asset review, revision requests and final internal creative approval;
- customer final-creative approval evidence;
- channel/placement eligibility for Meta/Facebook/Instagram, TikTok, YouTube and later adapters;
- targeting, dates, duration, frequency/budget limits and media-spend ceiling;
- compliance/platform-policy approval or rejection with reason codes;
- campaign submission/schedule/pause/resume/cancel controls after all gates pass;
- platform-review state, external campaign/ad identifiers and rejection/resubmission handling;
- incident notes, customer communication state, evidence attachments and close-out report approval;
- reconciliation of quoted fees, approved spend references and platform-reported spend.

Admin actions must be server-authoritative. The browser must call secured RPC/API/job commands; it must never hold raw platform credentials or publish directly to an advertising network.

Recommended future ADS1 permissions should be granular rather than a single broad admin flag, for example:
- `ads.view`;
- `ads.quote`;
- `ads.creative_review`;
- `ads.compliance_review`;
- `ads.approve`;
- `ads.publish`;
- `ads.pause`;
- `ads.report`.

High-value/risk actions such as first publication, material budget increase, reactivation after policy rejection or spend above a configured threshold should support dual approval / four-eyes control. The approval actor, prior/new values, reason, timestamp and resulting job/platform response must be auditable.

**Wantok Technical Control** (`apps/wantok_tech`) remains separate: it may configure secret references, OAuth/ad-account integrations, adapter health, callbacks/webhooks and technical diagnostics, but it must not grant itself campaign approval or customer-commercial authority merely because it controls an integration.

### Platform integration and security

- Integrate through official advertising APIs/authorised ad-account access where available; never collect customer social-media passwords.
- OAuth/access tokens and advertising-account credentials are secret references only and belong behind the Technical Control/integration boundary.
- Use replaceable platform adapters so Meta, TikTok, Google/YouTube and future networks do not leak provider-specific logic through the product core.
- Preserve customer consent and rights to supplied images/video/music/copy.
- Apply prohibited-product/content, misleading-claim, age-restriction and platform-policy checks before submission.
- A platform rejection must not be represented as a successful placement; reason/status must remain auditable.

### Reporting

Where supported by the platform adapter, report campaign metrics such as:
- campaign spend;
- impressions and reach;
- video views/watch metrics;
- clicks/CTR;
- messages, leads or conversions where authorised and available;
- cost-per-result and remaining budget;
- platform status/rejection reasons.

Metrics from external platforms are reported data, not Wantok-generated performance claims. Store source, retrieval time and campaign/ad identifiers for auditability.

### Architecture boundary

**CX1H** remains advertising **inside Wantok Services** (Sponsored/Promoted discovery). **ADS1 Wantok Ads** is a managed service that publishes campaigns to external social/video advertising networks. The two may later share campaign, creative, approval, billing-reference and reporting primitives, but paid external media spend must remain separate from organic Wantok ranking and from in-app sponsored placement.

Wantok Agent may later help customers prepare a campaign brief or draft copy, but it must not publish ads, spend money or bypass customer/Operations approval autonomously.

---

## FILLER-2026-10-07-07 - Global Platform + International Travel

**Status:** APPROVED product direction. Map to future **GLOB1 Global Market Foundation** and **TRV1 Global Travel & Itinerary** streams. Do not start implementation ahead of the current CX1 completion gate.

### Product scope decision

Wantok Services is **worldwide**, with Papua New Guinea as the launch/home market rather than the platform boundary.

Existing PNG-specific discovery, service names, Kina presentation and local provider strengths remain first-class. New shared architecture must not assume that every customer, provider, address, currency, time zone or service is in PNG.

### Global market foundation

Future shared contracts must support:
- country/subdivision-aware service availability;
- multiple currencies and explicit currency on every money amount;
- IANA time zones and UTC-normalised timestamps;
- locale/language preferences;
- international phone/address structures;
- market-specific payment rails, tax/regulatory rules and provider requirements;
- country-aware discovery rather than hard-coded PNG-only geography.

**Explore PNG** remains appropriate for the PNG launch experience. It should later sit inside a global **Explore** model capable of other countries/destinations.

### International travel

Wantok Services should support a specialised global Travel capability including:
- airplane/flight search and booking;
- accommodation/hotel search and booking;
- buses/coaches/rail/ferries where approved integrations exist;
- airport transfers, local taxi/ride and vehicle hire;
- events/activities/local Wantok services at the destination;
- multi-day itineraries combining multiple booking types;
- trip changes, cancellations/refunds and disruption support later.

Travel uses dedicated travel offers/orders/itineraries rather than forcing airline/hotel inventory into ordinary `service_bookings`.

### Wantok Agent as travel orchestrator

Wantok Agent should be able to handle requests such as:
- "Find me flights from Port Moresby to Singapore next month."
- "Compare the best options for two adults and one child."
- "Build me a five-day itinerary with a hotel and airport transfer."
- "Add a Wantok taxi from the airport and show local services near my hotel."
- "Show me my trip and explain what is confirmed."
- "Find a replacement option if this flight changes."

The Agent may search authorised travel inventory, compare returned offers, explain supplier-provided conditions, build itineraries and prepare a booking basket.

It must **not** invent live fares/availability/visa rules, spend money, ticket, cancel, change or refund travel without the explicit authority and confirmation defined by the workflow.

Before commitment, the user must see and explicitly approve the current revalidated itinerary/offer, travellers, total/currency, material fare/refund/change conditions, Wantok fees and payment method/rail when enabled. Material price/itinerary changes after approval require re-approval.

### Travel data and supplier boundary

Travel integrations should use replaceable server-side adapters for airline direct/NDC, GDS/travel-content, hotel/accommodation and other approved transport suppliers.

Wantok clients call Wantok APIs only. Supplier credentials/secrets remain behind Technical Control. Supplier-specific payloads must be normalised before reaching product UI/business logic.

Store authoritative external references, offer expiry/revalidation state, supplier confirmation/ticketing state and audit correlation IDs. A displayed offer is not a confirmed booking.

### Track / Inbox / Wallet

- **Track** should later show whole-trip lifecycle: itinerary timeline, flights, hotel, transfers, check-in reminders and supplier status.
- **Inbox** should separate travel-system/supplier updates from provider conversations and Help & support.
- **Wallet** must support multi-currency payment intent/accounting before travel purchase is enabled. Supplier funds, taxes/fees, Wantok service fees and refunds remain separately auditable.

### Administrative authority

**Wantok Operations Admin** owns customer/commercial travel intervention such as approved manual booking actions, cancellation/refund cases, service incidents, support and authorised fee/commercial configuration.

**Wantok Technical Control** owns adapter credentials, callbacks/webhooks, provider health and technical diagnostics. Technical integration authority does not imply commercial booking/refund authority.

### Architecture reference

Detailed design: `docs/GLOBAL_TRAVEL_ARCHITECTURE.md`.

---

## FILLER-2026-10-07-08 - Enterprise Home Dashboard + Payment/Travel Discovery

**Status:** APPROVED, implemented and live-verified on signed-in Android as the current client visual baseline. This is a presentation/discovery layer only; it does not activate unapproved payment or travel transaction rails.

### Canonical Home dashboard

The approved Wantok Services Home/dashboard style is the enterprise marketplace layout now implemented in `ClientHome`:

1. restrained Wantok Services header with the conventional profile/avatar position at top-right;
2. **Explore services and goods** hero with prominent search;
3. compact horizontal discovery chips;
4. **Local Providers / Services for everyday life** promotion;
5. **Popular categories**;
6. **Top providers** using real provider/rating data;
7. **Pay your way** payment-method preview;
8. locked bottom navigation **Home · Services · Track · Wallet · Inbox**.

The dashboard must remain service/goods-first. Account/profile, mode switching and Wantok Agent must not crowd the primary discovery area.

### Vanessa promotional asset

The Local Providers promotion uses the approved Vanessa image asset already bundled at:

`apps/wantok_app/assets/images/vanessa_local_provider.jpg`

Keep that asset as the current promotional image unless Mansfield explicitly requests a replacement. The flower treatment remains a visual overlay; do not regenerate or replace the source photo as part of ordinary dashboard work.

### Global discovery entry points

The dashboard may expose **Travel & Flights** and **Hotels** as global discovery/planning entry points before supplier integrations are live.

Until TRV1 supplier adapters and explicit approval/payment workflows exist:
- these entries must be presented as planned/being connected;
- do not show fabricated live fares, availability or booking confirmation;
- Wantok Agent may later orchestrate travel through controlled tools under `docs/GLOBAL_TRAVEL_ARCHITECTURE.md`.

### Payment preview

The approved Home payment strip includes:
- Wantok Pay;
- Visa;
- Mastercard;
- PayPal;
- Google Pay;
- Bank Transfer.

These are product/rail previews only until their respective integrations, compliance, settlement and market decisions are approved. The standard Android layout uses a compact horizontal strip: Wantok Pay, Visa, Mastercard, PayPal and Google Pay are visible in the initial viewport; Bank Transfer remains the next item in the same strip and is reachable by a short horizontal swipe rather than shrinking the brands below a readable size.

Rules:
- Wantok Pay may open the safe Wallet preview;
- inactive rails must clearly say they are planned/not active;
- no card/wallet/bank payment movement is enabled by this UI;
- payment methods remain market-configurable for the future global platform;
- supplier funds, taxes/fees and Wantok fees remain separately auditable when payment movement is eventually enabled.

### Services and Taxi alignment

Services follows the approved enterprise hierarchy:
**hero/search → local-provider promotion → Popular categories → Top providers → Recommended for you → deeper catalogue/discovery**.

Taxi/Ride follows a map-first pickup/destination planning pattern while keeping Wantok-owned dispatch, delegated-beneficiary rules, explicit Request ride authority and history intact.

This visual direction may take interaction inspiration from leading super-app patterns, but Wantok must keep its own branding, data authority, workflows and product architecture.

---

## FILLER-2026-10-08-01 - Existing Food/Groceries Commerce UX Alignment

**Status:** IMPLEMENTED presentation continuation on the existing commerce core. **This does not start CX1G General Marketplace.**

### Scope

The current Food and Groceries/Shops customer journeys are aligned to the approved Wantok enterprise marketplace visual system while preserving the existing commerce transaction authority.

Implemented presentation contract:
- delivery/pickup context is shown before vendor discovery; the actual fulfilment choice remains authoritative at checkout;
- search remains prominent and filters remain lightweight;
- the commerce hero uses the Wantok scenic visual language;
- populated markets show **Featured approved vendors** followed by **Browse all vendors**;
- featured ordering may use existing rating/review signals for presentation only; stored ratings are not rewritten;
- storefront cards may render real backend media from provider-service metadata when supplied;
- product rows may render existing `commerce_catalog_items.image_url`; missing/failed media falls back to Wantok icons;
- existing checkout, fulfilment, delegated-beneficiary, order and cancellation authority is unchanged.

### Mansfield's reversible smoke-data visual QA rule — 2026-10-08

Approved local presentation examples may be shown to reproduce the reference visual theme **only if each sample has a small, visible `s` marker and an unambiguous `SMOKE_20261008_*` identifier**. Keep the entire fixture manifest in `docs/SMOKE_DATA.md` and gate the sample UI behind the compile-time `WANTOK_SMOKE_DATA` flag (default **false**). A sample must not look like a real payment, vendor approval, dispatch, booking or conversation; clicking a sample reveals its full ID and explanatory disclaimer but never makes backend writes. Delete the entire sample layer at project completion using the manifest; do not remove genuine backend records or reset local accounts.

### Truthful inventory rule

Do not fabricate stores, products, stock, discounts, delivery times, ratings or promotions to make the marketplace look populated.

The preserved local QA dataset currently contains **0 active Food/Groceries storefronts and 0 available commerce catalogue items**. Therefore:
- signed-in Android QA verifies the polished empty-market state;
- deterministic widget tests verify the populated-vendor presentation using injected test data only;
- no local production-like vendor/catalogue fixtures were created merely for screenshots.

### CX1G boundary

CX1G remains the future general-products expansion beyond Food/Groceries. This filler does **not** activate:
- a general Marketplace/Products category;
- broader vendor/product schema;
- stock/inventory expansion;
- third-party logistics sale/delivery separation;
- new marketplace payment movement.

Those items remain governed by the existing CX1G roadmap gate.

---

## FILLER-2026-10-09-01 — New-chat continuity: evidence custody and approved user experience

**Status:** Approved continuity constraints. Latest implemented-code checkpoint **`73ea82f`** on `feature/flutter-platform-v1`. See the first section of `docs/HANDOVER.md` and `docs/EVIDENCE_QUARANTINE_ADMISSION.md` before changing code. Do not infer new functionality from a planned roadmap item.

### Preserve the approved Wantok Services experience

- Keep the reference-matched **photographic**, rounded, enterprise-friendly category cards and the **same category picture/label throughout screens**. Do not revert to plain-colour, generic icon-only category cards or generate replacement reference art without explicit instruction.
- Preserve Beauty & Wellness, Health & Medical, Travel & Flights and other expanded categories, while keeping their distinct information-only/provider-readiness restrictions intact.
- All temporary illustrative data must carry a small visible **`s`** and a traceable `SMOKE_20261008_*` fixture ID, remain opt-in and removable by the manifest in `docs/SMOKE_DATA.md`; never seed fake Supabase provider approval, payments or bookings. Do not delete genuine records by matching display names.
- Preserve the working emulator installation and authenticated session; never wipe data or rebuild the backend for a cosmetic change. Avoid disrupting the separate GVE systems.

### Security boundary for the next engineering session

- **Current reality:** isolated real ClamAV scan and encrypted synthetic candidate quarantine pass tests; there is **no operating secure applicant upload**. Draft `WANTOK-EVIDENCE-INTAKE-DRAFT-2026-10` is a version marker only, not informed consent. The evidence bucket remains sealed with no ordinary client Storage permissions.
- The next phase must start with **trusted backend session verification and a one-time, atomic applicant/check/intent claim**, then evaluate protected file custody, encryption-key lifecycle, resource quotas, durable audit/receipt, malware signature freshness, malicious/failure paths, immutable/versioned storage, privacy/retention and separately authorised reviewer access. Do not let a client supply its own `verifyIntent` decision. Do not wire public routes or provider activation until end-to-end controls and tests are independently accepted.
- Preserve the separate **Operations Admin** provider-review authority and Technical Control integration/health authority. There must be no automatic provider approval, payment flow or regulated-provider onboarding due to a clean antivirus verdict.
- Production is untouched. Restrict any configuration/migrations to the specifically authorised **EAGLT02 local** development environment unless the user separately approves another machine/deployment.

### Required resumption and backups

Open `AGENTS.md` → `docs/HANDOVER.md` → `docs/ROADMAP.md` → this filler → `docs/EVIDENCE_QUARANTINE_ADMISSION.md` → `docs/CLAMAV_LOCAL_RUNTIME.md`. Then check Git, EAGLT02 Docker/ClamAV signature freshness and free disk/memory before work. Use additive migrations and mandatory Flutter/database/scanner tests.

Keep both a verified GitHub push to the existing feature branch and an independent local `git bundle`; preserve private, access-restricted PostgreSQL backups for schema changes and **never include private archives, identity data, keys, configuration secrets or local `.wantok` files in Git**. An archive listing check is not a complete restore drill.
