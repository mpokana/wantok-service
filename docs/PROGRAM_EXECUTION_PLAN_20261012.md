# Wantok Services — Integrated Engineering Execution Plan

**Owner direction:** 12 October 2026, Papua New Guinea
**Single programme coordination:** this ChatGPT conversation, using only authorised laptop **EAGLT02**
**Repository:** `D:\Project-M.2\wantok-service-recovery`, GitHub `mpokana/wantok-service`, `feature/flutter-platform-v1`

## Binding order and decision

**Priority: E-series Operations/Enterprise → CX1 Client Experience → T2.4 Technical Control.** Do not resume T2.4 development while outstanding E engineering and CX1 acceptance are the current programme priorities. The completed T2.4A–E local source is preserved, **not deployed**. All future instructions in the current conversation must check this plan before changing scope.

**One chat as programme owner does not technically lock Git or stop another chat.** Do not assume exclusive ownership from a clean working tree; check both local/remote HEAD, ongoing processes, uncommitted edits, independent worktrees and a clearly assigned phase before each checkpoint. The user must stop other sessions from writing. Only stage owned paths, never `git add .`, `reset --hard`, force-push or delete other work.

### Terminology and status discipline

- **CODE/QA PASS**: automated source/security checks passed at an exact commit. Does not mean functionality is deployed, usable in signed-in browsers, or production ready.
- **LOCAL ACCEPTED**: real authorised EAGLT02 browser/emulator/handset test completed with a reproducible result, environment/build ID and safe evidence record.
- **EXTERNALLY BLOCKED**: delegated staff authority, law, jurisdiction, privacy, key custody, independent witness or real authentication is unavailable; an AI/test script cannot sign it off.
- **PRODUCTION AUTHORISED**: an entirely separate signed release determination; currently **NO**.
- Existing smoke/demo assets are not commercial inventory, providers, payments or approvals. All sensitive evidence remains out of GitHub.

## P0 — E-series Enterprise/Operations (ACTIVE)

**Baseline:** E6A–I security foundations have source/isolated QA evidence: two-person duty grants, independent case/country-category scopes, applicant read denial, investigator/reviewer conflict and recusal, sealed identity evidence/activation paths. E6I tested E6H plus then-three T2.4 migrations in a disposable schema/role stage **145/145**; this is historical test evidence, not permission-owner parity or current complete suite. T2.4E subsequently added a fourth technical migration.

### P0.1 — Engineering tasks permitted on EAGLT02

1. **E-01 — Migration and privilege equivalence audit (NEXT).** Produce a reproducible, **read-only** function-owner, search_path, role-grant, RLS-policy, SECURITY DEFINER and service-role inventory of E6/E6H and current T2.4 SQL against the authorised *local* Supabase; identify differences from existing isolated test-specific owner/ACL and document risk. Do not modify the shared DB. Use a disposable stage for any prospective migration.
2. **E-02 — Cross-stream regression after T2.4E addition.** In isolated network-disabled SQL, test exact pending migration order: E6H `20261011233000` then Technical `20261011240000`, `241000`, `242000`, `243000`. Cover E6 scopes, T2.4 090–093, rollback and source DB unchanged. Current previous 145/145 is not enough for the new fourth Technical migration.
3. **E-03 — Auth/RLS trust-matrix preparation.** Extend negative cases for applicant self-access, country/province/category, expired/revoked staff, conflicts, role privilege escalation, service-role exposure and legacy direct REST/RPC. Use only synthetic/rollback cases; distinguish signed synthetic JWTs from GoTrue credentials.
4. **E-04 — Safely prepare *dedicated staging* acceptance checklist.** Document backup integrity, exact role/ownership/ACL restore, migration abort/rollback, immutable evidence recording, account isolation and two-person witness protocol. Do **not** create trusted people or staging user accounts, reset the shared database, alter keys or apply migrations without separately granted authority.
5. **E-05 — Re-run full eligible clean Flutter/evidence/SQL regressions** using exact commit detached checkout, label any combined SQL failures due to unapplied migrations, checkpoint all source/doc changes and verify GitHub plus source-release `productionApproved:false`.

### P0.2 — Hard external gates before E6 closure and any E7 implementation

