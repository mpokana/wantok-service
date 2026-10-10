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
- Keep the client destinations **Home · Services · Explore · Track · Wallet · Inbox**. **Latest owner-approved 9 October 2026 navigation:** Inbox stays in the top header beside Profile; bottom bar is **Home · Services · Explore · Track · Wallet**. This extends (and supersedes) the earlier four-tab client bottom bar. Preserve Provider registration under Account/Profile; vendor navigation and roles remain unchanged. Further changes require approval.
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

---

## FILLER-2026-10-09-02 — Trusted metadata claim checkpoint (EAGLT02)

**Status: IMPLEMENTED LOCALLY, NO REAL EVIDENCE INTAKE.** Following `4bf2647`, the internal GoTrue verification adapter and one-time SQL claim are added without changes to approved photographic categories, consistent service taxonomy, Flutter layout, emulator session or opt-in `SMOKE_20261008_*` `s` markers.

The GoTrue request validates a Bearer JWT on the server; only the returned GoTrue account ID is sent using an isolated service-role credential to the server-only database claim RPC. The metadata intent is atomically changed from `awaiting_secure_gateway` to `claimed_for_quarantine` once; receipt is in the same PostgreSQL transaction. Claim races, revoked intent, foreign account or changed application/check must fail. Post-claim withdrawal remains possible; however the receipt is **not** tamper-proof evidence custody.

**Tests:** PostgreSQL 34 files/736 pgTAP PASS; admission/scanner 46 tests PASS; real loopback ClamAV 4 PASS. Further gates and architectural risks in `docs/EVIDENCE_AUTH_AND_CUSTODY_DESIGN.md`. No actual authenticated evidence upload, approved privacy consent, FS/DB custody, KMS, hardened decoder, reviewer-release or external deployment. Existing encrypted-quarantine `verifyIntent` test callback is still synthetic and not connected to this adapter.

**Preservation and backups:** do not enable the sealed `staged-provider-evidence` bucket or blend security work with user-facing theme. Keep private ACL-restricted PostgreSQL archives, independent local Git bundle and verified GitHub feature branch, without secrets in Git. Do not change working GVE machines or Wantok Neurons.

---

## FILLER-2026-10-09-03 — ClamAV freshness guard

**Status: Implemented in local, internal synthetic quarantine only.** Before the default ClamAV INSTREAM scan, the code checks actual daemon VERSION metadata for current signatures (48-hour default, 72-hour maximum). Stale, missing, malformed, timeout or non-loopback responses fail closed before bytes are scanned. An injected simulator scanner in isolated tests does not provide this guarantee. Unit tests 57 PASS and real engine tests 5 PASS. Details: `docs/EVIDENCE_SIGNATURE_FRESHNESS.md`.

**Remaining restrictions:** No consent, network uploader, protected ACLs, durable DB/file manifest, KMS, isolation of content decoders, approved reviewer release or retention/restore drills. CX1 signed-in Web QA remains open; T2.4 deferred. Preserve user-facing photographic categories, `s`-marked sample fixtures and sealed evidence bucket.

---

## FILLER-2026-10-09-04 — Offline claim-bound sealed-custody and crash inventory

**Status: Implemented as an internal synthetic-only fixture/test library**, not a production vault. One-file AES-GCM authenticated envelope binds claim, intent, subject, check, application and key version. Exclusive lock/pending/held publication refuses replacement; the read-only inspector identifies incomplete claims after simulated interrupted writes and never automatically retries. Unit suite 71 PASS, real ClamAV suite 6 PASS. See `docs/EVIDENCE_CUSTODY_OFFLINE_RECOVERY.md`.

**Remain blocked:** trusted GoTrue claim-to-storage gateway, durable DB/file transaction, KMS, dedicated ACL-proven storage, document sandbox, approved informed consent, separate reviewer access, legal retention/deletion, off-host audit, real crash/restore testing. Production and sealed Supabase Storage unchanged. CX1 remains in progress and T2.4 follows signed-in Web QA; do not disrupt the image-rich service taxonomy, opt-in `s`-marked smoke data, or sessions.

---

## FILLER-2026-10-09-05 — Claim-bound manifest and protected storage laboratory

