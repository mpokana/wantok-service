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

## FILLER-2026-10-12-13 — E6R role metadata public boundary and G8 decision pack

**P0:** read-only pg_catalog confirms eight selected role helpers locally executable by anon/auth/service; source lexical map covers 77 migrations, 242 historical callsite refs, 19 variable-ID patterns, one named Dart RPC (not 242 live vulnerabilities). New `064` synthetic tests **18/18** reproduce other-subject role/Technical entitlement queries from anonymous SQL, without role assignment. First test expectation fixed for automatic customer base role. No migration or live account/security changes. Disconnected SQL now **286/286** across 14 files, shared DB untouched. G8 D1–D5 independent policy/compatibility/reviewer decision plan prepared; G7 **28 planned / 0 witnessed**, formal G1–G10 **0/10**. CX1 queued, T2.4 paused. See `docs/E6R_ROLE_METADATA_CALLGRAPH_AND_G8_DECISION_PACK_20261012.md`.

## FILLER-2026-10-12-12 — E6Q role-helper subject vs caller trust

**P0:** New synthetic `063` pgTAP **25/25 PASS** uses separate rollback-only Operations, Technical and ordinary fake identities. Verified distinct role-family grants and refused cross-family privilege changes. Discovered potential staff-role metadata visibility: ordinary `authenticated` SQL actor can query `is_admin`, `is_technical_platform_admin` and `can_access_technical_console` on another test account via supplied user ID. This **is not impersonation** but requires independent G8 privacy decision and real G7 RPC verification. Disconnected seven-migration compatibility stage **268/268 PASS**, source DB unchanged. G7 matrix now 26 planned / zero witnessed. All G1–G10 BLOCKED; CX1 queued, T2.4 paused. `docs/E6Q_ROLE_HELPER_CROSS_PRINCIPAL_BOUNDARY_20261012.md`.

## FILLER-2026-10-12-11 — E6P role and publishing denial tests, parallel G7 witness workboard

**P0 E-Series:** nine selected privileged mutating SQL routines for role changes, Technical module state, branding and category editing contain source `auth.uid()`/admin guards; new synthetic pgTAP `062` tests **23/23** denial/side-effect invariants without real user logins. Cross-stream seven source-only pending migrations run in network-disabled disposable PostgreSQL with **243/243** pgTAP assertions, rollback and shared DB unchanged. **No E6P schema or Technical source changes.** Parallel independent G7 matrix now has **23 NOT EXECUTED/BLOCKED** cases, adding ordinary signed-in role escalation and authorised positive paths. G1–G10 0/10 independently approved. E6O shared ACL exposure persists until authorised independent stage. CX1 queued, T2.4 paused. `docs/E6P_ROLE_ADMIN_CONTROL_NEGATIVES_AND_G7_WITNESS_PLAN_20261012.md`.

## FILLER-2026-10-12-10 — E6O expanded public trust boundary and G8 finding

**P0 security:** full read-only `public` SEC DEFINER catalogue found 152 functions (95 anon EXE, 133 authenticated EXE) rather than only 19 selected E6 routines. Identified untrusted grant disparity on privileged shared `write_audit_event` and `enqueue_notification`; unapplied E6O source migration proposes revoking both from anon/auth while leaving service-role and nested definer paths intact. Disconnected 7-migration E6H/T2.4/E6N/E6O stage **220/220 PASS** across 11 synthetic pgTAP suites with explicit denied-call cases and untouched shared Supabase. Separate Technical internal health-report function flagged for G8/T2.4 owner review, **not modified**. Human G1–G10 0/10, G7 cases unexecuted, CX1 queued, Technical paused, production restricted. `docs/E6O_FULL_PUBLIC_DEFINER_SURFACE_AND_INTERNAL_RPC_GUARD_20261012.md`.

## FILLER-2026-10-12-09 — E6N definer pg_temp last path with independent G gates

**P0 source-only hardening** migration `20261012140000` applies 19 selected `ALTER FUNCTION ... SET search_path=public,auth,pg_temp` in transaction only when separately authorised; it is not applied to persistent DB. Disconnected test harness ran **206/206** across 10 pgTAP files after six prospective E6H/T2.4/E6N migrations; 19-function source-body/owner/grant fingerprint unchanged and temporary DB removed. Test-stage `--no-acl` restoration initially missed two ACL restrictions and was corrected *only* in disposable stage; not a real privilege escalation. Parallel G1–G10 register/evidence/reviewer matrix continues; **all formal gates BLOCKED**. CX1 queued, T2.4 paused. `docs/E6N_SEARCH_PATH_HARDENING_AND_GATE_READINESS_20261012.md`.

## FILLER-2026-10-12-08 — E6M source-only definer check + gate evidence register

**Allowed safe advancement:** static checked-in SQL review, no DB access: 19 selected E6 latest SECURITY DEFINER function definitions scanned for explicit search_path, simple unqualified relation refs, dynamic EXECUTE, and pending-version divergence. Positive source baseline; manual call-graph and explicit pg_temp ordering remain **REVIEW OPEN**. New G1–G10 workboard requires distinct reviewers, independent evidence slots and 18 separately witnessed GoTrue/PostgREST cases. **0/10 gates approved; all BLOCKED**. Docs: `docs/E6M_FUNCTION_SOURCE_REVIEW_20261012.md` and `docs/E6G_PARALLEL_ACCEPTANCE_REGISTER_20261012.md`. No shared DB or T2.4 writes.

## FILLER-2026-10-12-07 — E6L trust boundary and G1–G10 concurrent gate preparation

**Priority:** E-series P0 with G1–G10 readiness prepared in parallel, serial shared writing, CX1 queued, T2.4 paused. **Technical baseline:** 19 selected SECURITY DEFINER functions owned by local postgres/BYPASSRLS; 0 anon EXECUTE; 0 of seven trusted-only routines signed-in EXECUTE; caller schema CREATE absent; database TEMP allowed and explicit trailing pg_temp missing, merits function-body review. A metadata-only source script and G1–G10 independent evidence/GoTrue testing plan were added. **All gates BLOCKED** pending authorised real staff/legal/ISO/COI/security/DR testimony; no accounts, migrations, service-role changes, shared DB or production modifications. `docs/E6L_PRIVILEGED_FUNCTION_OWNERSHIP_AND_GATES_20261012.md`.

## FILLER-2026-10-12-06 — E6K public marketplace disclosure review

**Status:** Source/isolated security baseline only; 17/17 synthetic pgTAP RLS checks (new test 058), **181/181 total E6H+T2.4 disposable integration**, shared database unchanged. PostgreSQL catalogue confirms anon can SELECT all **18 profile** and **23 service** columns for otherwise public eligible provider records, including metadata and address/coordinates. Current public-row filters are active+verified; this is a field-disclosure/privacy decision, not proof of actual customer-data leakage. **BLOCKED:** independent metadata/public-field sign-off, safe API projection, multi-platform query migration, exact ACL/GoTrue testing. No live permissions, roles or T2.4 functions changed. `docs/E6K_PUBLIC_MARKETPLACE_RLS_AND_PRIVACY_BOUNDARY_20261012.md`.

## FILLER-2026-10-12-05 — E6J local trust catalogue and five-migration integration

**Status:** Read-only E6J catalogue scanned 19 selected `SECURITY DEFINER` functions, 20 selected Operations tables and all five pending migration version IDs. Existing anonymous SELECT on public marketplace `provider_profiles`/`provider_services` and definer `pg_temp` search-path ordering are **review items, not confirmed exploits**. Disposable PostgreSQL with E6H + four T2.4 SQL migrations passed **164/164 pgTAP assertions** across eight suites; all test data rolled back and shared DB unchanged. Independent exact owner/ACL/policy and GoTrue witness remain pending; E6-G1–G10 blocked. See `docs/E6J_TRUST_CATALOG_AND_CROSSSTREAM_QA_20261012.md`.

## FILLER-2026-10-12-04 — Owner single-chat execution order (SUPERSEDES PARALLEL PRIORITIES)

**Decision:** This ChatGPT conversation coordinates **P0 E-series / E6 engineering and formal acceptance blockers → P1 CX1 signed-in Web/mobile client evidence → P2 T2.4 Technical Control**, in this order. T2.4 A–E source and earlier tests preserved; **new T2.4 engineering paused** until P0/P1 milestones. No automatic E6 human sign-offs, production or live schema migrations. One writer at a time for shared docs, permissions, UI and Git. See `docs/PROGRAM_EXECUTION_PLAN_20261012.md`.

**Next E-series work:** read-only security function owner/ACL/RLS inventory, E6H plus all four T2.4 migrations in disposable staging, signed-in role matrix preparation. **CX1 next:** actual authenticated Web category-first provider journey, Refresh route clicks, photo/editor, HONOR/device and owner gate acceptance. T2.4 later: actual log source/worker provenance, retention, safe monitoring and separately approved job policies.

## FILLER-2026-10-12-03 — T2.4E central log-source readiness

**Status:** Registered **source-contract readiness only**; trustworthy `not_connected` state, provenance ticket format, 1–90-day retention bounds, and server-enforced module.view+module.logs for reduced metadata. Technical Logs UI distinctly displays no central collector. Four migrations and pgTAP 090–093 **58/58 PASS** in disposable staging, shared DB untouched. No actual central log source or worker-heartbeat connected, no job actions or VM deployment. `docs/T24_CENTRAL_LOG_SOURCE_READINESS_20261012.md`.

