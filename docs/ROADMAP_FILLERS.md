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