**Status: IMPLEMENTED LOCALLY, NO LIVE EVIDENCE.** One-time service-only SQL metadata manifest is bound to an existing one-time applicant claim and stores bounded SHA-256 plaintext/sealed digests, MIME, byte counts and non-secret key version. Its sole state is `pending_independent_reconciliation`. The synthetic WQE2 envelope can produce an unsubmitted metadata proposal after verifying the encrypted object. No actual storage, Auth, upload, reviewer, consent or verification authority is connected. Database 35 files / 767 assertions PASS, scanner/custody 73 tests PASS, real ClamAV 6 PASS.

An empty private NTFS laboratory folder on EAGLT02 is restricted to Mansfield and SYSTEM with inheritance off. The new read-only auditor accepts this and rejects the ordinary repository permissions. This is **not production vault validation** and does not establish independent service-account or power-loss recovery. See `docs/EVIDENCE_CUSTODY_MANIFEST_AND_ACL_LAB.md`. Protected Storage policies stay absent, CX1 signed-in Web QA stays open and T2.4 is deferred. Do not modify Flutter photographic categories or s-marked sample fixtures.

---

## FILLER-2026-10-09-06 — Offline custody consistency and Android emulator preservation

**Status: implemented locally as a read-only synthetic consistency checker.** `custody-reconcile.mjs` compares a WQE2 test envelope against a caller-supplied untrusted metadata snapshot and claim status, marking missing/tampered/mismatched/withdrawn/interrupted states for independent investigation. Even exact matches never release content or grant Storage/reviewer/provider approval. New test coverage: **85 scanner/auth/custody unit tests PASS**, **6 real ClamAV tests PASS**, **35 SQL files / 767 assertions PASS**. No live Auth, database read, uploader, or production custody is enabled; see `docs/EVIDENCE_CUSTODY_RECONCILIATION_DRYRUN.md`.

The existing `Medium_Phone_API_36.1` Android emulator was launched without wipe/reset or app reinstall and then moved from invisible Session 0 to active console Session 1 using an on-demand non-recurring scheduled task; Wantok Services `io.wantok.service/.MainActivity` was confirmed resumed. Docker Desktop initially failed due to a missing `ProgramData` variable in the remote process and was recovered through process-only environment restoration, retaining local Supabase and ClamAV volumes. Preserve working customer UI, photographic categories, signed-in session and `SMOKE_20261008_*` markers. CX1 still requires signed-in Web QA before T2.4; applicant uploads remain disabled.

---

## FILLER-2026-10-09-07 — Customer navigation placement, Vanessa image and green/gold theme

**Status: IMPLEMENTED, FULL FLUTTER/DB TESTS PASS AND UPDATED DEBUG APK INSTALLED ON EAGLT02.** Inbox remains an accessible destination but is moved to a header icon directly beside Profile; the client bottom navigation is **Home · Services · Track · Wallet**, and vendor navigation remains Dashboard/Jobs/Listings/Me with header Inbox. Keep the existing **Account/Profile → Apply for vendor profile** registration entry, role checks and mode switch. Do not introduce a new registration shortcut on Home or Services; any pre-existing vendor workspace entry remains unchanged.

Replace blue primary styling with forest green/dark green and golden yellow in the shared theme; retain category photography, the scenic PNG discovery banner and **Vanessa's original `vanessa_local_provider.jpg`** green/gold `Services for everyday life` card. Remove the redundant horizontal Home category-chip row in favour of the existing Popular Categories grid. Vanessa's promo now leads to provider discovery, while scenic PNG remains broader Services discovery. Preserve the twelve development-only `S`-marked photographic reference previews under Services; do not misrepresent them as advertisements, customer listings, verified providers or financial transactions. No database/storage changes. Follow-up sign-in Web and owner visual QA remain open.

---

## FILLER-2026-10-09-08 — New Explore tab and photographic previews relocated