## FILLER-2026-10-12-01 — T2.4 privacy-scoped Technical Activity feed

**Status:** Source tested; module activity now reads only four allowlisted Technical Control change actions from real audit_events via a new module.view + module.logs RPC, hard server cap 30, and returns no person/target/meta/request fields. Typed Technical Activity page and six new widget tests PASS. Isolated staging runner now applies 3 T2.4 migrations; **39/39 pgTAP** PASS, original database unchanged, disposable container removed. Seven Flutter analyses, 132 Client / 43 Operations / 34 Technical tests PASS. Full shared SQL runner blocked by unapplied E6H/T2.4; production parity and browser acceptance open. No central logs, execution controls, live worker claims or VM deployment. `docs/T24_SCOPED_TECHNICAL_ACTIVITY_20261012.md`.

## FILLER-2026-10-12-02 — E6I disposable E6H + T2.4 migration QA

**Status:** Source-only E6I runner clones a non-personal schema/reference-only PostgreSQL stage, applies pending E6H and all three T2.4 migrations to that disposable database and passes **145/145 pgTAP assertions** across seven rollback-only case/security/observability suites. No shared DB migration, user records, external VM or activation; replica test ACLs do not establish production parity. `docs/E6I_ISOLATED_CROSSSTREAM_INTEGRATION_20261012.md`; E6 G1–G10 human gates OPEN.

## FILLER-2026-10-11-24 — T2.4 isolated staging automation

**Status:** Repeatable local `scripts/qa/t24-isolated-staging.ps1` PASS: disposable network-disabled PostgreSQL, schema-only plus non-personal technical references, T2.4 Log and Messaging migrations applied together in separate staging, **12 + 13 pgTAP assertions PASS**, sample data rolled back, original DB unchanged and test container removed. Seven Flutter analyses and 132 Client / 43 Operations / 28 Technical widgets PASS. Shared default full SQL suite remains blocked at 090/091 pending unapplied T2.4 schema; no production grant/owner parity, GoTrue/browser acceptance, online VM, worker liveness or executable jobs. `docs/T24_ISOLATED_STAGING_INTEGRATION_20261011.md`.

## FILLER-2026-10-11-23 — E6H case and clearance independent read scope

**Status:** Added unapplied additive E6H migration denying a provider acting as their own enterprise case reviewer/evidence/safety officer, and denying prior clearance identity/final reviewers access via later investigator role. Rollback-only 051/052/056/057 SQL tests **106/106 PASS**; all DDL/fixture effects rolled back, EAGLT02 only. E6 formal sign-off still blocked; combined migrations must be coordinated with T2.4 before applying E6H. `docs/E6H_ENTERPRISE_CASE_INDEPENDENCE_20261011.md`.

## FILLER-2026-10-11-21 — T2.4 scoped health log adapter

**Status:** Committed/pushed `0ba95ef`, local SQL 12/12 negative tests PASS in rollback-only transaction; seven Flutter analyses and 132 Client / 38 Operations / 22 Technical widgets PASS. New module-scoped backend log RPC requires module.view AND module.logs, sanitises text and caps 30 records. Running Technical preview unchanged; no database migration applied, no raw central logs or queue controls. Existing broader view-authorised Health history API remains a separate hardening task. Linux source release and local Git bundle verified; combined E6D/T2.4 seven Flutter analyses and 132 Client / 43 Operations / 22 Technical tests PASS on `0ad0fde`. `docs/T24_SCOPED_HEALTH_LOG_ADAPTER_20261011.md`.

## FILLER-2026-10-11-20 — E6D–F two-person grants and staged case recusals

**Status:** Local E6 security engineering code implemented and regression tested, formal live E6 acceptance OPEN. Country-scoped signed-in requester and independent approver duty changes are audited, time-bound, denied to targets and unaffected by global administrator flags. Staged applications are registered against independent ISO subdivision/category mapping (no free-text guesses); review/evidence duty separation and applicant owner RLS are enforced. Staff case-specific recusals immediately invalidate enterprise/staged case authority. Legacy resource activation decision sealed and direct sensitive column grants tested. Local 56 SQL/1,139 assertions, Node evidence 101/101, five new Operations duty widget tests passed; detached integrated QA seven analyses / 132 Client / 43 Operations / 22 Technical widgets PASS. `docs/E6DEF_INTEGRATED_SECURITY_ACCEPTANCE_20261011.md`. No real staff proof, signed-in browser witness, VM deployment, KYC, uploads, vendor activation or payment allowed. `docs/E6D_E6F_DUAL_STAFF_STAGED_CASE_RECUSAL_20261011.md`.

## FILLER-2026-10-11-19 — T2.4 owner-authorised read-only Technical observability

**Status:** T2.4 started (partial), not production/phase complete. Existing Technical capability cards now open module-scoped read-only diagnostics, limited health transition logs and a truthful disconnected-queue state with no actions. Six tests and isolated full Flutter regression PASS; local SQL 52/1,043 PASS. No SQL migration, raw logs, arbitrary probes, job execution, Web/Android upgrade or VM deployment. Remaining real log/queue adapters, secure technical audits and approved job commands are explicit future gates. Owner CX1 manual acceptance is documented separately from objective release evidence. `docs/T24_READONLY_OBSERVABILITY_FOUNDATION_20261011.md`.

## FILLER-2026-10-11-18 — E6C1 case-scoped safety and clearance controls

**Status:** E6C1 locally coded and tested; E6 programme OPEN. Safety investigators need current region/category grants and evidence-case ownership binding; global admins and conflicted officers are denied. Audited service-role-only emergency stop remains for unmatched historic providers; legacy activation and old provider approve/reject RPCs are blocked. Isolated Operations safety tab added. Database 52 files/1,043 assertions PASS; Operations analysis and 38 widget tests PASS. Production release, broad legacy route auditing, real staff provisioning and signed-in acceptance remain OPEN. See `docs/E6C_SCOPED_CLEARANCE_SAFETY_20261011.md`.

## FILLER-2026-10-11-17 — E6C safety clearance boundary review

**Status:** Source audit complete, implementation NOT performed. Legacy clearance monitoring/revocation, revocation audit, provider status and old provider reviews still use global administrator privileges. A country/province/category safety duty plus verified provider-to-evidence-case binding and trusted server-only emergency stop is required; E9 activation remains disabled. Remote tool security checks blocked migration creation; do not declare regression pass, release or E6 completion. See `docs/E6C_CLEARANCE_SECURITY_REVIEW_20261011.md`.

## FILLER-2026-10-11-16 — CX1 defer category photo upload until Save

**Status:** Technical Control UI patch/source QA PASS, live Web acceptance OPEN. Image selection now previews in the dialog and stays client-side until confirmed **Save category**. Cancel does not upload or edit; the existing storage/RPC permission checks still govern saves. Four synthetic photo tests PASS and full isolated Flutter regression PASS, including merged E6B compatibility (132 Client / 37 Operations / 16 Technical widget tests). Basic JPG/PNG/WebP signature and 3 MiB size checks do not constitute security scanning or licensing approval. A category SQL save failing after successful storage upload can still leave unused media; server-side recovery requires separate design. All six newly seeded categories remain inactive. No real image upload, publication, Web/Android deployment or VM access. `docs/CX1_CATEGORY_PHOTO_STAGING_20261011.md`.

## FILLER-2026-10-11-15 — E6B scoped case and evidence duties

**Status:** Partial E6 security checkpoint only. Explicit `case_reviewer` and `evidence_officer` staff duties require trusted per-case country, ISO subdivision and service-family classification with verified region registry; applicant free-text regions cannot be guessed. Internal intake/verification/evidence metadata RLS and RPCs now reject broad-admin access without a scoped duty, prevent country/province/category leakage and preserve original two-person procedural checks. Operations non-admin shows only authorised case and policy tabs; inappropriate actions hidden, server authority enforced. SQL 51/1,008 passed and Operations 37/37 widget tests passed; remaining clearance, legacy provider/staged routes, staff governance and legal/browser gates leave E6 OPEN. See `docs/E6B_CASE_JURISDICTION_SCOPED_REVIEW_20261011.md`.

---

## FILLER-2026-10-11-14 — CX1 safe Refresh navigation at narrow widths

**Status:** Implemented automated test expansion only. All three labelled Refresh buttons now have explicit tests at 320px as well as larger devices; six 320/1440px observer tests verify that centre taps trigger a second read without navigating to another Flutter route. Isolated 22 focused tests PASS; complete Flutter analyses/widget regression PASS, including a second combined E6A/CX1 integration worktree (132 Client/34 Operations/12 Technical tests). Five localhost endpoints, Web parity and emulator 4010 reverified. No live signed-in Chrome button click accepted (the dedicated Client window lost ownership/focus), no Web/Android redeployment or account data change. CX1 OPEN; T2.4 DEFERRED. See `docs/CX1_REFRESH_ROUTE_SAFETY_QA_20261011.md`.

## FILLER-2026-10-11-13 — E6A policy jurisdiction duty isolation