`docs/E6G_FORMAL_ACCEPTANCE_RUNBOOK_20261011.md` **E6-G1 through G10 remain BLOCKED**: real staff/HR delegation; distinct requester/approver and trusted key-custody sign-off; current maintained ISO country/subdivision attestation; legal service-family mapping; independently reviewed conflicts/related-party interests; separate real GoTrue sessions and PostgREST/browser positive/negative cases; independent RLS/legacy security audit; offboarding/DR and recovery witness; final security/compliance/owner approval.

**E-series is NOT complete**, even if P0 engineering tasks pass. E7+ identity intake, approval, KYC, payments, activation, production VM or shared DB migration remain sealed. **Escalation rule:** after P0 safe tasks have been exhausted, create a compact externally-blocked acceptance register and *only proceed to non-mutating CX1 work* without implying E6 passed. Any E-series high-risk implementation stays blocked until owner authorises the specific dependency.

## P1 — CX1 Client Experience (QUEUED; starts after P0 safe engineering checkpoint)

Current official navigation: **Home · Services · Explore · Track · Wallet**, Inbox in top header beside Profile; Provider registration under Profile. Preserve Wantok branding, approved images and backend-driven service categories. CX1 source regression has already passed but **CX1 gate remains OPEN**.

1. **CX-01 — Signed-in Client Web category-first functional journey.** On local Client `:3000`, preserve existing authorised session; **blank keyword search → Services/Browse providers → Specialist Services → Morobe → Lae → active QA provider card/5.0(1) rating → approved service/detail**. Record sourced empty states where no backend coverage exists; no simulated provider approvals or application submissions. Check wrong-route issue from Saved Refresh to Vendor Onboarding; do not claim fixed without actual reproduction and root-cause evidence.
2. **CX-02 — Authenticated read-only navigation/Refresh.** Witness Saved, Inbox/help and Track/Completed actual `Refresh` button centre taps on Web at narrow and desktop widths, unchanged route and record count; then Account/Privacy, Wallet **K0.00 planned-only** and Wantok Agent **not connected**. Keep browser credentials/cookies and screenshots out of Git. UI/source hashes or HTTP 200 alone do not pass.
3. **CX-03 — Photo/editor and product acceptance.** Verify six inactive-category editorial photos under existing security rules, Technical category selection/Cancel/Save/reload on authorised local environment *only when separately approved*; no category activation or real uploader bypass. Verify current Client :3000/3300 asset release parity. Never assume existing storage writes are reversible without evidence.
4. **CX-04 — Android/HONOR acceptance.** Confirm version/build, retained userdata, parity, owner visual/physical HONOR testing and any unavailable device as **BLOCKED** rather than PASS. Do not uninstall/reset existing emulator or sign-out users; previous offline-demo APK is not a signed-in production test.
5. **CX-05 — CX1 final evidence matrix.** Separate historic owner screenshot approvals from newly witnessed real user/browser tests, document inaccessible data or OAuth provider settings honestly, and get owner sign-off on **CX1 scope only**. Do not auto-authorise payments, provider roles, WhatsApp/agent backends, production or later CX1G/H capabilities.

See `docs/CX1_CLIENT_EXPERIENCE_GATE.md`, `docs/CX1_CATEGORY_PHOTO_STAGING_20261011.md`, `docs/CX1_REFRESH_ROUTE_SAFETY_QA_20261011.md` and `docs/CX1_LABELED_REFRESH_ACCEPTANCE_20261011.md`.

## P2 — T2.4 Technical Control (PAUSED; resume after P0 safe checkpoint and P1 gate)

Source-completed but unapplied: diagnostics/probes/dependencies; module health-transition log RPC `20261011240000`; Messaging queue aggregates `241000`; redacted Technical Activity `242000`; T2.4E metadata-only central log-source contract/readiness `243000`. T2.4E **58/58** SQL and 7 Flutter analyses / 132 Client / 43 Operations / 38 Technical widget checks were observed at its source checkpoint; no actual central collector, worker-liveness feed, executable jobs, ingestion or production approval.

After explicit unpause:
1. Map **actual** approved application/container log producers and worker processes; contract provenance, retention, redaction and trustworthy heartbeat state. An entry saying `not_connected` is not a collector.
2. Secure exact per-module log-source isolation, bounded pagination, content privacy, index/retention, audit integrity, availability and reliable worker freshness. Do not infer delivery from `sent` or worker life from `processing`.
3. Only design — **do not enable** — run/retry/cancel background jobs until idempotency, locks, dual controls, audit, impact preview and independent operational authorisation exist.
4. Repeat combined E6H + all T2.4 migrations in a formally approved backed-up staging system with exact production roles, witnessed GoTrue/PostgREST user matrix, full SQL and Flutter QA; no online VM unless explicitly authorised.