**Status: OWNER APPROVED, CX1 IMPLEMENTATION IN PROGRESS / TESTING.** Client bottom navigation becomes **Home · Services · Explore · Track · Wallet**, while header Inbox and Profile are retained. Move existing `Explore PNG and beyond` scenic card from beside Vanessa's green/gold provider photo card to the very bottom of Home; it opens the Explore screen, not the general Services catalogue. Preserve Vanessa's exact image, green/yellow provider card and its approved-provider-discovery action, as well as Account/Profile provider registration and vendor navigation. The entire original twelve-screen photographic `Reference screen samples` section is relocated from Services Categories to Explore as a separate gallery, keeping all `S` demo markers and opt-in `WANTOK_SMOKE_DATA` gate. Services remains the working service-category discovery/search page; Explore has a benign service browse route when samples are disabled. **Do not mistake design samples for real ads, bookings, services, inventory or approved providers.** Signed-in mobile and Web QA to follow; no account, payments, approval or production migration change.

---

## FILLER-2026-10-09-09 — HONOR Android phone beta and roadmap reconciliation

**Owner approval:** update living roadmap/fillers and proceed to phone beta. The latest authorised client bottom bar is **Home · Services · Explore · Track · Wallet**; Inbox stays beside Profile, and provider registration remains inside Profile. All earlier Home/Services/Track/Wallet/Inbox and four-item bottom-bar decisions are historical/superseded. Vanessa's original photograph/card, scenic Home Explore footer, category photos and 12 `S`-marked Explore samples remain. CX1 is still **IN PROGRESS**, with signed-in Web CX1F and broader Web acceptance pending before T2.4; CX1G/H, ADS1, GLOB1 and TRV1 remain planned.

**Handset compatibility/security discovery:** the `wantok-android-prior-explore-20261009.apk` local backup is an **old x86_64 emulator** build; it is not a usable HONOR release. Its `10.0.2.2` development API URLs work only in an emulator. The secure next action is to prepare a distinct **ARM64 offline visual beta** (`WANTOK_PHONE_PREVIEW=true`) with *no backend credentials* and explicit design-preview labelling. Reuse the authorised photo assets and opt-in S-marked gallery, not real bookings/accounts, and never expose EAGLT02 Supabase to the public internet. `docs/HONOR_ARM64_PHONE_PREVIEW.md` records build, limits, verification and phone installation procedure.

**Implementation checkpoint:** offline preview bootstrap, photo navigation and safety placeholders are written; focused tests **4/4 PASS** in default and opt-in sample modes; full Flutter **7 analysis targets, 75 client + 3 Admin + 1 Tech PASS** and DB **35 files / 767 PASS**. **ARM64 debug APK build remains BLOCKED** by repeat Windows Gradle-generated folder locks (`cleanMergeDebugAssets`, `mergeDebugNativeLibs`); no verified phone APK exists and no HONOR installation has occurred. Original x86_64 emulator APK separately backed up; do not distribute it as phone-compatible. Next engineering task is to build in an isolated clean output/worktree after diagnosing the file locking, verify embedded ABI/config/signing and retain SHA-256.

**Deferred functional beta:** Requires a dedicated approved reachable HTTPS staging Auth/API, test users, mobile network tests, proper signing/update flow and real handset acceptance. An offline design preview is NOT equivalent to a working signed-in app or full client-journey test. No unapproved payments, approval, ads, real provider evidence uploads or destructive data changes. Always back up tested source locally and to the existing authorised GitHub feature branch.

---

## FILLER-2026-10-09-10 — HONOR offline ARM64 preview packaged and verified

**Status: COMPLETE FOR OFFLINE APK PACKAGING; REAL HANDSET ACCEPTANCE PENDING.** Based on source checkpoint `c983cfb`, a detached EAGLT02 build at `D:\Wantok_ARM64_Build_20261009` resolved Kotlin C:/D: incremental-cache mismatch via worktree-only `kotlin.incremental=false`. Its separated debug application ID `io.wantok.service.offlinepreview` and label `Wantok Preview` prevent overwriting the main customer app. Final APK `D:\Wantok_Project_Backups\WantokServices-HONOR-OfflinePreview-arm64-20261009.apk`, 105209491 bytes, SHA-256 `8C9C135659AABF6010B13E580E69511673B7CDF11524B4897E2C936A150B6BCE` verified with Android `apksigner`, APK badges/ARM64 engine ZIP inspection; no Android Internet or location permissions. Explicit OFFLINE PREVIEW gate means no sign-in, real catalogue transactions, payments, provider approvals or Supabase backend even though source shares Flutter modules. Vanessa and all photographic samples preserved; samples remain labelled `S`. **No HONOR physical-device installation or acceptance is claimed.** Do not distribute debug build as production. The earlier FILLER-2026-10-09-09 APK build BLOCKED entry is historical and superseded.