**Status:** Partial E6 implementation on EAGLT02, **not** total E6 completion or production approval. Explicit scoped country/province/category `policy_author` and `policy_reviewer` checked by database RLS and RPC; administrative policy reviewer must be different from author and not named recusant. Duty grants are issued only by trusted `service_role`, not self-issued, and expire/revoke; no existing admin inherits country-wide rights. Additional `evidence_officer`, `final_approver`, `safety_investigator` duty names are reserved but **do not yet authorise** evidence access or clearance. Separate read-only scoped Operations workspace avoids full administrator shell. Locally tested 50 SQL/973 assertions and 34 Operations widgets; broader legacy-case scoping and E7 onward remain outstanding. No online VM usage, identity uploads, KYC issuance or activation. See `docs/E6_SCOPED_OPERATIONS_POLICY_DUTIES_20261011.md`.

---

## FILLER-2026-10-11-12 — Enterprise trust handover; packageable, NO VM rollout (LATEST)

**Status:** OWNER DIRECTIVE CONFIRMED; **documentation/Git/GitHub handover only**. Stop implementation in this chat. Complete the enterprise platform on **EAGLT02** before any VM operation; never log into, synchronise, upgrade or reinstall the online VM until a separate explicit instruction. Preserve a versioned installable/upgradable Linux source-release boundary throughout development. Read `docs/START_NEXT_CHAT_20261011.md`, `docs/ENTERPRISE_RELEASE_READINESS_GATES.md` and the new **top** sections of `docs/HANDOVER.md` and `docs/ROADMAP.md`.

### Latest verified enterprise work (Phase 2E; committed `af63232` prior to this docs handover)

- **Operations → Verification & KYC → International compliance policy proposals**, served on EAGLT02 `:3200`. Internal-only country/region/category policy authoring includes a draft notice, data collection purpose, *proposed* legal basis/retention/document categories, mandatory preview, independently reviewed state machine, append-only policy audit and immutable revision lineage. Writer cannot self-review. Legal approval, consent, uploads and actual policy effect **not** added.
- Backend migrations `20261011200500_vendor_policy_governance.sql` and `20261011201000_vendor_policy_revision_chain.sql`, tests `048_vendor_policy_governance.test.sql` and `049_vendor_policy_revision_chain.test.sql`; **49 database files / 937 pgTAP checks PASS**. Operations **33 Flutter tests PASS**, analyzer clean and browser-served code verified. Tests are local only; no real jurisdictional legal approval inferred.
- Earlier controlled local foundations remain intact: individual/business vendor applications; category-specific eligibility metadata and address; two-person preliminary verification, owner-visible evidence requirement/withdrawal/preflight, scanner/quarantine **synthetic** custody, emergency clearance revocation, auditable staff operations. Upload, KYC issuance, live payments and vendor activation remain safety-gated.
- Existing versioned source package `.wantok/releases/wantok-vps-af632329546c.tar.gz` includes the current tested `af63232` source checkpoint, has **62 migrations / 11,685,311 bytes**, SHA-256 `d62fc9b5ee3d1def087425a6482401cdd821d539bdfc32d4577774abb2fdca5b`; its manifest/checksum checked. Package is not a signed/offline production installer or VM staging acceptance.

### Requirements added/clarified for next chat

- **FILLER enterprise permission and jurisdiction contract (FIRST):** restrict Operations staff not only by role but by **country, state/province, category, conflict of interest and separation of duties**. Policy writers, independent policy reviewers, evidence staff, investigators, final clearance approvers and platform Technical Control must not share all powers. Current broad `is_admin` implementation is an interim administrative gate, not country-specific enterprise authorisation; implement an additive, testable migration.
- **FILLER consent:** proposed notices must not silently become live. Add separately legally approved purpose-specific notices, stable content hashes/revision/effective dates, applicant informed consent, re-consent, withdrawal, lawful retention/delete/hold and international privacy reviews. Do not invent country-specific statutes.
- **FILLER evidence:** production-grade, privately encrypted/sandboxed malware-scanned upload and custody cannot open until KMS/security, consent, durable audit and disaster recovery have passed; signed-in applicant preflight must continue to fail closed.
- **FILLER independent decisions/appeals and Helpdesk:** distinguish procedural review from evidence-backed KYC clearance; handle expiration, re-verification, fraud/safety investigation, complaints, ticket SLAs and a **dedicated enterprise Helpdesk** distinct from current Support Inquiries.
- **FILLER installation acceptance:** build from Git commit to a checksummed source package; keep immutable migration history, external config/secrets/persistent data, recovery backups, roles/tests and signed release compatibility; **Linux VM deployment tests require later owner permission**, not this or the next unauthorised coding step.
- **CX1/T2.4 not overwritten:** signed-in toolbar click acceptance, physical HONOR/Android, new category photo editorial and actual image CRUD still open; Technical `T2.4` diagnostics/logs/jobs remains deferred. Never include unrelated untracked `supabase/snippets/` or private QA screenshots in a Git commit.

**Next-chat action:** inspect EAGLT02, repository status and the top handover capsule; start **country-scoped Operations RBAC** (E6) as the first implementation task, keep the gateway and VM off, test and Git/GitHub backup after a reviewed feature increment.

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

---

## FILLER-2026-10-10-03 — Enterprise visual consistency across signed-in Client tabs

Owner reviewed and accepted Home's compact visual treatment but pointed out that Services and the other signed-in Client pages were not visually consistent. On authorised EAGLT02, implemented shared `ResponsiveClientCanvas` for six Client tab destinations at >=700 px (max widths 1480 px Home/Services/Explore/Wallet, 1160 px Track/Inbox); vendor/admin/technical platforms unchanged, mobile unchanged. Services photo tiles now max 245 px per card instead of 4 oversized columns. Explore has local bundled PNG water/events/trades editorial inspiration tiles only; these are **NOT offers/bookings** and no made-up providers/locations introduced. Track and Inbox have enterprise green/gold header styling and existing real RLS booking/conversation/empty states; Wallet preview now brand-green and remains K0.00 with all rails inactive. Six focused widget scenarios passed at desktop 1560-1800 px and phone 390 px, with explicit no overflow. No Supabase, authentication, transactions, reviews, evidence or permissions changed. Pending full Flutter+DB pass, commit/push/bundle and Client-only :3000 restart; CX1 remains open. Preserve unrelated untracked `supabase/snippets/`.

---

## FILLER-2026-10-10-04 — CX1 visual acceptance and protected Support & Inquiries queue

**Owner acceptance:** on 10 October 2026, after viewing the deployed signed-in Wantok Services Client web interface on EAGLT02, the owner stated **“Perfect. Approved. Please proceed with CX1. Remember to update handover notes and fillers.”** Record a **PASS for the responsive enterprise visual design** of Home/Services/Explore/Track/Wallet/Inbox and the existing mobile/tablet responsive source. It is not proof of authenticated *functional* Web provider search/rating/Saved, Agent handoff, reviews, live transactions, or physical HONOR acceptance. CX1 remains IN PROGRESS and T2.4 deferred.

**Next CX1I implementation:** `apps/wantok_admin/lib/src/dashboard/support_inquiries_page.dart` supplies a **read-only protected Support & Inquiries** queue in the existing Operations Admin navigation (no role changes). Reads at most 150 records from existing `public.ai_agent_handoff_requests` through the current signed-in Supabase client and existing RLS; filters open/assigned/resolved/closed, displays UTC submit date, private summary and existing resolution note, and offers a safe retry. UI never changes status/assignment/resolution or sends messages; live model/chat/staff replies remain unimplemented. Do not log user summaries or bypass authorised RLS. `support_inquiries_page_test.dart` injects synthetic local widget-test data (not live DB fixtures), covering 390/850/1440 px, read-only filter and error/retry. No new migrations, test accounts or privilege grants.

**Validation PASS:** 7 clean Flutter analyses, 94 Client + 12 Operations Admin + 1 Technical tests, 35 pgTAP SQL files / 767 assertions. **Next acceptance:** deploy only the unchanged-auth Operations Admin application on local loopback `:3200` after all Flutter/database regressions, GitHub feature push and independent Git bundle; log that authenticated browser UI evidence still needs owner observation. Preserve `:3000` Client, `:3100` Technical Control, Android emulator, local Supabase volumes/data, and unrelated untracked `supabase/snippets/`. Continue signed-in Client Web `plumber` → Specialist Services/Morobe/Lae, 5.0 (1) approved QA provider card, Saved/detail, Account, Inbox, Track, Wallet and Agent read-only verification. Keep any production evidence-storage, payment and provider-approval gates closed.

---

## FILLER-2026-10-10-05 — CX1I source deployment and evidence distinctions

**Source checkpoint:** `3342ac05cbb833abc69511a8db28f2580c536fe2` on `feature/flutter-platform-v1`, pushed to `https://github.com/mpokana/wantok-service.git` and verified remote HEAD equal to local. Independent full-history backup `D:\Wantok_Project_Backups\wantok-services-cx1-support-3342ac0-20261010.bundle` (11,539,914 bytes, SHA-256 `1A2A7EA6D9262BB9533AF506366C16582FA17164F13FBB7E965315A5800DECD1`) verified with `git bundle verify`. Full Flutter check PASS (7 clean analyses; 94 client + 12 Admin + 1 Technical tests); PostgreSQL pgTAP PASS (35 SQL files/767 assertions).