## Workstream controls, acceptance and checkpoint protocol

| Scope | Single-chat accountable coordinator | Source owner while active | State |
| --- | --- | --- | --- |
| E-series Operations/security | Current conversation | Current conversation | **ACTIVE P0** |
| CX1 Client experience | Current conversation | Current conversation | **QUEUED P1** |
| T2.4 Technical Control | Current conversation | No active code writer until unpaused | **PAUSED P2** |
| Shared `docs/HANDOVER.md`, `docs/ROADMAP.md`, `docs/ROADMAP_FILLERS.md`, `AGENTS.md`, `package.json`, common DB | Current conversation, serial only | One explicit writer/checkpoint | **SERIALISED** |

Before any editing: read `AGENTS.md`, this execution plan, living handover/roadmap/fillers and task architecture; check `git status`, HEAD, remote and process ownership. Prefer a new detached worktree from the verified SHA. Commit only owned files, run `git diff --check`, scoped tests and clean `scripts/flutter/check.ps1`; do not conceal skipped combined DB assertions. Coordinate fast-forward and verify remote SHA before GitHub push. Verify checksum/source archive and backup release; keep `productionApproved:false`. Preserve pre-existing untracked `supabase/snippets/` and every unrelated active worktree.

**Latest E6M safe engineering and G workboard:** Static source-only scan of latest checked-in 19 selected E6 SECURITY DEFINER functions: explicit paths and schema-qualified table references under narrow lexical check, no explicit dynamic SQL; **two E6H functions remain unapplied locally**. This is not a full SQL AST/privilege/call-graph audit. In parallel created **G1–G10 gate-by-gate independent evidence workboard**, 18 planned real GoTrue/PostgREST role/tenant tests, G8 audit checklist and explicit ALL BLOCKED statuses. Source: `docs/E6M_FUNCTION_SOURCE_REVIEW_20261012.md`, gate workboard: `docs/E6G_PARALLEL_ACCEPTANCE_REGISTER_20261012.md`. No schema or role changes, CX1 queued, T2.4 paused.

**Active E6L priority and gate preparation:** Read-only local metadata-only `scripts/qa/e6-function-trust.mjs --local` checks 19 selected E6 SECURITY DEFINER functions: all local postgres owned/BYPASSRLS, 0 anon EXECUTE, 0 authenticated EXECUTE on seven trusted-only routines, no untrusted CREATE in inspected searched schemas. All 19 explicitly set `search_path=public,auth` but omit explicit last `pg_temp`; ordinary roles can CREATE TEMP. **Code-level source/security review remains pending**, no exploit demonstrated. In parallel, prepare independent G1–G10 evidence and real GoTrue/PostgREST staged witness matrix without inventing signatures or creating user accounts. See `docs/E6L_PRIVILEGED_FUNCTION_OWNERSHIP_AND_GATES_20261012.md`. Human gates remain BLOCKED; no shared DB/production/T2.4 writes.

**Completed E6K checkpoint:** audited real local public-marketplace RLS/grant metadata without reading provider records: anonymous SELECT currently covers 18/18 profile and 23/23 service columns, including unstructured `metadata` and coordinates where RLS allows a row. New rollback-only source test 058 **17/17 PASS**; combined E6H+four-T2.4 disconnected PostgreSQL **181/181 PASS**. **Privacy decision is still OPEN**: approve public-safe projection before revoking public table SELECT and migrating the Client/embedded REST queries. No shared database or application changes; E6-G1–G10 still blocked. See `docs/E6K_PUBLIC_MARKETPLACE_RLS_AND_PRIVACY_BOUNDARY_20261012.md`.

**Historical E6J checkpoint (superseded by E6K above):** P0/E-01 selected **read-only catalog baseline**, 19 selected SECURITY DEFINER functions/20 operational RLS tables, with review items for public marketplace SELECT and temp-schema search paths; **not** a whole-system certificate. P0/E-02 five-migration disposable PostgreSQL integration **164/164 PASS** across eight suites; shared database unchanged. **Next:** independently review RLS/column exposure and definer function ownership/search-path privilege assumptions; E-03 signed-in GoTrue/PostgREST matrix design and reversible staging approval. See `docs/E6J_TRUST_CATALOG_AND_CROSSSTREAM_QA_20261012.md`. T2.4 functionality remains paused.