**Next:** user-side HONOR USB/local install and visual QA; independently authorised HTTPS staging API/Auth and mobile signing policy for a truly functional Android beta; complete CX1 signed-in Web acceptance before T2.4. The original emulator and local database remain untouched.

---

## FILLER-2026-10-09-11 — HONOR physical-device screenshot review

**Status: INITIAL VISUAL QA PASS; FINAL RESPONSIVE ACCEPTANCE OPEN.** The owner installed the isolated offline `Wantok Preview` build on their HONOR phone and supplied six screenshots in chat. Home, Services, scrolled Explore design-sample gallery, Track, Wallet and `Service Listing (Food)` sample detail visibly render with green/gold brand, Vanessa photo, approved category imagery, five bottom client destinations, sample `S` markers and explicit no-account/no-bookings/no-money-movement warnings. This **closes real-device APK installation/launch/display**, superseding the FILLER-2026-10-09-10 statement that no physical installation was observed. It is still a debug-signed OFFLINE preview only: no Supabase Auth, real provider bookings, uploads, staff approval, marketplace purchases or payment functionality. Screenshots are only present in the user conversation, not committed to GitHub (avoid phone status bar identifiers).

**Owner-approval visual follow-ups:** the 3-column narrow-phone service-category grid visibly truncates `Home Services` and `Water Transport`; five nav labels fit but are crowded; check long Food Listing sample/detail against Android bottom-system-nav SafeArea / scroll padding. Suggested (not implemented): 2-column narrow-mobile categories, responsive tab typography, and detail scrolling inset review. Confirm full Home scroll to `Explore PNG and beyond` footer and remaining S-marked samples on device before final visual acceptance. No changes to Vanessa/photo asset, provider registration under Profile, icon order, emulator sign-in or production security are approved by these screenshots. Finish signed-in Web CX1 acceptance separately; T2.4 remains deferred.

---

## FILLER-2026-10-09-12 — Pinch-adaptive grids and top Profile menu

**Status: owner-approved CX1 refinement; engineering implemented, final checkpoint pending.** User wants a **dynamic 2/3-column experience on every applicable photo/icon/category grid across pages**. Two-finger pinch in selects compact 3-across, spread out selects larger 2-across; usable width and Android accessibility text scaling choose the default. Share density across Home/Services/Explore preview grids in a single app session; preserve one-finger scroll, tappable icons, list/form/detail layouts and original photographic imagery. This is adaptive grid density, **not** arbitrary zoom of the entire interface or fonts.

**Profile icon header dropdown** beside Inbox: `My Settings` opens existing Account/Profile and its security/preferences, `Wallet` opens the existing non-transactional Wantok Pay preview, and `Vendor` routes unapproved accounts to the current provider application or approved provider/driver role-holders into the existing vendor workspace. No bypass of server approval. The isolated offline HONOR preview must show an accurate non-live vendor/settings explanation and the Wallet mock-up, without Supabase backend, credentials or cash movements.

**Vendor panel scope:** an approved user can view the existing provider profile/verification state and existing Jobs/Listings/Food/Groceries capabilities. Planned features must remain clearly disabled until engineering/security/approval milestones: general products/storefront/sales = CX1G; in-app paid promotion = CX1H; managed external Wantok Ads = ADS1; earnings/settlements and real Wallet transfers remain separately gated. An informational card is not a completed checkout, advertiser, settlement or approval service. No database, approval or payment permissions added by this UI increment. Source validation **PASS**: 7 Flutter analyses, 79 client + 3 Admin + 1 Tech widget tests, 35 SQL files/767 pgTAP assertions. Next: build and inspect isolated ARM64 preview, independent backups and GitHub checkpoint, then owner HONOR visual/pinch/menu acceptance; signed-in Web CX1 remains open.