**Deployment:** On authorised EAGLT02, only the clean detached `D:\Wantok_Web_Admin_20261010` checkout was advanced to `3342ac0` and the existing loopback Flutter Admin `:3200` restarted with its previous `local-web.json` and `WANTOK_SMOKE_DATA=false` configuration. `:3200` HTML and Flutter bootstrap HTTP 200, Client `:3000` and Technical `:3100` remain HTTP 200 and unmodified. Read-only local SQL count confirms **one previously existing open Wantok Agent handoff**. No request body/user ID/session tokens exported. No staff statuses/assignments/replies, records, schema, accounts, roles, payments, approval workflow, emulator, or Supabase volume were changed.

**Accuracy:** The sign-in-protected Admin queue has NOT yet been visually inspected in an authenticated browser; HTTP 200 and the tests do not prove actual signed-in rendering. Owner should use current Operations Administrator account in Chrome at `127.0.0.1:3200`, hard-refresh and open **Support & Inquiries**. The owner separately approved the *responsive desktop Client visual direction*, while genuine authenticated Client Web CX1F provider filtering/Saved/detail, Account/Track/Inbox/Wallet/Agent journeys, tablet/handset physical acceptance and staff reply workflow remain open. CX1 **IN PROGRESS**; T2.4 still deferred. Unrelated untracked `supabase/snippets/` deliberately untouched.

---

## FILLER-2026-10-10-06 — Resumed CX1F Android read-only QA; authenticated Admin shell, queue still pending

**EAGLT02 observed on 10 Oct 2026:** local Client/Technical/Admin web listeners :3000/:3100/:3200 returned HTTP 200, and a real Chrome window visibly displayed a signed-in Operations Admin **overview**, authentic local overview counts and the **Support & inquiries** sidebar link. This does **not** prove the new queue loads or that staff can filter its one existing open handoff: the active desktop tab changed during UI review, so no authenticated queue screenshot or requester content was obtained. Keep Admin queue browser acceptance OPEN and do not export private support summaries/cookies/tokens.

**Android CX1F functional PASS:** preserved EAGLT02 `Medium_Phone_API_36.1`, installed `io.wantok.service`, real sign-in, and tapped Services → provider discovery. Searching `plumber`, filtering **Specialist Services → Morobe → Lae** retained **Wantok QA Plumbing Services**, **5.0 (1)**; opening its actual detail displayed **QA Plumber & Maintenance**, a Quote service in Lae/Morobe. This is stronger than widget-only evidence but **does not count as the still-pending authenticated Web check**. Did not tap Saved, send messages, book, add reviews, alter account, initiate funds/approval or create synthetic records. QA PNGs saved only in ignored `.wantok/` (see CX1 gate). Emulator user data preserved.

**Additional read-only Android evidence:** user Inbox still separates Services (0) and Help & support (1); Track shows one existing completed Specialist Services booking with Edit review entry; Wallet K0.00 and explicit inactive payment rails remain; top Profile offers My Settings / Wallet / Vendor. The installed Android Wallet still has an older blue preview card, while the owner-approved newly deployed Web uses green, so **fresh non-destructive Android build/visual parity is still open**, not silently accepted. Screenshots in ignored `.wantok/cx1-android-{inbox,track,wallet,profile}-qa.png`; no saved/review/booking/support/role/money writes.

**Continuation priority:** owner/staff browser should open **Support & inquiries** at :3200 and confirm actual 1-open queue/filter/Refresh state without transmitting sensitive text; then the separate signed-in Client Web :3000 plumber-filter/detail/Saved read-only journey and Account/Inbox/Track/Wallet/Agent. Model chat, staff reply/assignment, provider approvals, sensitive evidence upload and payment settlement stay gated. Existing `supabase/snippets/`, user session, local Supabase and production untouched. CX1 **IN PROGRESS**; T2.4 **DEFERRED**.

---

## FILLER-2026-10-10-07 — Authenticated Support queue screenshot acceptance; Refresh and Retry regression fixed

**Screenshot evidence from owner:** live EAGLT02 Chrome Admin at `127.0.0.1:3200` shows authorised **Support & Inquiries** route, **1** recent request and **1** open/assigned, original Open CX1 Android QA handoff (no operational assistance requested), UTC time, visible All/Open/Assigned/Resolved/Closed status chips and Refresh. Mark *authenticated queue DISPLAY* PASS, superseding the earlier owner-acceptance pending entry. A single screenshot proves neither click behaviour nor full staff workflow. Do not commit the screenshot/request detail or Chrome credentials.

**Focused reliability discovery/fix:** new real Flutter widget Refresh test reproduced pre-existing assertion `setState() callback argument returned a Future` from the Admin queue's `setState(() => _future = _load())` implementation. Replaced with block-form synchronous assignment to `_future`, used by both Refresh and Retry; fixed visible grammar for single-request count. Expanded `support_inquiries_page_test.dart` to **8 passing focused cases**, including every status chip, refresh re-query, recovery after failed request and 390/850/1440 px layout. No staff reply, assignment, status change, Supabase migration, RLS/role grant, payment or external chat activation.

**Next:** full 7-target Flutter, Client/Admin/Tech widget and 35-file pgTAP regressions, `git diff --check`, GitHub feature push, full independent bundle; then advance/restart **only** clean detached Admin worktree on `:3200` with unchanged local defines, verify HTTP 200 and have owner optionally click Refresh/Open. Client/Technical origins, emulator userdata, local Supabase and existing untracked `supabase/snippets/` remain preserved. Signed-in **Client Web** `plumber`/filters/provider detail/Saved/Account/Inbox/Track/Wallet/Agent is still OPEN despite real Android PASS. Updated physical HONOR acceptance and all monetary/approval/evidence gates remain pending.

---

## FILLER-2026-10-10-08 — CX1I read-only queue repair deployed on EAGLT02

**Validated source:** `a69d36665817e6e542d8a4c70853bd70f42219d7` pushed to GitHub `feature/flutter-platform-v1` (remote HEAD verified) and backed by independently verified full-history Git bundle `D:\Wantok_Project_Backups\wantok-services-cx1-support-refresh-a69d366-20261010.bundle` (11,566,955 bytes, SHA256 `745287EEA67989C509AE78E8DEBDB3828E8A0C6469BD43C6F5424110A15927D1`). Full 7 analyses, 94 Client + 15 Admin + 1 Tech widget tests and PostgreSQL 35 files/767 assertions PASS; `git diff --check` PASS. Admin focused eight tests PASS including all filter choices and actual Refresh/Retry callback tests.

**Deployment:** Original Admin Flutter process closed gracefully with `q`; only clean detached `D:\Wantok_Web_Admin_20261010` advanced to `a69d366` and restarted at `127.0.0.1:3200` with original local backend defines, sample fixtures OFF. HTTP 200 confirmed for Admin `:3200`, unchanged Client `:3000`, unchanged Technical `:3100`; existing `emulator-5554` remained connected. This fixes Future-returning `setState` for Refresh and Retry and singular request text. Owner's prior authenticated screenshot confirms read-only queue with one open CX1 QA handoff **before** this UI fix; new runtime source is served, but a post-deployment authenticated hard-refresh/click has NOT been claimed. No source/prod permissions, database records, other worktrees or unrelated `supabase/snippets/` changed. CX1 Web functional and physical Android/HONOR acceptance remain OPEN. T2.4 deferred.

---

## FILLER-2026-10-10-09 — Owner correction: category-first CX1 acceptance replaces plumber-primary

**Decision:** owner explicitly requested that **Specialist Services** search, not the particular word `plumber`, lead the acceptance protocol. Never equate broad specialist categories with a single trade. Current **PRIMARY** sequence is signed-in **Services → Browse providers / Explore providers → Specialist Services → Morobe → Lae → Provider Details** **with an empty text-search field**; `plumber` remains an independent **SECONDARY keyword-query regression**.

**Live evidence PASS — EAGLT02 preserved `emulator-5554`:** opened signed-in Home; Home **Specialists** tile routed to **Describe the job / Post request** (viewed only, did NOT submit). Returned to **Services**, opened **Browse providers**, left keyword search **BLANK**, selected **Specialist Services**, **Morobe**, then **Lae** in the actual provider directory. Genuine existing QA provider **Wantok QA Plumbing Services** returned with **5.0 (1)** and the provider detail opened to **QA Plumber & Maintenance** (approved Specialist Services · Lae, Morobe · Quote). No new bookings, Saved toggles, payments, provider applications, reviews, job requests or synthetic records. Evidence in ignored `.wantok/cx1-categoryfirst-*.png` only; do not publish screenshots or sessions.

**Important differentiation:** Home Specialist category is a **create-request** entry; Services → Browse providers is a **read-only provider-directory** entry. Both are current behaviours; neither should be silently changed during QA. If a future UX adjustment is requested, design and authorise it separately. The exact same blank-search provider directory path remains **OPEN on authenticated Web `:3000`**; Android PASS does not close Web. Read-only Saved, Account/Inbox/Track/Wallet/Agent, HONOR physical parity and other real service categories are separate. Other category rows should be tagged `PASS (loaded)`, `PASS (truthful empty)`, `BLOCKED (missing approved test data)` or `FAIL (functional error)` based on actual evidence, not assumptions. Keep CX1 OPEN and T2.4 deferred.