---

## FILLER-2026-10-09-13 — Verified updated pinch/profile HONOR offline APK

**Status: SOURCE AND OFFLINE ARM64 PACKAGING COMPLETE; HANDSET RETEST PENDING.** Source commit `340f1fa` implements two-finger adaptive 2/3-column photo/icon grids and Profile's **My Settings / Wallet / Vendor** dropdown with server-authoritative vendor-role distinction. Vendor application/status remains for unapproved accounts; authorised vendor dashboard uses existing jobs/listings, while advertising, general goods sales, settlements and payment movement stay explicitly future/disabled. Seven Flutter analyses, 79 client + 3 Admin + 1 Tech tests, and 35 SQL files / 767 assertions PASS. GitHub feature branch and independent Git bundle verified.

A new side-by-side, network-disabled, debug-signed HONOR visual preview was built from detached clean-source worktree `D:\Wantok_ARM64_Build_20261009_v2`, with **worktree-only** Kotlin/Android debug manifest customisations. Package `io.wantok.service.offlinepreview`, APK `D:\Wantok_Project_Backups\WantokServices-HONOR-OfflinePreview-PinchProfile-arm64-20261009.apk`, 105218839 bytes, SHA-256 `F1CCFFA22C7F8DE03BD26918DAC189C87AD8D5C58D6709A8D27CA328BB4E2A6B`. Sidecar checksum and build-only patch archived; signature verified, ARM64 Flutter engine present, no manifest Internet/location permissions, no local emulator backend URL in targeted compiled-Dart scan. Previous APK preserved. **No new actual HONOR installation or visual QA performed yet.** Next: user installs latest preview and tests both pinch directions and popup at real phone font/display scaling; safe-area and full Home/Explore scroll still need acceptance. The functional backend app requires separately authorised HTTPS staging and proper release signing. Do not represent this preview as a vendor account, sales or payment system.

---

## FILLER-2026-10-09-13 — Shared grids/Profile menu verified and HONOR beta rebuilt

**Status: IMPLEMENTED + UNIT/REGRESSION PASS; HONOR OWNER ACCEPTANCE PENDING.** Flutter source commit `340f1fa` introduces shared adaptive photo/category grids with 2/3-column width/text scaling defaults and two-finger pinch in/out density choice that persists across applicable client-session pages, including Home/Services/Explore/sample grids; no forced columns for lists/forms/details. Menu beside Inbox: `My Settings` → existing Account; `Wallet` → existing non-transactional preview; `Vendor` → existing approved role-gated dashboard or unapproved application flow. Approved dashboard has provider verification/status, existing jobs/listings/food-commerce access and clearly disabled/planned general goods (CX1G), sponsored advertising (CX1H), external advertising (ADS1) and payouts. No new backend privileges, advertising, payments or Supabase schema changes.

**Validation:** 7 Flutter analyses, 79 client + 3 Operations Admin + 1 Technical Control tests PASS, PostgreSQL 35 files/767 pgTAP assertions PASS, opt-in sample-mode preview/grid tests PASS. Isolated EAGLT02 detached worktree `D:\Wantok_ARM64_Build_20261009_v2` built a safe offline Android ARM64 package from `340f1fa` with the verified Kotlin/manifest debug-only patch. New `D:\Wantok_Project_Backups\WantokServices-HONOR-PinchProfile-OfflinePreview-arm64-20261009.apk`, 105218839 bytes, SHA256 `F1CCFFA22C7F8DE03BD26918DAC189C87AD8D5C58D6709A8D27CA328BB4E2A6B`; certificate matches original offline phone preview, app ID `io.wantok.service.offlinepreview`, no Internet/location permissions, backend not configured. New checksum/patch copies saved with the APK. **Not yet installed on HONOR; do not claim new version tested on phone.** Source and GitHub/local bundle final checkpoint must be verified, and owner must check pinching/menu at device text scale.

---

## FILLER-2026-10-09-14 — Full emulator interface on HONOR with read-only demonstration data