---

## FILLER-2026-10-11-01 — CX1 continuation after new Public Services/category artwork and Theme & Media

**Baseline changed after prior handover:** on EAGLT02 the real development source is now locally committed through `a83d1b0` (11 October), containing `3199499` Public Services directory + Operations module switch, `6508781` distinct category photo mapping, and `a83d1b0` Technical Theme & Media appearance draft/preview/publish. The 10 October dated Flutter worktrees are deliberately behind. On initial inspection GitHub feature branch was still `b2dbc55`; preserving three local commits is critical. `supabase/snippets/` remains pre-existing and unrelated.

**Web smoke:** Client `:3000` served Public Services icon/photo, Emergency icon, Government photo and Specialists photo assets with HTTP 200; JavaScript includes Public Services. Technical `:3100` JS includes Theme & Media. Staging `:3300/:3400` responds. Admin `:3200` remains `a69d366` detached, so its source-level Public Services module switch is NOT accepted as deployed there. Do not replace active servers from 10 October snapshots or enable a module silently.

**Source security/QA:** local pgTAP 37 files, 789 assertions PASS; current Client 102 widgets PASS, Admin 17 widgets PASS. Seven Flutter analyses clean after correcting one braces-only Dart lint (`packages/wantok_ui/lib/src/wantok_branding.dart`). Flutter Technical tests failed to *start* in the working source because Windows could not remove its locked `build/unit_test_assets`; rather than deleting build output or interrupting a running server, created a disposable clean detached source worktree at `D:\Wantok_CX1_Tech_QA_20261011` and ran all 4 Technical tests PASS, including 3 mobile/tablet/desktop theme previews. No model, payment, auth or database changes; no supplier contact/import.

**CX1 acceptance remains distinct:** signed-in Client Web `:3000` category-first **blank keyword** Specialist Services → Morobe → Lae → provider detail/Saved is STILL OPEN, as active Windows Search overlay prevented safe browser interaction. The Android journey remains historical PASS, not a substitute. The four Public Services areas are emergency/safety, health, government and community **informational only**, with no real dispatch or verified official links. Local media/branding work does not imply production publication. Account/Inbox/Track/Wallet/Agent, physical HONOR, staff live replies and T2.4 gates stay open.

**Checkpoint secured:** local source `3199499` + `6508781` + `a83d1b0` and 11 October CX1 lint/documentation correction `7487c8c` were pushed as a fast-forward to GitHub `feature/flutter-platform-v1`; verified remote HEAD SHA `7487c8c12e3f046085309f1aa1f077d780bf3cbd`. Verified independent full-history bundle `D:\Wantok_Project_Backups\wantok-services-cx1-public-media-7487c8c-20261011.bundle` (12,046,992 bytes; SHA-256 `AB49922715F0E734104EFF240CD7225526C66318BF5EB71C6E8DEC1139CFC400`). Module activation, Technical Appearance Studio publishing, official contact ingestion, Client Web functional acceptance and Android/HONOR visual sign-off remain unchanged/unapproved.

---

## FILLER-2026-10-11-02 — Technical Control Local Applications & Ports, staging truly separate

**Owner direction:** keep the five loopback URLs visible inside the Technical Control Panel and continue CX1 without undoing Public Services, distinct picture slots or appearance work. Added `apps/wantok_tech/lib/src/dashboard/technical_local_ports_page.dart`, a **Local applications & ports** link in the Platform Administrator Technical sidebar/toolbar, direct declared `url_launcher` dependency and `technical_local_ports_page_test.dart`. Endpoint register: 3000 Client; 3100 Technical; 3200 Operations Admin; 3300 Client staging; 3400 Technical staging. All links are exact `http://127.0.0.1:PORT/`; purpose and main/staging distinction visible. Warn that `127.0.0.1` means the viewer's own device and clicking is only a **manual** check, not live uptime telemetry. No Auth/RLS/DB change and no credentials.

**Important existing configuration defect corrected:** 3300 was serving Client's **same directory** as 3000 and 3400 Technical's **same directory** as 3100. Created verified independent snapshots `D:\Wantok_Staging_Builds_20261011\Client` and `...\Technical`, checked `main.dart.js` SHA-256 equality with originals, restarted **only the two staging Python HTTP servers** pointed at snapshots, and verified responses. New release built from isolated QA source worktree `D:\Wantok_Local_Ports_QA_20261011` with unchanged local Supabase build defines (fixtures OFF), including port text and existing Theme & Media. Backed up old main Technical served web tree as `D:\Wantok_Project_Backups\wantok-tech-web-preports-20261011` and `apps\wantok_tech\build\web-preports-preserved-20261011`, then swapped only Technical main `:3100` served files. New `:3100` JS HTTP 200 contains `Local applications & ports`; `:3400` intentionally remains previous staging source. Client and Admin untouched. Browser screenshot privately under ignored `.wantok/cx1-20261011-tech-ports-runtime.png` shows authenticated signed-in sidebar entry beside Theme & Media. Link actions covered by Flutter widget testing; no private cookies/screenshots committed to Git.

**Test evidence:** Tech analyser clean; registry exactly 5 correct URI strings; 390px/1200px page and clickable main/stage tests PASS; full Technical isolated suite **8/8 PASS**. Pre-existing Main Technical `build/unit_test_assets` file lock was bypassed safely with isolated clean worktree, never deleting running app files. Operational lookup `docs/LOCAL_APPLICATION_PORTS.md`.

**CX1 not closed:** signed-in Web Client category-first `:3000` blank-query Specialist Services → Morobe → Lae → real provider detail/Saved, Account/Inbox/Track/Wallet/Agent and physical HONOR remain separate. Operations Admin public-services toggle still source-only because `:3200` older `a69d366` live. No payment, agency official contact, module toggle, live chat or branding publish action. T2.4 deferred.

**Follow-up QA outcome (same CX1 increment):** Complete clean-worktree Flutter regression PASS: **7 analysis targets; Client 102, Operations Admin 17, Technical 8 widget tests**. Local PostgreSQL pgTAP **37 SQL files / 789 assertions PASS**. After deploying Technical 3100, actual authenticated browser shows the new **Local applications & ports** sidebar action; main JS HTTP 200 has the page, staging 3400's older snapshot does not. Local Client, Admin and independent Client/Technical staging still HTTP 200.

**New signed-in Client Web evidence (not merely Android):** Chrome `127.0.0.1:3000` Home shows new Public Services icon/pictures, Services → Explore providers opens provider directory, keyword search remained blank, selecting Specialist Services returned authorised QA provider **Wantok QA Plumbing Services** with sourced **5.0 (1)** and locality Lae. The foreground switched to Technical Chrome before continuing Morobe → Lae → details, so those steps and Saved remain OPEN. Private screenshots only in ignored `.wantok/cx1-web-*-20261011.png`. No account data written. Maintains CX1 IN PROGRESS and T2.4 deferred.

---

## FILLER-2026-10-11-03 — Photo-forward service categories and shared Web/Android media

Owner requested no AI-generated artwork, realistic photographs for Public Services, Education & Training, Hotels, General Labour and remaining plain service categories, and the visible name Operations instead of Operations Admin.

Audited 19 category registry entries (18 actual service categories and navigation-only More). Public Services now uses the pre-existing PNG institutional-building photograph; seven unique bundled licensed Unsplash WebPs added for Education, Hotels, Labour, Financial, Errands, Boat Hire and Venue Booking. Rejected inappropriate sunrise and groceries images during candidate review. Source/provenance and editorial limits in docs/CATEGORY_PHOTO_ASSETS.md. More retains its navigation ellipsis intentionally.

One Flutter renderer now powers both mobile and Web Home/category tiles. Home resolves technical homeIcon, then cardImage, then same bundled photo; catalogue resolves cardImage then bundled photo. Image network failures fall back to the bundled image. Existing independent Technical Theme & Media slots retained. Visible Operations label in Technical port list and provider status copy updated; internal RLS/API/package names unchanged; Operations 3200's new Public Services module control still undeployed and not toggled.

Full isolated Flutter QA from D:\Wantok_Category_Photos_QA_20261011: 7 analyses, 103 Client, 20 Operations, 8 Technical tests PASS. Database tests 38 files/800 assertions PASS. Client Web release on 3000 deployed with static folder swap after SHA-256 verified backup D:\Wantok_Project_Backups\wantok-client-web-pre-photo-20261011; HTTP 200 JS, Public Services and photo assets. Technical 3100 deployed Operations port label with backup D:\Wantok_Project_Backups\wantok-tech-web-pre-operations-name-20261011. Static staging 3300/3400 unchanged.