**Owner-approved change:** the previous offline HONOR APK was too simplified and omitted content visible in the signed-in EAGLT02 emulator. New offline visual build MUST reuse full emulator Home, Services, Explore, Track, Wallet and Inbox Flutter widgets, preserve all Vanessa/scenic/category imagery, photo reference details, green-and-gold design, Inbox/Profile header with My Settings/Wallet/Vendor dropdown, and shared 2↔3-column pinch. Sample catalogue derives 17 categories from canonical ReferenceServiceCategories with SMOKE_20261008-prefix IDs and no Supabase inserts. Data hooks and UI safeguards are opt-in-only. Category/provider/saved tap journeys open S-marked photo sample details rather than real transactions. Track and Inbox use injected empty read-only loaders; Vendor offers labelled sample applicant and illustrative approved-vendor dashboard without role or payment grants. Preserve no backend, no Internet/location permissions, original emulator and normal app flows.

**Current stage:** six new focused owner-review widget tests pass in default and opt-in smoke mode; full Flutter/database regression and isolated ARM64 APK signature/hash verification are mandatory before final delivery. The demo is a layout comparison, NOT real provider approval, booking, wallet/payment or connected account functionality. Signed-in Web CX1 and a later HTTPS staging/mobile release remain separate gates. See docs/HONOR_FULL_INTERFACE_DEMO.md.

---

## FILLER-2026-10-09-15 — Verified full emulator-screen HONOR offline APK

**Source complete and archived:** main app Home, Services, Explore, Track, Wallet and Inbox widgets now display offline in HONOR preview with canonical photo assets and in-memory 17-category, S-marked provider/sample fixtures, zero fabricated reviews and no real credentials. Six owner comparison widget tests PASS both demo flag modes; full Flutter 7 analysis targets, 81 client + 3 Admin + 1 Technical tests PASS; SQL 35 files / 767 assertions PASS. Source commit `a6b164a` from `feature/flutter-platform-v1` built in detached `D:\Wantok_ARM64_FullInterface_20261009`, with build-only Kotlin/Android debug patch kept OUT of production.

**Final APK:** `D:\Wantok_Project_Backups\WantokServices-HONOR-FullEmulatorInterface-OfflineDemo-arm64-20261009.apk`, 105229563 bytes, SHA-256 `755F08A5A5B8B6F052D348A682E85671936225FF01F59CCD77BC5AFE228920AB`, separate app ID `io.wantok.service.offlinepreview`, verified ARM64 Flutter engine and debug signature, no manifest Internet/location permissions or local emulator API literals in checked compiled snapshot. Sidecar SHA and the exact isolated Gradle patch archived beside it; previous tested phone preview retained. **Physical HONOR testing of this updated build remains PENDING**, with no sign-in, real providers, bookings, funds, ad creation or role grants. Owner to compare real layouts and pinch to emulator, report refinements, then decide on separate authorised HTTPS staging for connected beta. See docs/HONOR_FULL_INTERFACE_DEMO.md.

---

## FILLER-2026-10-09-16 — EAGLT02 reconnected; real Chrome Web guest QA, signed-in CX1 pending

**State:** clean Git checkpoint `67cad66` on existing `feature/flutter-platform-v1` at session start. On authorised EAGLT02, local Supabase is running and the full real Flutter Web client is available at **http://127.0.0.1:18108/** through a detached read-only source worktree `D:\Wantok_CX1_Web_QA_20261009`, preserving the original emulator/session and avoiding the main working copy's generated-asset file locks. Isolated Chrome **guest** captures at 320/390/1280 px show the approved Wantok Services sign-in card, tagline, Vanessa background, email/password inputs, Sign in and Create account links with no visible clipping. Captures and the temporary Chrome automation script are local in ignored `.wantok/`, **not GitHub**. The local browser origin is loopback; these screenshots are NOT proof of authenticated provider, Wallet, Agent, Inbox or Vendor functionality.

**Validation:** seven Flutter analysis targets clean; 81 client + 3 Operations Admin + 1 Technical Control tests PASS; 35 SQL files / 767 PostgreSQL assertions PASS; no application, schema, account, provider, funds or approval changes. An independent **headed Chrome QA profile** is now open to the Web sign-in page for owner to authenticate manually. Do **not** scrape password, Chrome profile, cookies or session tokens; user must authenticate via their own login. Next after sign-in: read-only CX1F provider `plumber` search, Specialist Services → Morobe → Lae, sourced ratings/details and Saved state, Account/Inbox/Track/Wallet/Agent and responsive authenticated Web QA. Write exact PASS/FAIL/BLOCKED evidence; don't send new messages, reviews, bookings or mutate Saved without approval. T2.4 remains gated.

**Security observation:** local Supabase Docker reports some host-published dev ports bound to `0.0.0.0`; remote reachability was NOT tested, so do not infer exposure. A firewall/loopback binding review is appropriate with owner approval but no network changes were made. Preserve all original data, offline HONOR APKs and separate Wantok Services/GVE systems.

---

## FILLER-2026-10-10-01 — Enterprise catalogue + Operations dashboard source validated, emulator resumed

Owner explicitly authorised implementing desktop Web, Operations backend/dashboard, tablet and mobile designs based on the six supplied visual references (no image generation). Preserve green/gold palette, original PNG photo assets including **Venenssa** (existing asset filename remains `vanessa_local_provider.jpg`), real service catalogue/RLS and 5 client tabs with header Inbox/Profile. On EAGLT02, starting clean `a59e493`, implemented `enterprise_services_catalogue.dart` and `services_hub_page.dart` integration at width >=700 px; new service photo-grid/hero/search/filter/provider discovery for tablet/desktop, while mobile <700 retains original adaptive 2/3-finger-pinch gallery. Added `operations_overview_page.dart` and `operations_sidebar.dart` to existing role-protected AdminShell; desktop sidebar, tablet rail, narrow drawer, read-only provider application/listing/booking/audit queries, and deliberately unavailable regional/payment sections. **No invented provider/booking/transaction records, data mutations, privilege grants, payment rails or schema migrations.** Snapshot metrics have backend query limits and should not be described as unrestricted enterprise totals.

Focused widget tests cover Services at 840/1440 px and search/filter navigation, Operations at 390/900/1440 px and existing admin section links. Fixed actual tablet banner 4px overflow and its 150%-text-scale accessibility failure by scaling hero height. Full `scripts/flutter/check.ps1` PASS: seven analysis targets, 84 client + 7 Admin + 1 Tech tests; `npm run db:test` PASS: 35 SQL / 767 assertions. Original emulator `Medium_Phone_API_36.1` started in active user session 2 on EAGLT02 using existing `Wantok_Emulator_Interactive` task, booted with ADB `emulator-5554`; no wipe. Existing installed client returned to launcher, and attempt to rebuild from MAIN checkout met a Windows Gradle asset-file lock; do not clean/reset production/data/AVD. **Next:** validated source/docs commit + local Git bundle/GitHub; refresh emulator via isolated detached worktree and verify existing login, then continue signed-in Web CX1 and pixel-level visual refinement. CX1 remains IN PROGRESS; T2.4, ads, goods sales, evidence uploads and money features remain gated.

---

## FILLER-2026-10-10-02 — Desktop Home layout and navigation correction

User supplied signed-in Chrome screenshots of local Client :3000, Technical Control :3100 and Operations Admin :3200 and confirmed ability to log into all three. Client desktop Home was stretching a three-column touch-focused photo catalogue to giant wide bars and retained a full-width bottom phone tab bar. Added centred desktop max 1480 px content, the original bundled **Venenssa** hero before categories on desktop, photograph-first responsive category cards with maximum 205 px widths from tablet upward, and top-header navigation at >=1120 px with mobile bottom nav preserved below. No changes to Technical Control or Operations Admin or business/data/auth. Source tests **PASS**: 7 Flutter clean analyses, **88 client + 7 Operations Admin + 1 Technical** widget tests, and **35 SQL files / 767 pgTAP assertions**. New widget tests prove 390 px touch grid, 900 px tablet, 1600 px desktop compact cards and 1500 px desktop header. Next commit/push/bundle and restart only Client local :3000, verify signed-in owner visual acceptance. Keep pre-existing unrelated `supabase/snippets/` untouched and out of Git. CX1 still open.