Matching Android offline-demo x64 APK built (92,684,189 bytes, SHA256 99F965EEDC61C24A13B69550A0823EBF6099433A1F6802424280AFAF3CE88EA1), saved at D:\Wantok_Project_Backups\wantok-client-photo-parity-android-preview-20261011.apk. Initial native build hit Kotlin incremental compiler C-versus-D drive roots bug; setting kotlin.incremental=false in isolated QA Gradle properties only permitted successful build. Emulator Package Manager service returned Broken pipe (32) for pm path and adb install -r, with no uninstall/wipe/change to old installed app. Normal no-wipe reboot attempted, package health not confirmed. Android screenshot/runtime parity remains PENDING, not accepted.

CX1 remains open for actual Web/Android visual owner approval and mobile installation, authentic Web provider category Morobe -> Lae details/Saved and other Client user journeys, HONOR physical device, separate Operations module deployment. T2.4 deferred; no money, emergency dispatch, admin permission or approval changes.

**Android repair/update completion (supersedes temporary install blocker):** gracefully stopped/restarted existing Medium_Phone_API_36.1 AVD with no wipe or userdata reset. Android package service recovered. Installed original build 4003 rejected first candidate build 3 as version downgrade; regenerated SAME offline preview with build number 4004 and the process-local nonincremental Kotlin workaround, saved independent APK D:\Wantok_Project_Backups\wantok-client-photo-parity-android-preview-4004-20261011.apk. adb install -r Success, versionCode 4004, firstInstallTime still 2026-10-05. Screenshots in ignored .wantok show PNG building Public Services on Home and Hotels/Education/Financial/Labour photographs in actual Android Services catalogue. Web :3000 was also visually inspected and passed Public Services photographic card layout. Android demo explicitly remains no sign-in/bookings/money. User final visual approval and HONOR physical device still outstanding.

---

## FILLER-2026-10-11-04 — Unique category images for dormant backend slugs

**Owner direction:** resume CX1; generate a category image when missing but **never reuse another category's image**. Checked actual EAGLT02 PostgreSQL public.service_categories in read-only mode: 23 categories, 20 active, 3 inactive. Cross-checked current Flutter style registry and on-disk files: every active category has its own existing photo; no existing same-file duplicate. Dormant bus-coach wrongly fell to More and dormant flights reused travel-flights artwork. Accommodation already has its own photo. No new service types invented.

**Image source and QA:** attempted AI image generation twice, but the tool supplied whole-page app mock-ups, not individual category image assets. Rejected both (not committed or deployed). Instead created original per-category 960x610 WebP asset files by cropping separately licensed photographic source images; no AI-generated photograph claims. New category_bus_coach.webp (bright long-distance tour coach, Unsplash CDN photo-1570125909232-eb263c188f7e) and category_flights.webp (Pexels Anna Shvets airport self-check-in image 3943950, airline logo masked). Existing user-reviewed visuals kept. Photography does not imply a licensed PNG provider or endorsement; consult docs/CATEGORY_PHOTO_ASSETS.md.

**Code, regressions:** WantokCategoryStyles.busCoach and .flights provide slug-exact distinct pictures, with updated bySlug routing (flights no longer aliases travel-flights). backendCatalogue lists all 23 database category slugs without activating a module. Dedicated backend_category_media_test.dart validates correct slug resolution, distinct asset paths and bundled file bytes and widget rendering. Isolated D:\Wantok_Category_Missing_QA_20261011 full Flutter check PASS: 7 analysis targets, Client 106, Operations 21, Technical 8 tests. Server schema, RLS, booking/payment gates and category is_active flags unchanged.

**CX1 gates:** this is artwork readiness, not activation. Still pending full signed-in Web Morobe/Lae provider/Saved, Account/Inbox/Track/Wallet/Agent, HONOR owner visual sign-off and separate Operations module review. T2.4 deferred.

**Deployment close-out:** New Client Web release built with local-web.json and smoke fixtures OFF; both /assets/assets/images/categories/category_bus_coach.webp and category_flights.webp returned HTTP 200 on port 3000. Initial Windows static folder rename denied access; fallback kept the old build intact. Rebound only the verified Client Python HTTP server to separately copied candidate, overlaid SHA-matched source into canonical apps/wantok_app/build/web, rebound back to canonical; both new assets still served HTTP 200. Verified prior build backup D:\Wantok_Project_Backups\wantok-client-web-pre-extra-category-20261011, independent static candidate retained. Staging 3300 and the three other application ports untouched.

**Android release close-out:** Flutter debug x64 offline-demo APK built as versionCode 4005 (not a downgrade from 4004), SHA-256 F235119375637DFB07C430F94C484025091DA566BCE83911ABE794D0085AF077, copied/hash-verified to D:\Wantok_Project_Backups\wantok-client-complete-photos-android-preview-4005-20261011.apk. Existing Android emulator installed the APK with adb install -r Success and launched; dumpsys reports versionCode 4005 while preserving firstInstallTime 2026-10-05. This upgrade did NOT enable signed-in live backend mode, flights, bus-coach, money, bookings or official emergency contacts. New category images are future-ready, not expected on the current public Home grid. CX1 still in progress; T2.4 deferred.

---

## FILLER-2026-10-11-05 — Category editor and expanded live Home catalogue

User requested complete category management and additional realistic Papua New Guinean/Pacific service imagery. Verified Desktop Commander EAGLT02 online. Main source `e00e824` clean before changes except pre-existing `supabase/snippets/` (excluded). Pre-migration full PostgreSQL `pg_dump -Fc` checked to `D:\Wantok_Project_Backups\wantok-pre-category-editor-20261011.dump` (1,357,065 bytes, SHA256 `75ecd8369a6f31450ef72cccc70445cc12d2251dc653432df6e93e193ea0cf36`).

**Backend:** `20261011163000_category_editorial_controls.sql` applied using `npm run db:migrate`, not reset. Added `show_on_home`, `show_in_services`, `image_path`, audited category edit function and secured admin-only query function. Seeded six new disabled/hidden categories: IT/Electronics, Automotive/Mechanics, Agriculture/Farming, Pets/Animal Care, Cleaning/Maintenance, Construction/Trades. All 23 original categories and provider histories retained. Direct SQL edit grants remain blocked. Inactive/draft image gate, server-side technical admin authorization, optimistic updates, immutable category slugs, image scope ownership, archive and limited delete. **41 pgTAP files / 828 assertions PASS**, including tests requiring RLS admin read path.

**UI:** Flutter Home no longer hardcodes 6 category limit nor duplicates Travel tile; shows all active `show_on_home` categories in backend sort order. Services honours `show_in_services`. Shared per-category image upload in immutable existing `wantok-branding` bucket; published appearance overrides, server category image path and existing bundled asset fallback preserved. Unknown new categories use distinct generic style, not More icon. Technical Control Platform Admin menu **Service categories** now lists, searches, creates, edits, filters, sorts, uploads/replaces photos and safely archives/deletes unused drafts. RLS protects direct accesses. No real image upload or service activation performed in this QA.

**Tests/deployment:** Full 7 Flutter analyses; 108 Client, 21 Operations, 11 Technical widget tests PASS. Isolated QA worktree `D:\Wantok_CX1_Category_Manager_QA_20261011`, SHA-matched staging web builds `3300/3400` and main Client `3000` / Technical `3100` deployed with independent source backups in `D:\Wantok_Project_Backups`. All five loopback ports HTTP 200, Operations 3200 unchanged. Authenticated EAGLT02 Chrome showed Technical new sidebar and **29 of 29** category rows; Client Home full active category grid. Android x64 offline-demo versionCode **4006** installed with `adb install -r` Success, original first-install date retained; APK backup SHA256 `5658C765DE051606A91C24066ADE7B523CA36BC6CE624D7660514D25977FD62E`.

**Images:** Generated composite Web/mobile/Admin dashboard mock-up was **rejected**, not uploaded as category art because it is not six individual realistic Pacific/PNG pictures. Six new categories remain inactive and invisible pending independently appropriate, distinct image assets and subsequent owner approval. No new actual category photograph generated by the coding step. Existing category pictures unchanged. Category image upload/editor is operational but an actual browser-upload/save test is pending. No payment rails, approvals, emergency dispatch, guest permission, review data or evidence writes performed. T2.4 still deferred. CX1 functional Web provider/Saved/Account journeys and physical HONOR remain OPEN.

## FILLER-2026-10-11-06 — Technical category photos and global theme corrected

Owner screenshot showed category manager had plain white list cards with blank photo icons despite existing Client category photos. Root cause: photographs were bundled in Client-only Flutter app and Technical checked only optional database `image_path`. Implemented canonical single-source media in `packages/wantok_ui`: **23 existing WebP category photographs + real Public Services JPEG** moved physically out of Client source, without generating or copying different stock pictures. Shared `WantokCategoryMedia` provides slug→bundled photo registration and fallback rendering; Client's original category-style photo references now point to the same package. Tests preserve uniqueness and byte presence of all prior categories; external photos are still handled only by existing published branding or category-upload overrides.

Applied published `WantokBrandingTheme` / `WantokBrandingScope` globally across Technical Control's MaterialApp, mirroring Client's previously existing branded theme. Category manager restyled with engineering green-gradient header, same colour tokens, photo-forward cards, summary metrics and visual Active/Draft + Home/Services pills. Focused responsive tests exposed an overflow of 16–27 px in metric Row; corrected using Expanded/ellipsis and reran. **7 Flutter analyses PASS, Client 108, Operations 21 and Technical 12 widget tests PASS** (including real Taxi + Public Services image identity). No DB mutations, category activation, payments or approvals.

Isolated source/QA worktree `D:\Wantok_CX1_Shared_Category_Theme_QA_20261011`. Release Web bundles verified to include shared photographs; SHA-matched staging Client/Technical on ports **3300/3400** with image HTTP 200. Main Client **3000** and Technical **3100** promoted after full recoverable snapshots and controlled temp-candidate binds; canonical builds mirrored and checked. Independent prior build backups `D:\Wantok_Project_Backups\wantok-client-web-pre-global-theme-20261011`, `D:\Wantok_Project_Backups\wantok-technical-web-pre-global-theme-20261011`. Operations **3200** untouched. Real browser screenshot `.wantok/cx1-global-category-manager-list-20261011.png` shows branded category manager and actual Taxi / Hire Car / Boat Hire / Water Transport photos, with 29 total, 20 active, 9 inactive.

Matching offline-demo Android x64 debug APK **4007** built from same QA assets and saved `D:\Wantok_Project_Backups\wantok-client-global-theme-shared-media-android-preview-4007-20261011.apk` SHA256 `BDB6A8BE87AAAD4E060DD2C2A9AB0201B4148A6E35375990C1D70498F086EE91`. `adb install -r` Success; preserved emulator firstInstallTime 2026-10-05 23:44:14; package launched; Android screenshot `.wantok/cx1-shared-photo-android-4007.png` shows same category artwork and no active bookings/money. User's request about realism is satisfied for EXISTING PHOTOS via reuse, but **six new inactive category photographs still need to be individually generated/curated and visually approved**, not faked by shared icons. Browser live upload/edit lifecycle, signed-in discovery/Saved and physical HONOR remain outstanding. **CX1 IN PROGRESS; T2.4 DEFERRED.**

## FILLER-2026-10-11-07 — CX1 authenticated Client Web category-first ACCEPTED

Actual EAGLT02 Chrome Client at `http://127.0.0.1:3000/` navigated `Services → Browse providers → Explore providers → Category Specialist Services → Province Morobe → Town Lae → Provider Details`, with free-text search **blank the entire time**. All filters remained visibly selected; existing real Wantok QA Plumbing Services (verified QA business) returned rating **5.0 (1)**. Provider detail displayed approved **QA Plumber & Maintenance**, `Specialist Services · Lae, Morobe · Quote`. Screenshot records in ignored `.wantok/cx1-web-category-morobe-lae-pass.png` and `.wantok/cx1-web-provider-detail-pass.png`. Full reproducible steps in `docs/CX1_WEB_DISCOVERY_ACCEPTANCE_20261011.md`. No job requests, booking, ratings, reviews, bookmarks, approvals, profile updates, payments or messages changed.

New additive optional read-only `SavedItemsPage.loadSavedItems` loader exists for tests. Original production ClientExperienceRepository load and Supabase RLS unchanged. Four focused Saved widget tests PASS (390px, 1240px, empty state, failed read/Retry), with **zero Saved writes**. Isolated QA worktree `D:\Wantok_CX1_Saved_Readonly_QA_20261011` passed full `scripts/flutter/check.ps1`: seven analyses and complete Client, Operations, Technical test suites including four new cases. No new Web/Android release is necessary because the only runtime change is an optional test loader which production never supplies.

The verified QA provider had a filled green bookmark icon, but it was deliberately not clicked; **live signed-in Account → Saved persistence is still OPEN**. After provider detail acceptance, Chrome focus switched from the intended Wantok Client to Operations/Windows desktop; input scripts aborted on the wrong foreground window. Multiple matching Chrome windows were minimised. Exact provider-detail window was restored and visually confirmed but user/other desktop work then resumed, so additional Client clicks were not attempted. No credentials, tokens, cookies, personally sensitive account details or private screenshots pushed to Git.

Other CX1 gates OPEN: Web Account, Inbox, Track, Wallet, Wantok Agent, genuine Saved page display, physical HONOR device, and unique approved Pacific/PNG-themed photographs for six inactive service categories. Concurrent uncommitted vendor-verification implementation and unrelated `supabase/snippets/` are not part of this work; do not stage. Existing Operations :3200 and Web :3000/3100/3300/3400 unchanged. **CX1 IN PROGRESS; T2.4 DEFERRED.**


## FILLER-2026-10-11-08 — CX1 Saved refresh deployed, Web and Android

User requested resumption plus handover/filler updates. EAGLT02 Desktop Commander online; original feature branch checkpoint `dd0a24d`. **Earlier authenticated Web category-first gate remains PASS** (blank search, Specialist Services, Morobe, Lae, existing QA provider/detail). Actual authenticated Account → Saved list remains **NOT YET LIVE VERIFIED**, due to an active separate desktop Chrome session; do not infer genuine persistence from prior green bookmark indicator.

**Implementation:** `SavedItemsPage` in `apps/wantok_app/lib/src/home/client_account_tools.dart` now has a visible `Refresh saved items` AppBar button in Web and Android. Refresh uses only existing authenticated `ClientExperienceRepository.loadSavedItems` and existing RLS, never `setSavedItem` unless the separate user-requested remove action is explicitly selected. `_refreshing` prevents overlapping reloads; original pull-to-refresh, empty and Retry paths maintained. New `apps/wantok_app/test/cx1_saved_read_only_test.dart` coverage: **6 focused widget cases PASS** including 390/1240px initial display and toolbar refresh, empty list, failed read/Retry; **zero Saved writes**. Isolated full `scripts/flutter/check.ps1` PASS across 7 Flutter analyses and Client/Operations/Technical widget suites.

**Web:** isolated QA worktree `D:\Wantok_CX1_Saved_Refresh_QA_20261011`; release `main.dart.js` SHA-256 `2DE1432750358A432FA32FCDCDC71DB03534B12A95BD162547EEC5C50C507033`. Client staging `3300` and main Client `3000` promoted after full SHA-matched backup/candidate snapshots, with HTTP 200 app bundle and real photo checks. Previous Client Web in `D:\Wantok_Project_Backups\wantok-client-web-pre-saved-refresh-20261011`; source-matched candidate in `D:\Wantok_Project_Backups\wantok-client-web-saved-refresh-candidate-20261011`. Technical `3100`, Operations `3200`, Technical staging `3400` untouched.

**Android:** matching offline demo x64 debug APK **4008** built from the same clean QA source; hash-verified independent copy `D:\Wantok_Project_Backups\wantok-client-cx1-saved-refresh-android-preview-4008-20261011.apk`, SHA256 `93FBE7C5FF01DC52AF9113943BF99124C2D7BC3763BC0CEE4FFA2F72327B15A8`. `adb install -r` **Success**, original emulator firstInstallTime **2026-10-05 23:44:14** preserved and package launch successful. No uninstall, emulator wipe, signed-in backend switch, payment or provider modification.

**Pending:** real browser Account → Saved list/persistence read-only check with safe Chrome target selection; Inbox, Track, Wallet preview, Wantok Agent and physical HONOR; individual PNG/Pacific-themed artwork for six inactive categories; browser category CRUD/image upload. Concurrent other vendor compliance work and unrelated `supabase/snippets/` files were **never staged or modified** by this CX1 change. **CX1 IN PROGRESS; T2.4 DEFERRED.**


## FILLER-2026-10-11-09 — Live Saved acceptance + Inbox/Track read-only refresh

User requested CX1 continuation. EAGLT02 Desktop Commander confirmed online, repository started at 494e4e9 on feature/flutter-platform-v1 with only unrelated untracked supabase/snippets/. Before any UI write, authenticated Client Web was read-only checked through Home → Account menu → My Settings → Saved. Existing Wantok QA Plumbing Services provider was visibly listed; this closes the live signed-in Saved LIST gate, stronger than merely the filled search-result bookmark. No click on remove/bookmark, booking, payment, review, account edit, message or handoff. Private screenshot .wantok/cx1-live-saved-readonly-20261011.png excluded from Git and account PII not copied into documentation.

The later hard browser reload reset Flutter's route stack to Home, and the next browser navigation command was blocked by safety controls. No more browser clicks attempted. Thus post-reload Saved, actual live Inbox, Track, Wallet and Wantok Agent, signed-in Android and HONOR remain OPEN, not silently claimed.

Implemented non-transactional Refresh Inbox in MessagesPage and Refresh activity in ActivityPage, on their existing enterprise headers, consistent at 390px and 1440px. Messages reloads owner-scoped service threads and help requests, Activity reloads user's reservations, all through unchanged repository/RLS; concurrency guard, Track disabled while booking/review busy. Six focused widget tests PASS including temporary load failure recovery and no write operations. An initial full Flutter check found a missing-brace lint; fixed. Subsequent complete scripts/flutter/check.ps1 PASS for seven analysis targets and Client/Operations/Technical tests. Isolated QA checkout D:\Wantok_CX1_Inbox_Track_QA_20261011.

Web release JS SHA256 AB18B9EB8F0733482B396E3C122EB0B726AB9CF2823A79458B0F34AB9178C51D. Verified static copy/hash/photo checks and promoted Client staging 3300 + main Client 3000. Pre-change full rollback copy D:\Wantok_Project_Backups\wantok-client-web-pre-inbox-track-refresh-20261011; verified candidate D:\Wantok_Project_Backups\wantok-client-web-inbox-track-refresh-candidate-20261011. Technical 3100, Operations 3200, Technical staging 3400, backend category flags, support and financial data unchanged. Android offline-demo x64 APK **4009** successfully built and SHA256 verified (E6E529939F6F44D938BD98F94DDF5CA57C72288B7D63081B047576DBF08DB06F, 92,825,175 bytes), saved as D:\Wantok_Project_Backups\wantok-client-cx1-inbox-track-android-preview-4009-20261011.apk, adb install -r Success, same firstInstallTime 2026-10-05 23:44:14 and launch PASS, no data wipe. Real signed-in Android and HONOR pending.

Remaining CX1: post-reload Saved, signed-in Inbox/Track/Wallet/Agent, physical HONOR, PNG/Pacific visual assets for six inactive categories, browser category media CRUD. T2.4 deferred. No private screenshot or browser secrets staged.


## FILLER-2026-10-11-10 — Signed-in Web read-only journeys and post-reload Saved

CX1 resumed from 809428e while separate vendor/trust work was active. On authorised EAGLT02, Desktop Commander confirmed all five local Web ports (3000/3100/3200/3300/3400) HTTP 200. Main branch advanced concurrently to d4b5751 (trusted custody/release); it was preserved. No Client source code, backend schema, payment, approval, booking, review, messages, account or provider data changed in this acceptance-only pass.

**Actual authenticated Client Web :3000 PASS:** Track showed existing completed Specialist Services QA record in Lae/Morobe; Wallet showed K0.00 and explicitly inactive preview payment rails; Inbox displayed Services(0) and existing owner-private Help & support(1) Open QA item, without opening or changing sensitive details; Wantok Agent page showed controlled provider-search shortcuts and human help, explicitly warning that live AI chat model is not connected. No money, messaging, new handoff or actions performed.

**SAVED after hard Chrome reload PASS:** after full Chrome reload restored Home, safely navigated My Settings → Account and profile → Saved; the same existing QA provider still appeared. This closes same-session post-reload Saved visibility (not logout/login or multi-device persistence); no saved toggle or removal. Screenshot evidence in ignored .wantok/cx1-postreload-saved-list-20261011.png. All other screenshots also stay PRIVATE in .wantok and no user account PII is recorded in committed docs. See docs/CX1_WEB_READONLY_ACCEPTANCE_20261011.md.

**Safety stop:** attempted to click the Saved header refresh tool but UI unexpectedly navigated to Become a Wantok vendor. No form fields touched or submitted. Browser automation stopped to protect active vendor development. Thus live refresh click acceptance for Saved/Inbox/Track remains OPEN; prior six focus widget cases and full Flutter regression from 809428e still PASS, but current browser screenshots do not prove all toolbar controls visible. Do not assume root cause without isolated reproduction. Nothing redeployed.

**Open:** controlled browser toolbar refresh acceptance and any remaining same-user login/session tests, signed-in Android and physical HONOR, six inactive categories' distinct real PNG/Pacific themed photos and authenticated Technical image CRUD. CX1 IN PROGRESS; T2.4 DEFERRED.


## FILLER-2026-10-11-11 — CX1 release parity guard and exact T2.4 scope

User asked to continue CX1 and clarify T2.4. Verified the authoritative ROADMAP.md section: T2.4 = Diagnostics, logs and jobs, AFTER CX1. Five future items: diagnostics adapters; central/module log adapters; background job/queue visibility; approved job actions; richer technical audit views. Required sequence T2.3 checkpoint, then CX1 acceptance, then T2.4. T2.4 is NOT started or completed by this work.

Verified EAGLT02 Desktop Commander online, current feature branch at 7d4f505 and several unrelated uncommitted vendor policy/governance files (Operations code, new database migration, tests), deliberately left untouched. Client Web 3000, Technical Control 3100, Operations 3200, Client staging 3300, Technical staging 3400 all responded HTTP 200. Android emulator-5554 connected with original installed build 4009. Previously accepted live signed-in browser journeys include category-first discovery, Saved list after hard reload, Track, Wallet preview, Inbox categories, and Wantok Agent preview. The live browser refresh-button interactions remain unverified; a former Saved click unexpectedly navigated to vendor onboarding with no changes. No new Chrome inputs or speculative cache/profile modifications.

Created a strictly read-only CX1 QA script, scripts/qa/verify-cx1-local.ps1. It checks all five localhost static shells, the exact JavaScript SHA-256 parity of Client main/staging and Technical main/staging, presence of the three expected Saved/Inbox/Track toolbar labels in actually served Client JavaScript, the byte-for-byte identity of original Taxi and Public Services photographs on all four Client/Technical endpoints, and optional ADB package version without installing or touching data. PASS with Client JS SHA256 AB18B9EB8F0733482B396E3C122EB0B726AB9CF2823A79458B0F34AB9178C51D, Technical JS SHA256 1D0E6DE096EC54D7D189A798B756A23EAE4F4B7CD32C4AAFE4E30DB905AD67A1, shared images, Android build 4009; printed CX1_RELEASE_QA_PASS. Negative test requiring deliberately impossible Android build 999999 produced CX1_RELEASE_QA_FAIL count=1 and exit code 1 as expected, with no state mutation. Static checksum parity CANNOT prove a particular Chrome tab actually rendered the new toolbar or that click inputs are correctly mapped. Details in docs/CX1_RELEASE_PARITY_GUARD_20261011.md.

No application Flutter source, binary, database, vendor records, authenticated session, user data, payments, GVE servers or production systems changed. Remaining CX1: controlled Chrome visibility/click acceptance for Saved/Inbox/Track refresh, signed-in Android and HONOR physical installation, six individually approved PNG/Pacific-themed photographs for new inactive category drafts, browser Technical category-image CRUD. CX1 IN PROGRESS; T2.4 DEFERRED.


## FILLER-2026-10-11-12 — Clearly labelled Saved/Inbox/Track refresh buttons, Web and Android

User directed "Continue cx1." EAGLT02 online but Windows foreground was **Windows Default Lock Screen**, so do not attempt login bypass, credentials, cached user sessions, or blind browser interactions. A Chrome --app local window was started for isolation but the lock screen prevented actual acceptance; actual signed-in browser rendering/clicks **remain OPEN**. Previous case of Saved click unexpectedly opening vendor onboarding was NOT assumed fixed by these UI changes.

To make CX1 controls clearer and safer on both Web and Android, converted existing icon-only refresh actions on Saved, Inbox and Track into **visible Refresh text plus icon** buttons with accessible existing tooltips, stable ValueKeys cx1-saved-refresh / cx1-inbox-refresh / cx1-track-refresh and minimum 96×48 logical-pixel tap targets. Preserved real owner-scoped read-only repository paths, concurrent refresh guards, existing pull-to-refresh, error/Retry, Track transaction-busy protection, and global theming. Did not modify vendor applications, data, payments, bookings, provider review, support status, backend/RLS or technical controls.

Five exact Flutter files copied into isolated worktree `D:\Wantok_CX1_Labeled_Refresh_QA_20261011` based on then-current HEAD 3596658; 12 focused Saved/Inbox/Track tests PASS. Tests now find stable keys, check tap-target height >=44px and tap actual widget centres at 390px and 1240/1440px. The complete seven-analysis `scripts/flutter/check.ps1` and all Client/Operations/Technical widget test suites PASS (including concurrent unrelated vendor tests). No database reset/fixtures used.

Web release built with local defines, SMOKE_DATA=false. Compiled `main.dart.js` contains all three captions and stable keys; SHA256 `2207D8BBCCC5BE261B7C7A77498F4E801829E0D7B13378F56B61A06F3E3B2E66` (4,099,079 bytes). Client staging :3300 and main :3000 promoted with SHA checks and static content/photo HTTP health, prior complete Web backup `D:\Wantok_Project_Backups\wantok-client-web-pre-labeled-refresh-20261011`, independent candidate `D:\Wantok_Project_Backups\wantok-client-web-labeled-refresh-candidate-20261011`. Technical :3100, Operations :3200, Tech staging :3400 left unchanged.

Matching Android offline-demo x64 APK build **4010** compiled and SHA verified at `D:\Wantok_Project_Backups\wantok-client-cx1-labeled-refresh-android-preview-4010-20261011.apk` (92,828,063 bytes, SHA256 `8FE01D17D5C11057B435686F0499D32EC09BE7B368D50CF3F433E696843C8591`). Existing emulator install 4009 upgraded with `adb install -r` Success; versionCode 4010, firstInstallTime **2026-10-05 23:44:14** unchanged, app launched, no data wipe or sign-in mode change.

Evidence/gate: `docs/CX1_LABELED_REFRESH_ACCEPTANCE_20261011.md`. Open browser visual/click tests after Windows unlock, signed-in Android and physical HONOR, six new inactive categories' distinct PNG/Pacific imagery + Technical authenticated image upload/editor acceptance. Existing Account Saved listing, provider category-first, Inbox/Track/Wallet/Agent read-only browse acceptance unchanged. CX1 IN PROGRESS; T2.4 DEFERRED.
