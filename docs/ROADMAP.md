# Wantok Services — Living Roadmap

**Updated:** 2026-10-13

## Owner commercial direction — vendor-funded marketplace; community/social DEFERRED (13 October 2026)

**Decision status: OWNER PRODUCT DIRECTION RECORDED; DESIGN/BACKLOG ONLY. No new runtime capability, payment integration, acceptance or release is claimed.**

- [x] **Vendor-funded unified commission model (owner clarification, 13 October):** Customers pay vendors directly using cash, mobile money, bank or mutually agreed means. **One standard commission policy applies to all qualifying product sales AND service bookings**, including goods, transport, food, delivery, trades and hire. Charge the same final approved rate, within the proposed **2–3% range**, to verified successfully fulfilled transaction value; **do not assign distinct percentage rates by category**. The final single percentage and precise commissionable base (discounts, GST, delivery, mixed orders, partial fulfilment, returns/refunds and milestones) remain to be approved. No commission for browsing, enquiries or transactions not fulfilled.
- [x] **Prepaid commission rule:** A vendor funds a **non-transferable platform-fee account** before taking chargeable bookings. Reserve sufficient commission for accepted priced bookings, finalise deductions on verified completion, release on qualifying cancellation. When available funds are exhausted/insufficient, **disable new chargeable bookings until a verified top-up**, while preserving already accepted work, records and disputes. A top-up is not automatically earned revenue.
- [x] **Payment separation:** Wantok does not require customer-to-vendor payments to pass through its platform. Vendor commission funding is separate from customer payments and advertising budgets. Potential top-up routes: approved CellMoni/BSP merchant arrangements, verified business bank deposits/transfers and later authorised cash outlets or single-use vouchers, subject to commercial/legal and automated reconciliation design. **No provider API/merchant access is asserted.**
- [x] **Vendor growth services:** Paid, distinctly labelled in-app sponsored placements plus optional vendor marketing, TikTok/YouTube/other external campaigns, creative services, analytics and future business plans. Platform ranking must retain relevance, quality and safety, not secretly substitute payment for trust.
- [x] **Service sourcing:** Wantok may coordinate requests beyond registered providers only with an advance agreed commission/referral/coordination arrangement; third-party customers and providers do not incur an undisclosed retrospective fee. Structured customer requests and quotation workflows are future designs, not implemented entitlements.
- [x] **Free Public Services RETAINED:** Emergency & Safety, Health, Government and Community information remain a separate no-commission, non-ad-gated public-interest directory. Verify official contact information; no claim of live emergency dispatch or government integration. Preserve existing module activation/admin rules.
- [x] **Social/community feed MUTED/DEFERRED:** Do not build a general-purpose social feed, social posting/comments, unsolicited public hiring threads, recommendation network, follower system, or video-sharing feature in the current roadmap execution. Keep the idea documented for a separately authorised later phase with anti-bypass/commission leakage analysis, moderation, safety/privacy and funding case. This does **not** disable Public Services or paid vendor promotions.
- [ ] **Future gated implementation:** Legal/tax review and approved vendor terms, commission definition and ledger controls, provider top-up verification, booking reservation/completion/dispute/refund rules, anti-fraud/RLS, reporting and a small real-world pilot before funding-scale claims. Record measured activation, retained paying vendors, top-up recurrence, completed GMV/commission revenue and conversion from free public-services traffic; do not invent traction.

**Programme sequencing unchanged:** P0 E-series security/Operations remains externally gated, CX1 real browser/mobile acceptance remains OPEN, T2.4 PAUSED, G1–G10 0/10 approved, production/E7+/provider payment activation blocked. No code, schema, entitlement, API, social UI, staging or deployment work is authorised by this documentation entry. Detailed clarification: `docs/ROADMAP_FILLERS.md` FILLER-2026-10-13-05 and later unified-rate decision FILLER-2026-10-13-06.

## CX1D local :3000 deployment for acceptance, with rollback (13 October)

- [x] User identified port `:3000` still served the old invisible Track Refresh. Verified old JS SHA `2207D8BB...`, local Supabase auth at `127.0.0.1:54321` healthy, old configured `10.186.22.64:54321` unreachable.
- [x] Backed up **96/96** currently served files with old hash at `D:\Wantok_Project_Backups\wantok-client-3000-pre-cx1d-20261013`. Rebuilt CX1D source with isolated private config changing only Supabase URL to local loopback. Existing Git config and credentials not modified/committed.
- [x] Controlled local-only static server transition: locked directory refused initial swap without corruption; second attempt stopped only verified Client PID 35016, staged directory swap with old version retained, restarted port 3000 as PID 19096. HTTP HTML **200**, new JS SHA `C7EA377A8B5B540D18311B20F3D44B8645728DB3F1B314614DA5519A1D4B47B0` verified, Auth health and CORS OPTIONS **200**. Port 3300 unchanged.
- [ ] Owner Chrome hard reload **required**. Capture actual corrected Track Desktop before/after Refresh and three 320px mobile cases; **do not count static delivery, CORS or compilation as authenticated browser acceptance**. CX1 2/6 visual checks to date, formal human acceptance OPEN, E6 security 0/10 approved, T2.4 PAUSED, production blocked.

## CX1D — Track Refresh visibility fix after owner browser walkthrough (13 October)

- [x] Owner's signed-in screenshot pairs visually confirm Saved Desktop stable at one QA provider and Inbox Desktop stable at 0 service/1 help after Refresh; **two of six user-witnessed visual checks**, not full machine-certified acceptance.
- [x] Track Desktop Refresh white-on-light-grey bug reproduced from user screenshot and source: `_TrackRefreshHeader` absolute button lay outside compact green hero but retained white translucent styling. Fix background solid `Color(0xFF096B4B)`, no route/booking mutation. New 320/390/1440px contrast+tap test, focused **11/11 PASS**.
- [x] Full isolated source QA: **7 Flutter analyses clean; Client 135/135, Operations 43/43, Technical 38/38 widget tests PASS**. Report `docs/CX1D_TRACK_REFRESH_VISIBILITY_FIX_20261013.md`.
- [x] Built and verified separate loopback-only corrected Web preview `127.0.0.1:3301`, JS served SHA-256 `219C9C2D5D81D8098230C95D6C94D4C45FE7CEE56F815451F2F7CA66BCC2FE4B`, original `:3000`/`:3300` unchanged. No credentials exported or real browser signoff claimed.
- [ ] The Client browser static builds at `:3000`/`:3300` still serve the pre-fix bundle. **Track Desktop actual after-Refresh, all three mobile tests and independent human signoff remain OPEN** until authorised fresh preview/build and user test; no production deployment or T2.4 resume.

## CX1C — six-case browser witness contract in independent parallel worktree (13 October)

- [x] Worked independently of CX1B's two Client static servers and release-checker changes: detached QA at `D:\Wantok_CX1C_Parallel_Witness_QA_20261013`, four new disjoint source/doc files, integrated after verified CX1B `1f364f9` without overwriting main work.
- [x] Added tracked `docs/CX1C_BROWSER_REFRESH_WITNESS_MATRIX_20261013.json`: six real signed-in Saved/Inbox/Track mobile 320px and desktop 1440px cases, all **NOT EXECUTED**. Known Saved-to-Vendor-Onboarding browser anomaly **UNRESOLVED**.
- [x] Added source-only `scripts/qa/cx1-browser-witness-preflight.mjs` and synthetic tests **13/13 PASS**, requiring actual authorised window/session, labelled centre-click, before/after route and count, no unexpected vendor redirect, private evidence hash and independent reviewer identity before human review. Any fake approval/invalid evidence blocks; machine cannot sign off. Baseline CLI returns exit 2 **NOT READY**.
- [x] Full untouched app Flutter source in detached worktree: seven clean analyses and **132 Client / 43 Operations / 38 Technical** widgets PASS (exit 0). No auth Chrome interactions or app/server changes.
- [ ] Next: independent operator-assisted actual authorised Chrome browser centre-click witness at `:3000` on both viewports and full private evidence recording. **CX1 gate OPEN**, E6 G1–G10 0/10, T2.4 PAUSED, E7+/production blocked.

## CX1B — restored isolated Client Web and scoped readiness checks (13 October)

- [x] Verified original and saved labelled-Refresh Client web bundles are **exact byte matches**, `main.dart.js` SHA-256 `2207D8BBCCC5BE261B7C7A77498F4E801829E0D7B13378F56B61A06F3E3B2E66` (4,099,079 bytes) plus equal Taxi/Public Services image hashes. Started read-only loopback static servers `:3000` and `:3300`, did not overwrite code or restart Operations/Technical services. Auth health anonymous GET on local `:54321/auth/v1/health` HTTP 200, no customer data accessed.
- [x] Added `-ClientOnly` support to `scripts/qa/verify-cx1-local.ps1`; actual Client-only endpoint/Javascript/label/photo integrity **CX1_CLIENT_RELEASE_QA_PASS**, which does **not** attest full five-port staging, authenticated browser or actual route clicks. Extended synthetic offline guard to **6/6** PASS including Client-only positive and staging JS/photo negative cases.
- [x] Cross-stream safeguards: fresh unchanged Flutter source at `91bd630`, **7 analyses**, Client **132/132**, Operations **43/43**, Technical **38/38** widgets PASS; disconnected SQL **301/301 in 16 suites** PASS with rollback and removed container; synthetic JWT 23/23, independence 106/106, evidence 101/101 and E6S privacy PASS.
- [x] Documented operator-only signed-in Saved/Inbox/Track Refresh witness steps and private local static process boundaries in `docs/CX1B_CLIENT_LOCAL_WEB_RESTORATION_AND_ACCEPTANCE_20261013.md`.
- [ ] Actual signed-in Chrome centre-click, routes/counts, previous Saved-to-Vendor-Onboarding mystery, Android/HONOR and six licensed category photos/editor **OPEN**. CX1 acceptance unsigned, E6 G1–G10 0/10, T2.4 paused, production blocked.

## CX1A — read-only client acceptance preflight + release-guard reliability (13 October)

- [x] Resumed after E6Z at `5bb7c74` with programme sequencing intact. 11 October real signed-in Client Services → Specialist Services → Morobe → Lae QA provider/detail and limited Saved/Inbox/Wallet observations remain **historical**, not freshly reproduced; known wrong-route Saved-to-Vendor-Onboarding click cause is NOT established.
- [x] Found all five local Web shells `3000/3100/3200/3300/3400` unreachable from EAGLT02 and expected Android emulator absent. No service restarts, user session/Cookie reads, app deployments or data writes. New signed-in Web refresh and Android/HONOR acceptance **BLOCKED**.
- [x] Fixed false-positive asset hash/parity `PASS` on failed HTTP requests in `scripts/qa/verify-cx1-local.ps1`; missing adb metadata now explicit FAIL. New **3/3** synthetic offline PowerShell-mocked tests PASS (all available, all missing, only Client main.js missing). Corrected actual read-only preflight now returns `CX1_RELEASE_QA_FAIL count=17` with no false JS/parity success lines.
- [x] Added `docs/CX1A_READONLY_ACCEPTANCE_PREFLIGHT_20261013.md` distinguishing historic signed-in evidence, fresh source/host results, and pending real-browser/real-device witness.
- [x] Full source-only cross-stream regressions: guard **3/3** mocked synthetic, clean detached Flutter **7 analyses/132 Client/43 Operations/38 Technical** widgets PASS; disposable SQL **301/301** across 16 suites, rolled back/removed; synthetic HTTP **23/23**, E6 independence **106/106**, evidence **101/101**, privacy source/local PASS. Persistent shared `db:test` not claimed green.
- [ ] When existing authorised Client app/session is **actually available**, witness three labelled centre-click Refresh controls on desktop/mobile, unchanged route/count and no Vendor Onboarding; verify main/staging hashes, Android/HONOR and six licensed inactive-category photographs with separate authorised editorial steps. **CX1 not signed off**, E6 externally blocked, T2.4 paused, production sealed.

## E6Z — security decision register and reversible-stage review gates (12 October)

- [x] Added machine-readable `docs/E6Z_REMEDIATION_DECISION_REGISTER_20261012.json` with **6** separately classified findings and **8** unsigned/blocked prerequisites: E6O-01 existing internal writer ACLs, future table TRUNCATE, future function and sequence default grants, API candidate vs live RPC route, E6S privacy D1–D5.
- [x] Added source-only `scripts/qa/e6z-decision-pack-check.mjs` and synthetic tests **12/12 PASS**. Fail-closed integrity check rejects invented G7/G8 approval or stage authority, missing blocker, modified E6O two-function source REVOKE, and false production approval. No privileged action.
- [x] Documented independent stages, backup/restore, true owner/role/default ACL parity, separate real GoTrue/PostgREST and notification worker witnesses in `docs/E6Z_SECURITY_REMEDIATION_DECISION_AND_STAGE_READINESS_20261012.md`. Postgres semantics: defaults affect future objects; `TRUNCATE` is not covered by RLS; **no new migration created**.
- [x] Full eligible QA: corrected E6Z validator **12/12**; disconnected seven-proposed-migration SQL **301/301** over **16** suites with rollback/container cleanup; E6 auth **23/23**, independence **106/106**, evidence **101/101**, privacy validators PASS; unchanged detached Flutter source **7 clean analyses**, **132 Client / 43 Operations / 38 Technical** widgets PASS. No shared combined db:test PASS asserted.
- [ ] All external acceptance unresolved: G7 **31/31 NOT EXECUTED**, G1–G10 **0/10**, privacy D1–D5 unsupplied, shared local internal writer grants OPEN; CX1 queued, T2.4 paused, E7+/production sealed.

## E6Y — default privilege and intended API/RPC exposure inventory (12 October)

- [x] Added `scripts/qa/e6y-default-acl-rpc-contract.mjs` for source config + READ ONLY local PostgreSQL `aclexplode(pg_default_acl)` and exact 14-function result/SQL EXECUTE survey; **12/12 synthetic classifier tests PASS**. No HTTP, GoTrue, user record or SQL modification.
- [x] Checked-in API schemas `public`, `graphql_public`; `auto_expose_new_tables` unset with checked-in fallback comment, not confirmed runtime. 14 selected functions have SQL anon/auth EXECUTE; 13 **possible non-trigger candidates for independent RPC review**, not 13 published/exploitable RPCs.
- [x] Observed 27 local default ACL records; for new `postgres`-created `public` objects, explicit client-role grants cover **2 future function EXECUTE**, **16 future table privilege** (including **2 TRUNCATE**) and **6 future sequence** entries. These defaults DO NOT change already-existing objects. Report `docs/E6Y_DEFAULT_PRIVILEGE_AND_RPC_EXPOSURE_CONTRACT_20261012.md`.
- [x] Regressions: E6Y synthetic **12/12**, previous E6V/E6W source/metadata scans, disposable pending migration SQL **301/301** in 16 suites, synthetic HTTP **23/23**, independence **106/106**, evidence **101/101**, E6S privacy PASS; detached unchanged Flutter **7 analyses, Client 132 / Operations 43 / Technical 38 widgets PASS**, exit 0. No persistent SQL change or G7/G8 acceptance.
- [ ] High-priority independent risk treatment: both **existing** E6O-01 writer grants remain OPEN; future-object defaults and exact production-equivalent PostgREST/RLS/worker security contract need separate approval. G7 31/31 pending, G1–G10 0/10, D1–D5 open; CX1 queued, T2.4 paused, E7+/production blocked.

## E6X — G8 catalogue parity fingerprint and fail-closed stage comparison (12 October)

- [x] Added `scripts/qa/e6x-g8-parity-snapshot.mjs` for **one local PostgreSQL READ ONLY metadata transaction**: exact selected 14 definer functions, grants/owners/search path and function comparison digests; all public table/column ACL+RLS and 117 policy hashes; default ACLs, role memberships, extensions, PG version. Local PostgreSQL **17.11**, **93/93 RLS**, **0 FORCE RLS**, **27 default ACL entries**; no user rows/function source exports.
- [x] Added `scripts/qa/e6x-g8-parity-snapshot.test.mjs`: **13 synthetic tests** PASS for equality-without-approval, owner/grant/policy/RLS-version/default-ACL drift, broken fingerprint, missing arrays, duplicate identities and nonzero CLI failure for detected drift. Stored baseline is local private `.wantok/` only. SHA-256 metadata digest `97f56f9cd16e8b7aa69b2aed90f9a0c3d019a77ad50ed68cad766791419da113` (not externally attested).
- [x] Prepared source-controlled `docs/E6X_G8_METADATA_PARITY_SNAPSHOT_AND_STAGE_READINESS_20261012.md` with restricted-snapshot procedure and independently gated stage stop/go fields. Exact migration ledger, real PostgREST routes, authentic GoTrue sessions, worker notifications, backups and G8 independent sign-off **remain NOT SUPPLIED**.
- [x] Regressions: `13/13` E6X comparator cases, `301/301` network-disabled SQL (16 suites, fixture rollback), `23/23` synthetic HTTP negatives, `106/106` E6 independence, `101/101` evidence, E6S privacy source/local validators, and fresh detached unmodified Flutter **7 analyses / Client 132 / Operations 43 / Technical 38** widget tests all PASS. Combined persistent shared `db:test` not green while proposed migrations unapplied.
- [ ] E6O-01 local writer grants still OPEN; no persistent change, production approval or claim of production-equivalent parity. G7 **31/31 NOT EXECUTED**, G1–G10 **0/10**, D1–D5 unresolved. E P0 active, CX1 queued, T2.4 paused, E7+ sealed.

## E6W — latest declared privileged caller and installed local trust snapshot (12 October)

- [x] Added `scripts/qa/e6w-installed-caller-trust.mjs` with source-only and **READ ONLY** local PostgreSQL catalog modes; scanned 77 migrations, parsed 227 dollar-quoted declarations, narrowed **16 historical** writer-calling definitions to **12 latest-by-name** audit-writer caller candidates. Regex matching and pending SQL are not a full installed call graph.
- [x] Found **14/14** installed local selected function signatures with `SECURITY DEFINER` and BYPASSRLS `postgres` owner; installed Boolean body-regex matches for all 12 selected audit callers, zero notification direct caller references. SQL EXECUTE on all 14 selected is effective for `anon` and `authenticated`; API exploitability not established.
- [x] New `docs/E6W_INSTALLED_CALLER_TRUST_AND_G8_PARITY_WORKSHEET_20261012.md` maps distinct Operations, Technical, branding, category, trigger and notification continuity checks and future exact signature/ACL/role/RLS/REST parity evidence. **No staged data, approvals or migration deployment**.
- [x] Source-only and local catalog scanner PASS; isolated SQL **301/301** (16 suites), synthetic auth **23/23**, E6 independence **106/106**, evidence **101/101**, E6S privacy validators PASS; clean detached baseline Flutter QA **7 analyses and Client 132 / Operations 43 / Technical 38 widgets PASS**. Shared `db:test` is not green because pending migrations remain unapplied.
- [ ] **E6O-01 remains OPEN** on shared-local writer grants, G7-31 real witness remains NOT EXECUTED; G7 **31/31 blocked**, G1–G10 **0/10 approved** and E6S privacy D1–D5 unresolved. E-series active, CX1 queued, T2.4 paused, E7+/production sealed.

## E6V — internal writer dependency compatibility inventory (12 October)

- [x] Added reproducible non-mutating `scripts/qa/e6v-internal-writer-dependency-map.mjs` across 77 SQL migrations and app JS/TS/Dart: 9 migrations match, **16 historical audit-writer candidate nested calls**, **0** notification writer SQL calls and **0** app named writer references. Lexical/historical only, not live call graph, route analysis or proof that a worker is unused.
- [x] Mapped candidate audit dependencies: status-change trigger, role/Technical mutators, public service controls, branding and category updates. Checked presence of E6O corrective source, **not** deployed. Source evidence `docs/E6V_INTERNAL_WRITER_DEPENDENCY_AND_STAGE_COMPATIBILITY_20261012.md`.
- [x] Revalidated disconnected 16-suite SQL **301/301**, local read-only E6U privilege catalogue, synthetic HTTP **23/23**, E6 independence **106/106**, E6S privacy-contract validators, evidence **101/101**, and *detached unchanged Flutter app source* **7 analyses + 132/43/38 widget tests** exit 0. Main working-copy Flutter attempts met a shell variable/locked build artefact; no existing directory deletion.
- [ ] Independent approved dedicated stage must verify **actual** inner-call/definer-owner rights, PostgREST untrusted direct denials, authorised nested audit continuity and real notification worker enqueue/delivery after mitigation. Proposed **G7-31 NOT EXECUTED**; G7 **31 total**, G1–G10 **0/10 APPROVED**. E6O-01 open; CX1 queued, T2.4 paused, production blocked.

## E6U — G8 role/ACL preflight and trusted worker continuity (12 October)

- [x] Read-only `npm.cmd run test:e6u:parity-preflight-local` inventories ten selected privileged functions (two internal writers + eight E6S role helpers): **10/10 BYPASSRLS owners**, **2/2 shared writers still untrusted SQL EXECUTE** in local DB; `public` **93 tables / 93 RLS enabled / 117 policies / 0 forced RLS**. **No user data**, no exact stage parity implied.
- [x] New `066_postpatch_trusted_audit_worker.test.sql` **7/7** confirms `service_role` can still create a synthetic audit record after E6O restriction in disposable SQL, anon/auth denied; rollback. Separate pre/post exact two-function fingerprint proves owner/SQL body/search settings invariant during E6O GRANT change.
- [x] E6U full regression: seven Flutter analyses + Client **132**, Operations **43**, Technical **38** widget cases PASS; E6S privacy-proposal and read-only catalogue checks PASS, local JWT HTTP negatives **23/23**, case independence **106/106**, evidence **101/101** PASS. No externally witnessed G7 sign-in.
- [x] Network-disabled seven pending migration integration now **16 SQL suites / 301/301 assertions PASS**, all fixtures/container removed, shared DB unaffected; Technical T2.4 used for compatibility only, still PAUSED.
- [ ] Stage parity: true backed-up production-equivalent owner/ACL/RLS/REST key and worker configuration, witnessed trusted notification/audit and G7 direct anonymous signed-in denials, privacy D1–D5 plus G1–G10 signatories. Added G7-30, **30/30 cases NOT EXECUTED/BLOCKED**; **G1–G10 0/10 approved**. No E6U SQL migration or production deployment.
- Report `docs/E6U_G8_PRIVILEGE_PARITY_AND_TRUSTED_WORKER_CONTINUITY_20261012.md`.

## E6T — Trust-boundary positive SQL reproduction and expanded callability audit (12 October)

- [x] Local pg_catalog `READ ONLY` classification shows **152** `public` SECURITY DEFINER functions, 95 anon SQL EXECUTE, including **6 trigger-return and 89 non-trigger-return**. SQL EXECUTE does not mean published PostgREST access; classify by real route and owner/role parity with independent G8.
- [x] Isolated new rollback-only `065_prepatch_audit_writer_reproduction.test.sql` **8/8 PASS**: before proposed E6O grant fix, synthetic `anon` actually inserted an audit-event row via definer; rolled back, no source DB writes. After E6O stage migration, existing `061` **14/14** direct denials PASS. **E6O grant fix is still UNAPPLIED to shared database**.
- [x] E6T focused QA: E6S draft contract and read-only metadata tests PASS; synthetic JWT HTTP **23/23**, E6 independence **106/106**, evidence **101/101**. Detached Flutter complete **7 clean analyses, 132 Client / 43 Operations / 38 Technical widget tests PASS**, exit 0 after supplying missing test-shell `ProgramFiles(x86)`; no app source changed.
- [x] Disconnected E6T E6H/T2.4/E6N/E6O regression **7 source-only migrations / 15 suites / 294/294 pgTAP PASS**, fixtures rolled back, container removed and source DB intact. No new E6T migration or Technical implementation.
- [ ] G8 independent security + staging proof to verify actual REST callable route, legitimate audit worker, role/owner/ACL parity, rollback, provider public privacy and approved role metadata D1–D5 before persistent change. New G7-29 planned real-session audit-write-denial witness **NOT EXECUTED**; G7 **29 total**, G1–G10 **0/10 approved**.
- Evidence: `docs/E6T_PRIVILEGED_SQL_CALLABILITY_AND_PREPATCH_AUDIT_REPRO_20261012.md`. Programme P0 E ACTIVE, G PREP PARALLEL; CX1 queued, T2.4 paused, E7+ sealed.

## E6S — Role-helper proposed API contract, migration-impact and staged acceptance (12 October)

- [x] Machine-readable **PROPOSED, not approved** `docs/E6S_ROLE_PRIVACY_CONTRACT_PROPOSAL_20261012.json` specifies exact eight currently callable role/Technical helpers, separate anonymous vs self/delegated vs trusted internal outcomes, five D1–D5 independent decisions, signed human approvals **0/10**.
- [x] E6S full validation: eight-helper contract source and READ ONLY local catalog **PASS**; disconnected stage **286/286** over 14 SQL suites, main synthetic auth negative **23/23**, independence **106/106**, evidence **101/101**, Flutter **7 clean analyses + 132/43/38 widget tests** PASS. Shared DB unchanged, real GoTrue witnesses absent.
- [x] Reproducible `npm.cmd run test:e6s:privacy-contract` source-only and `test:e6s:privacy-contract-local` PostgreSQL **READ ONLY** catalog parity validators check eight function signatures/return types, current definer status, owners and EXECUTE grants, without touching user records or HTTP.
- [x] `docs/E6S_ROLE_HELPER_PRIVACY_AND_STAGING_READINESS_20261012.md`: scoped migration-impact matrix for Operations RLS, Technical, Flutter, Taxi/booking and role workflows; **S-01..S-09 dedicated-stage preflight** requires approval, backup/restore, owner+ACL+RLS parity, independent GoTrue/REST witnesses, cleanup and signed go/no-go.
- [ ] **G8 D1–D5 all NOT SUPPLIED**: confirm whether role/rank is sensitive metadata, define exact API isolation, approve safe nested/RLS contract and negative/positive stage evidence before ANY privacy migration. E6K/E6O/E6R findings stay OPEN.
- [ ] Real G7 **28 cases NOT EXECUTED**; G1–G10 **0/10 independently approved**; no persistent SQL migrations, accounts, production or T2.4 work.
- Report: `docs/E6S_ROLE_HELPER_PRIVACY_AND_STAGING_READINESS_20261012.md`.

## E6R — Role metadata callsite inventory and G8 decision pack (12 October)

- [x] Read-only local pg_catalog check confirmed **eight selected definer role helpers** have effective `anon`, `authenticated` and `service_role` EXECUTE with local postgres owner; never assume this proves HTTP exploit/actual production grants.
- [x] Source-only lexical map `scripts/qa/e6-role-helper-callsite-map.mjs`: **77 checked-in migrations / 242 historic helper-call references / 19 variable-subject matches / 1 named Dart source call**. Explicitly excludes straightforward grant DDL but counts superseded SQL; not current executable call graph. Traced delegated taxi `is_admin(v_user_id)` to `v_user_id := auth.uid()` caller-bound identity.
- [x] Added synthetic rollback-only `064_role_helper_anon_disclosure_reproduction.test.sql` **18/18**: `anon` direct SQL can see other fake users' admin/Technical entitlement through explicit UUID but cannot issue roles. **G8-04 role metadata exposure OPEN**, no source mitigation yet.
- [x] E6R full regression: **286/286** isolated SQL, **23/23** signed-synthetic HTTP negatives, **106/106** independent case tests, **101/101** evidence tests; Flutter **7 clean analyses, 132 Client/43 Operations/38 Technical widgets PASS**. No shared DB writes or GoTrue G7 approvals.
- [x] Disconnected seven-migration integration **14 SQL files / 286/286 assertions PASS**, fixtures rolled back/isolated container removed, shared persistent DB untouched.
- [x] Prepared D1–D5 independent G8 privacy/compatibility/go-no-go decision pack and extended **G7 26 → 28 NOT EXECUTED/BLOCKED** cases, including anonymous direct REST and real user/cross-user helper comparison. G1–G10 **0/10 formal approvals**.
- [ ] Dedicated stage and G8 reviewer to confirm direct PostgREST exposure, current function/RLS owner ACL, lawful field contract and least-privilege migration before promotion. E6O writer privileges and E6K marketplace disclosure still open.
- Reference `docs/E6R_ROLE_METADATA_CALLGRAPH_AND_G8_DECISION_PACK_20261012.md`.

## E6Q — Role-helper cross-principal trust/metadata boundary (12 October)

- [x] Source review: `has_role`, `is_admin`, `is_technical_platform_admin`, platform/module helpers accept subject IDs; **subject's** authority must not be mistaken for calling principal. RBAC `admin` remains distinct from `tech_platform_admin`.
- [x] Synthetic `063_role_helper_cross_principal_boundary.test.sql` **25/25 PASS** under four fake rollback-only user IDs: positive permitted family grants, denial of cross-family admin grants/revocations, ordinary actor cannot elevate privileges. **Other-user role metadata is visible through explicit helper subject IDs**: logged as E6Q-G8-04 **candidate information-disclosure/privacy decision**.
- [x] Full E6Q regression: disconnected SQL **268/268** across 13 suites; synthetic HTTP negatives **23/23**; E6 independence **106/106**; evidence scanner **101/101**; Flutter `check.ps1` **7 clean analyses and 132/43/38 widgets** PASS. No shared DB, Technical source or production change.
- [x] Cross-stream disconnected PostgreSQL **7 migrations, 13 SQL files, 268/268 tests PASS**, shared database untouched, disposable records fully rolled back. No new E6Q database migration, Technical control/source unaffected.
- [x] Extended G7 parallel real GoTrue/REST witness matrix **23 → 26**, adding explicit other-user helper privacy, distinct cross-role delegated sign-in, expired/revoked/legacy role. All **NOT EXECUTED/BLOCKED**; formal G1–G10 remain 0/10 approved.
- [ ] G8 independent role metadata/API exposure policy, exact stage privilege/owner/RLS parity, full 152 definer call graph and E6O writer mitigation. Separate genuine GoTrue-positive and negative G7 witness checks need authorised staging.
- Report `docs/E6Q_ROLE_HELPER_CROSS_PRINCIPAL_BOUNDARY_20261012.md`.

## E6P — Privileged role control negative regression and real G7 witness readiness (12 October)

- [x] Reviewed current checked-in source-level caller guards for nine sensitive role, Technical-module, branding and service-category mutators; explicit `auth.uid()` and relevant administrator/scoped permission checks present (not full authorisation proof).
- [x] Added `062_privileged_role_control_anon_denials.test.sql` **23/23** synthetic pgTAP assertions: four definer invariants, nine anonymous direct denied calls, five authenticated-DB-role NULL-identity denials and five no-effect checks. **Not** a real GoTrue positive/negative acceptance test.
- [x] Fresh E6P regressions: disconnected SQL **243/243**, main synthetic HTTP negative **23/23**, E6 case-independence **106/106**, evidence **101/101**; detached Flutter `check.ps1` exit **0**, **7 clean analyses + 132/43/38 widget tests** PASS. Shared/production DB untouched.
- [x] Re-ran seven unapplied source migrations in disconnected disposable PostgreSQL: **12 pgTAP suites / 243/243 PASS**, fixtures rolled back, container removed and source DB untouched. No new E6P migration, Technical grants/source unaffected.
- [x] Extended independent **G7 witness case plan from 18 to 23**, with G7-19–G7-23 testing actual unrelated logged-in actor denials, different role-family positive authorisations, Technical module RPCs, category/branding reviewer separation and the E6O shared writer mitigation. **All 23 NOT EXECUTED/BLOCKED**; G1–G10 **0/10 signed**.
- [ ] Independently verify authenticated staff role scope, full 152-function definer call graph/owner ACL, E6O-01 untrusted writer grants, E6O-02 Technical health route and E6K public metadata in backed-up dedicated stage; G8 security review and owner signatures still pending.
- Evidence `docs/E6P_ROLE_ADMIN_CONTROL_NEGATIVES_AND_G7_WITNESS_PLAN_20261012.md`.

## E6O — Complete public definer inventory + trusted internal RPC boundary (12 October)

- [x] New read-only, reproducible public PostgreSQL `SECURITY DEFINER` inventory: **152 functions** (versus 19 earlier E6 selection), **95 anon EXECUTE**, **133 authenticated EXECUTE**, **152 BYPASSRLS-owned**; audited only catalog metadata, no private rows/secrets. All have configured search_path; shared local DB still has 0 explicit trailing `pg_temp` because previous source migration remains unapplied.
- [x] Identified **E6O-01** potential privileged internal RPC ACL exposure: both `write_audit_event` and `enqueue_notification` have untrusted grants despite source intending service-role only. Proposed source-only `20261012152000_e6_shared_internal_rpc_execute_boundary.sql` revokes untrusted EXECUTE while preserving service-role; no live application/DB changes.
- [x] Full E6O regression: **220/220 SQL**, `061` **14/14** direct role/ACL cases; local synthetic JWT negative HTTP **23/23**, E6 independence **106/106**, evidence scanner **101/101**, fresh **7 Flutter analyses + 132/43/38 widgets** all PASS. No live test identity, shared SQL migration or production write.
- [x] Network-disconnected disposable tests now **7 source-only migrations / 11 suites / 220/220 assertions PASS**, including new `061` negative direct SQL calls under anon/authenticated, unchanged E6N 19-function fingerprint and shared DB untouched. Staging fixtures are *not production ACL/owner parity*.
- [ ] **E6O-02** `record_technical_module_health_report_internal` is locally untrusted-callable: independent G8 owner/Technical owner to investigate. **T2.4 source/grants remain untouched** under programme pause.
- [ ] Independent G8 reviewer must audit remainder of 152 privileged functions, nested call-graph, untrusted REST RPC exposure, service-role handling, exact staged owner/ACL and public provider-field contract before any live mitigation. **G1–G10 all BLOCKED, G7 18 planned cases NOT EXECUTED**, CX1 queued.
- Source report: `docs/E6O_FULL_PUBLIC_DEFINER_SURFACE_AND_INTERNAL_RPC_GUARD_20261012.md`.

## E6N — Selected SECURITY DEFINER path hardening and G-series readiness (12 October)

- [x] Added **source-only, unapplied** E6 migration `20261012140000_e6_operations_definer_search_path.sql` for **19** explicit function `pg_temp` last paths; no body, owner, grants, role or RLS changes and no shared DB migration.
- [x] Focused regression: local synthetic signed-JWT HTTP negatives **23/23**, E6 independence **106/106**, evidence scanner **101/101**, E6L read-only function catalogue baseline PASS; independent GoTrue and G1–G10 external gates remain blocked.
- [x] Full detached E6N Flutter check exit **0**: 7 analyses clean and **132 Client, 43 Operations, 38 Technical** widget tests PASS. No deployment or witnessed browser sign-in.
- [x] Added new pgTAP test `060_operations_definer_temp_path.test.sql` **25/25 PASS** and extended disconnected E6/T2.4 compatibility harness to **6 migrations, 10 test files, 206/206 assertions PASS**. The first run identified missing test-only ACL restoration; corrected fixture grants; verified staged function body/owner/ACL fingerprint unchanged and shared DB untouched.
- [ ] Independent G8 security owner to audit **all** related privileged function call graphs, function-owner parity, temp/operator/type name resolution and public-field privacy restrictions; real G7 auth/bypass tests on separately approved staging.
- [ ] Continue G1–G10 preparation **in parallel** with safe E engineering; 0/10 gates approved. G10 last, E7+/payments/provider activation/production blocked.
- [ ] Dedicated backed-up staging approval before applying even E6N migration beyond disposable QA. Detailed `docs/E6N_SEARCH_PATH_HARDENING_AND_GATE_READINESS_20261012.md`.

## E6M — Source-defined trusted SQL and parallel G1–G10 acceptance (12 October)

- [x] E6M regression: **19 selected latest definer source definitions PASS** under static lexical guards; **181/181 disconnected SQL** tests PASS, **23/23 synthetic HTTP negatives**, **106/106 E6 independence**, **101/101 evidence**, **7 clean Flutter analyses**, **132/43/38** app widget tests PASS. No GoTrue witnessed acceptance; shared DB remains unchanged.
- [x] Reproducible source-only latest-definition scan across 19 selected E6 SECURITY DEFINER functions: 19 explicit `search_path`, 0 simple unqualified relation refs and 0 explicit dynamic SQL EXECUTE. Corrected regex false positives for `IS [NOT] DISTINCT FROM` and `ON CONFLICT DO UPDATE SET`. Two latest E6H definitions not on shared local DB. **Static review only**: nested privilege, temporary schema, owner, real authenticated G7/G8 checks still OPEN.
- [x] Separate G1–G10 independent acceptance workboard with required reviewer roles, dependencies, blank protected evidence refs, **18 NOT EXECUTED** real GoTrue/REST cases and precise G8 reviewer checklist. **G1–G10 all BLOCKED**; G10 remains last.
- [ ] Independently check full function call graph + all related SECURITY DEFINER overloads, temp schema path hardening in disconnected owner-equivalent stage, exact ACL/RLS, trusted key custody, recorded privacy field-contract approval.
- [ ] Gather real external staff, legal, geography, COI, security, signed-in witness and DR evidence into separately approved private records; no synthetic code test can sign them off.
- Detailed `docs/E6M_FUNCTION_SOURCE_REVIEW_20261012.md` and `docs/E6G_PARALLEL_ACCEPTANCE_REGISTER_20261012.md`.

## E6L — Privileged function trust + G1–G10 concurrent evidence readiness (12 October)

- [x] Read-only local `pg_catalog` audit of **19 selected SECURITY DEFINER** E6 functions: all `postgres` owned/BYPASSRLS, 0 anon EXECUTE, 0 authenticated EXECUTE on seven trusted-only routines, 19 explicit paths, 0 normal-schema CREATE rights for anon/auth; `pg_temp` suffix absent on all 19 and TEMP allowed — **needs function-body/temp-name audit**, not proven exploit.
- [x] Re-ran E6L regressions: detached Flutter **7 clean analyses**, **132 Client / 43 Operations / 38 Technical** PASS; disconnected SQL **181/181 PASS**; local auth **23/23**, E6 independence **106/106**, evidence **101/101** PASS. No migrations applied.
- [x] Prepared gate-by-gate G1–G10 independent evidence queue; designed separate real GoTrue/PostgREST role, tenancy and legacy bypass matrix; staged authorisation/backups/owner-parity checklist. **Preparation is not approval**: G1–G10 all BLOCKED.
- [ ] Inspect actual checked-in function bodies for unqualified relations/types, dynamic SQL, JWT identity source and definer bypass; propose safe `pg_temp` ordering and owner/ACL hardening in **disposable role-equivalent stage**, test before migration.
- [ ] Real witnessed test accounts and independent G7/G8 review only after explicit dedicated staging approval; legal/HR/COI/DR sign-offs under G1–G10; E7+ locked.
- Evidence: `docs/E6L_PRIVILEGED_FUNCTION_OWNERSHIP_AND_GATES_20261012.md`; human gate source of truth `docs/E6G_FORMAL_ACCEPTANCE_RUNBOOK_20261011.md`.

## E6K — Public marketplace disclosure and RLS boundary (12 October; SOURCE QA)

- [x] Read-only PostgreSQL policy and per-column anonymous exposure audit: verified active profiles and services remain RLS restricted, `anon` has no table mutation rights, but **18/18 provider-profile** and **23/23 provider-service** columns are SELECTable when a public row qualifies. Eight address/coordinate/metadata fields require privacy review. No real data rows read.
- [x] New transaction-rollback `058` synthetic RLS matrix **17/17 PASS** (active/verified vs draft/inactive, own unpublished vs cross-provider, visible public metadata risk).
- [x] E6H + four Technical migrations combined **181/181 pgTAP PASS** across nine suites in disposable disconnected staging; original shared DB unchanged. Test-only owner/grants are not production ACL parity.
- [ ] Independently approve explicit public field/metadata privacy policy, migrate public Client/embedded REST reads to a safe projection, and **then** narrow `anon` SELECT privileges in dedicated approved, backed-up staging. Avoid breaking public discovery, provider ratings and structured filters.
- [x] Full E6K clean detached Flutter `scripts/flutter/check.ps1` passed exit 0: 7 analyses, Client 132, Operations 43, Technical 38.
- [x] Revalidated unchanged main code's local synthetic-JWT HTTP negatives **23/23 PASS**, E6 independence **106/106 PASS**, evidence scanner **101/101 PASS**. These are **not** witnessed real GoTrue identities.
- [ ] Actual GoTrue/PostgREST privilege and signed-in browser witness, exact definer-owner/ACL parity, maintained legal/HR/COI approval and DR sign-off; E6-G1–G10 BLOCKED. Details: `docs/E6K_PUBLIC_MARKETPLACE_RLS_AND_PRIVACY_BOUNDARY_20261012.md`.

---

## PROGRAM PRIORITY OVERRIDE — E-series → CX1 → T2.4 (12 October; SINGLE CHAT)

**Owner decision:** continue all three workstreams here, **strictly prioritised**: **P0 E-series Enterprise/Operations security and governance**, followed by **P1 CX1 Client Experience completion**, then **P2 T2.4 Technical Control**. Previous T2.4 commits are preserved, but **further T2.4 implementation is PAUSED**. This header supersedes outdated historical text below that presented T2.4 as the active next task; historical milestones and test evidence remain factual.

- [x] **P0 E6J initial read-only inventory:** 19 selected E6 functions and 20 operational tables audited; all selected RLS enabled and explicit function search paths. Public marketplace SELECT grants on `provider_profiles`/`provider_services` and implicit temp-schema ordering require independent review, not automatic vulnerability claims. Zero database writes.
- [x] **P0 E6J five-migration isolated integration:** pending E6H plus **four** T2.4 source migrations tested together: **164/164 pgTAP** across 051/052/056/057/090/091/092/093; all synthetic fixtures rolled back and shared database unchanged.
- [ ] **P0 E-series next:** independently review policy/column exposure, function-owner and SECURITY DEFINER search-path decisions, prepare real role-bound GoTrue/PostgREST staging witness and documented backup/restore approval; the persistent full 61-file database suite remains blocked by unapplied migrations. Details `docs/E6J_TRUST_CATALOG_AND_CROSSSTREAM_QA_20261012.md`.
- [ ] **P0 formal E6-G1–G10:** independently witnessed staff delegations, two-person grants, ISO country/subdivision and sector legal sources, beneficial-owner COI, real GoTrue/PostgREST/browser roles, revocation, independent security audit, DR and owner approvals. **All remain BLOCKED. E7+ production/KYC/activation stays gated.**
- [ ] **P1 CX1F/CX1 acceptance:** reproduce blank-keyword signed-in Web provider category → Morobe → Lae → storefront/detail/Saved; prove Saved/Inbox/Track Refresh stays on correct route, Account/Wallet/Agent read-only flows; verify six inactive category photographs/editor, Android/HONOR and owner visual evidence. Distinguish previous signed-in Android PASS from unverified Web/browser clicks.
- [ ] **P1 CX1 closure:** collect direct evidence and explicit CX1 owner acceptance. E6 formal external blockers must remain visible, but do not prevent separately safe read-only CX1 QA after P0 engineering is exhausted. Do not turn CX1 acceptance into E6 security sign-off.
- [ ] **P2 T2.4:** after earlier priorities, resume real central-log provenance/retention/redaction and genuine worker heartbeat; job actions remain disabled pending specific approval. Four Technical SQL migrations remain unapplied to shared DB. T2.4E source tests **58/58**, clean Flutter 7 analyses and 132/43/38 widgets; not a live collector or release.

**Working register and dependencies:** `docs/PROGRAM_EXECUTION_PLAN_20261012.md`. Shared `docs/HANDOVER.md`, `docs/ROADMAP_FILLERS.md`, `AGENTS.md` and database require one writer; only this conversation coordinates work going forward. Preserve source, other worktrees and `supabase/snippets/`. No user/customer changes, online VM, payments or release approval.

---

## T2.4E — Centralised log-source readiness contract (12 October; CODE ONLY)

- [x] Introduced metadata-only trusted source registry with safe provenance ticket, bounded retention and non-connected state; no collector or credential fields and no live event ingestion.
- [x] Added protected reduced per-module readiness RPC, typed Flutter repository, and explicit unconnected status in the Technical Control Logs page. No false worker or central log claims.
- [x] T2.4 isolated staging now verifies four additive migrations and **58/58 pgTAP assertions**, rolls back synthetic fixtures and leaves shared Supabase unchanged.
- [ ] Independently identify actual source collectors, verify provenance/redaction/retention and worker heartbeat, audit and performance before authorising any ingestion. Perform real GoTrue/PostgREST sign-in acceptance under production-equivalent ownership/ACL.
- [ ] Full 61 SQL suites in an approved backed-up staging after E6H/T2.4 migrations; formal E6/Operations and Technical security gates, no online VM or production deployment. `docs/T24_CENTRAL_LOG_SOURCE_READINESS_20261012.md`.

---

## E6I — Integrated E6H/T2.4 disposable SQL staging (12 October; PASS, NOT DEPLOYED)

- [x] Applied pending E6H plus three T2.4 migrations together only to a network-disabled, no-port disposable PostgreSQL clone containing schema and seven non-personal reference tables.
- [x] Seven pgTAP suites **145/145 assertions PASS** (051/052/056/057/090/091/092); synthetic records rolled back, isolated container deleted and shared Supabase unchanged.
- [ ] Full persistent database SQL migration/test still blocked until separately authorised backup, exact owner/ACL parity, controlled migration sequencing and signed-in GoTrue/API browser acceptance. Isolated test grants are *not* production parity.
- [ ] E6 staff authority, official country classifications, COI and formal G1–G10 approvals remain pending; E7, live vendor activation, sensitive identity evidence and production VM prohibited. See `docs/E6I_ISOLATED_CROSSSTREAM_INTEGRATION_20261012.md`.

---

## T2.4 — Module-scoped Technical Activity audit (12 October; SOURCE QA PASS)

- [x] Reuse `audit_events` safely via a separate, bounded read-only module action-history RPC: explicit `module.view` + `module.logs` PostgreSQL permission, allowlisted action/entity pairs, module-key equality, no actor/target/metadata/customer payload. Distinguish activity from central/container logs.
- [x] Add typed Technical Activity page with fixed safe labels and read-only Refresh; 6 new widget tests PASS. Updated isolated staging script applies three T2.4 migrations and **39/39** SQL assertions PASS; full seven Flutter analyses / 132 Client / 43 Operations / 34 Technical tests PASS.
- [ ] Full shared SQL runner is still blocked by separately unapplied E6H 057 and T2.4 090–092 migrations. Exact staging ownership/ACL parity, signed-in API/browser role matrix, audit retention/source-integrity/large-table query review and controlled migration sequencing OPEN. No live deployment, job actions or online VM.
- [ ] Continue safe central log-source design and real worker-health adapters, then separately approve auditable and idempotent operational job actions. `docs/T24_SCOPED_TECHNICAL_ACTIVITY_20261012.md`.

## T2.4 — Reproducible isolated staging SQL acceptance (11 October; QA PASS, LIVE MIGRATION OPEN)

- [x] Added disposable, no-network/no-port Postgres staging runner `scripts/qa/t24-isolated-staging.ps1`, schema-only + five non-personal technical registry tables. Both T2.4 RPC migrations apply together only in isolated `t24_stage`, with **25/25 SQL negative/privacy assertions PASS**, fixture rollback, source DB unchanged and automatic container cleanup.
- [x] Clean Flutter source validation **7 analyses / 132 Client / 43 Operations / 28 Technical widgets PASS**. Record `docs/T24_ISOLATED_STAGING_INTEGRATION_20261011.md`.
- [ ] Full default shared 58-file SQL suite remains BLOCKED by **unapplied** T2.4 migrations 20261011240000 and 20261011241000; distinguish that from the isolated 25/25. Stage clone uses test grants, not exact production ownership/ACL parity.
- [ ] Prepare independent backed-up real staging with exact grants, authentication/PostgREST role acceptance, E6H migration compatibility and full 58-file SQL suite. Keep online VM, run/retry/cancel jobs, payments, service activation and production release closed.

## E6H — Enterprise self-review and clearance read independence (11 October; CODE QA ONLY)

- [x] Explicitly block enterprise applicant from gaining internal case scope on their own application even when granted reviewer, evidence or safety duties.
- [x] Block identity reviewer/final approving officer from reading their original vendor clearance through a later investigator grant; preserve independent safety review.
- [x] Rollback-only local tests **106/106 PASS** across 051/052/056/057, with zero persistent local schema or sample data changes; detached E6H checkout seven Flutter analyses, **132 Client / 43 Operations / 28 Technical widgets PASS**. `docs/E6H_INDEPENDENT_INTEGRATION_QA_20261011.md`.
- [ ] Apply E6H to designated environment only after separately owned T2.4 migration compatibility/backups are approved; rerun full combined SQL suite.
- [ ] Formal E6 human/witness gates G1–G10 and E7/VM production authorisation remain OPEN. Detail `docs/E6H_ENTERPRISE_CASE_INDEPENDENCE_20261011.md`.

---

## E6G — Formal acceptance checks (11 October; human sign-off pending)

- [x] E6-only SQL 56 files / 1,139 assertions PASS and evidence 101/101 PASS; combined 57-file SQL runner blocked by separately owned T2.4 migration not yet applied.
- [x] Added read-only local REST/JWT negative acceptance checks: 23 of 23 passed; zero users or records created.
- [x] Documented ten formal human witness gates in `docs/E6G_FORMAL_ACCEPTANCE_RUNBOOK_20261011.md`.
- [ ] Independently verify authority, country codes, conflicts, signed-in user-role scenarios and recovery evidence before closing E6.
- [ ] Do not advance production deployment or E7 without explicit accepted sign-off.

## E6D–F — Dual staff approval, staged case isolation & COI (11 October; CODE PASS, FORMAL SIGN-OFF OPEN)

- [x] Separate country-authorised provisioning requester from independent approver and subject; enforce country/subdivision/category, 366-day maximum expiry, audited grant/revoke, pending does not confer authority, no implicit administrator duties.
- [x] Restrict legacy staged-provider triage/verification and evidence planning/metadata RLS to independently classified, active scoped case/evidence officers; keep applicant reads and non-uploading intents. Wire staged queue/checklist/evidence action separation into restricted Operations tabs. Seal old resource activation moderation.
- [x] Add staff self-declared and independently recorded immutable case recusal; PostgreSQL case-scope checks deny reviewer, evidence or investigator privileges after a conflict is recorded.
- [x] Validate existing provider/driver and listing activation column-level grants and RPC denials; ensure profile owner cannot change verification flags through direct SQL.
- [x] Local three migrations PASS, **56 pgTAP files / 1,139 assertions PASS**, evidence safety 101/101 PASS, new staff authorisation 5 widget tests PASS, full Operations **43/43 PASS** and app analyzer clean. Detached `0ad0fde` QA passed **7 analyses / 132 Client / 43 Operations / 22 Technical widgets**. See `docs/E6DEF_INTEGRATED_SECURITY_ACCEPTANCE_20261011.md`; package/GitHub proof separate.
- [ ] **Formal E6 sign-off open:** real verified independent staff delegation and key custody; official source provenance for country subdivision/classification; COI/business relationship review; controlled signed-in multi-user browser matrix; security/recovery and E6 release runbook approval.
- [ ] E7–E12 separately gated; no production/online VM deployment, KYC issuance, documents, vendor activation or money movement. Detail `docs/E6D_E6F_DUAL_STAFF_STAGED_CASE_RECUSAL_20261011.md`.

---

## T2.4 — Server-scoped health-transition log adapter (11 October; SOURCE/SQL QA PASS)

- [x] Create an additive authenticated RPC for technical module log reads: require both module.view + module.logs, cap to 30 newest transitions, suppress untrusted summary/probe-key content and permit only the assigned module.
- [x] Wire Technical Logs to the new server-enforced adapter, without adding raw log/queue/action privileges. Transactional migration + 12 pgTAP negative/read tests **PASS**, complete rollback confirmed. Seven analyses / 132 Client / 38 Operations / 22 Technical widgets **PASS** on isolated T2.4 code.
- [x] Commit `0ba95ef` and verify GitHub feature branch, full Git-bundle backup and verified source-only Linux release archive; subsequent combined E6D/T2.4 checkout `0ad0fde` full Flutter check PASS (seven analyses, 132 Client / 43 Operations / 22 Technical). **Migration not applied** to shared development DB; port 3600 still serves the previous preview.
- [ ] Audit original `list_technical_module_health_history` broader view-only API, implement separately authorised central/module log provider contracts and queue metadata adapters, then carefully approve executable jobs and dedicated audit trail. Full migrated SQL suite and authenticated UI acceptance remain OPEN. `docs/T24_SCOPED_HEALTH_LOG_ADAPTER_20261011.md`.

## T2.4 — Technical Diagnostics, Logs and Jobs (11 October; FIRST READ-ONLY MILESTONE)

- [x] Owner-authorised **start** of T2.4 after reporting 8/8 CX1 manual checklist items complete. Preserve the difference between owner attestation and independently witnessed browser/HONOR evidence; CX1 photographs remain inactive without database image paths.
- [x] Wire per-module Diagnostics, Logs and Jobs cards in Technical Control. Diagnostics shows existing server-scoped health/probes/dependencies; Logs only existing bounded health transitions (not central logs); Jobs clearly reports that no queue adapter is connected and makes no fabricated counts or calls. Module capability-gated read-only screens, safe retry and no raw exception data.
- [x] Isolated 390/1200px capability/refresh/no-actions/error tests **6 PASS**; full 7 Flutter analyses / 132 Client / 38 Operations / 22 Technical widgets PASS; local DB 52 files / 1,043 assertions PASS. No migration, live application deployment, account/category changes or VM interaction.
- [ ] T2.4 remaining: real central/module log adapters with redaction and server enforcement, queue metrics with provenance/freshness, explicitly approved scoped job execution/cancel/retry with immutable audits and high-risk dual control, and distinct richer technical audit queries. Browser staging acceptance separate. `docs/T24_READONLY_OBSERVABILITY_FOUNDATION_20261011.md`.

## E6C1 — Clearance safety and legacy activation guard (11 October; LOCAL PASS, E6 OPEN)

- [x] Scoped `safety_investigator` access to existing verified case / region / service family, and checked clearance provider ownership against the original applicant; replaced broad admin reads and emergency revoke access.
- [x] Preserve atomic revocation/pause/audit, deny prior reviewer/approver conflict, introduce server-role-only emergency stop for unclassified historic providers, keep expiry maintenance service-only.
- [x] Reject all `active` transitions through legacy admin service-status RPC and seal old provider accept/reject decision; no new clearance or payment is issued.
- [x] Restrict safety staff to isolated Operations safety tab; local SQL migration PASS, **52 files / 1,043 assertions PASS**; Operations analysis clean and **38 widgets PASS**.
- [ ] Continue E6: independent dual-authorised staff provisioning, broad staged/provider RPC audit, signed-in multi-role browser checks, extended COI and official jurisdiction-source proof. Clean `8604ea2` checkout passed seven analyses / 132 Client / 38 Operations / 16 Technical tests; evidence safety 101/101 PASS. Package and GitHub proof reported separately in `docs/E6C_INDEPENDENT_INTEGRATION_QA_20261011.md`.
- [ ] E7–E12 remain gated; no VM deployment or operational identity/evidence access. Detail `docs/E6C_SCOPED_CLEARANCE_SAFETY_20261011.md`.

---

## E6C — Clearance monitoring and emergency safety (11 October; HISTORICAL SOURCE REVIEW, SUPERSEDED BY E6C1)

- [x] Audit existing broad-admin clearance-status listing, emergency revoke/audit, provider service transitions and old provider review functions; record case-to-provider binding risk and test design.
- [ ] Implement a fail-closed, independently scoped safety-investigator path for classified cases, retaining a trusted service-only emergency stop for unclassified legacy cases.
- [ ] Prevent new activation before E9, preserve expiry maintenance, add negative pgTAP and signed-in UI isolation acceptance.
- [ ] **Implementation blocked:** remote tool safety checks rejected the proposed SQL file write; no migration or tests were applied in this checkpoint. E6 remains open. See `docs/E6C_CLEARANCE_SECURITY_REVIEW_20261011.md`.

---

## CX1 — Safe Technical category image staging (11 October; CODE PASS, BROWSER OPEN)

- [x] Retain selected image locally until explicit **Save category**, so Cancel does not orphan a storage upload; show selected preview and validate image file extension, header and 3 MiB maximum before initiating the existing authorised upload.
- [x] Test cancellation (zero storage/SQL calls), exactly-once upload-and-save of an inactive draft, unsupported extension and spoofed signature with injected callbacks. Full isolated E6B/CX1 integration PASS: seven Flutter analyses and **132 Client / 37 Operations / 16 Technical** suites.
- [ ] Actual signed-in Technical browser select/cancel/upload/replace, Web/Android photo parity and the six distinct editorially approved draft photographs; do not activate categories. Server-side cleanup for upload-success/save-failure remains an unapproved hardening task.
- [ ] Signed-in Client Refresh browser acceptance and physical HONOR remain open; T2.4 Diagnostics, Logs and Jobs DEFERRED. Evidence: `docs/CX1_CATEGORY_PHOTO_STAGING_20261011.md`.

## E6B — Case-jurisdiction, verification and evidence metadata (11 October; CODE PASS, E6 OPEN)

- [x] Maintain verified jurisdiction and service-family classification separately from applicant free-text region, with trusted registry, service-role-only changes and durable case events. **No automatic old-case classification.**
- [x] Enforce signed-in `case_reviewer` and `evidence_officer` duty at PostgreSQL RLS and RPC boundaries for enterprise vendor intake, events, preliminary verification and metadata-only evidence requests/cancellation.
- [x] Preserve applicant read/response, two-person preliminary procedural review, and deny global admins, wrong province/category, unknown cases and expired/revoked grants without a matching authorised duty.
- [x] Add isolated Operations staff tabs and read-only/action separation for evidence-only and reviewer-only accounts; fix intake Flutter setState refresh bug. SQL locally **51 files / 1,008 assertions PASS**, plus Operations static analysis clean and full **37/37 widget tests PASS** (three new restricted-role UI cases).
- [ ] Remaining E6: clearance/read/revoke, legacy provider services and staged provider routes, officially sourced ISO mapping and two-person staff provisioning approvals, full COI/case assignments, browser signed-in negative journey and integration/packaging.
- [ ] E7+ remain gated, **no upload, final KYC, activation, payment or VM deployment**. Detail `docs/E6B_CASE_JURISDICTION_SCOPED_REVIEW_20261011.md`.

---

## CX1 — 320px Refresh navigation regression (11 October; TEST PASS, BROWSER OPEN)

- [x] Add 320px Saved/Inbox/Track click and read-only reload cases and six 320/1440px route-observer tests to ensure Refresh stays on its Flutter screen. Clean CX1 baseline: 16 expanded tests + six route safety tests PASS; seven Flutter analyses and complete Client/Operations/Technical widget suites PASS.
- [x] Re-test against E6A scoped Operations RBAC in a fresh worktree: seven analyses, 132 Client, 34 Operations, 12 Technical widget tests PASS; active checkout Technical temporary-build Windows lock separately documented, no forced clean-up.
- [x] Repeat read-only local release parity: five HTTP 200 shells, matching main/staging bundles and unchanged shared artwork, existing emulator build 4010. No redeployment or user data mutation.
- [ ] Authenticate and visibly exercise Saved/Inbox/Track Refresh in an identified Chrome Client window at desktop and narrow sizes; avoid unrelated sessions and speculative root-cause fixes. Signed-in Android, HONOR, category photography and safe Technical image workflows still open. CX1 IN PROGRESS; T2.4 DEFERRED.
- Evidence: `docs/CX1_REFRESH_ROUTE_SAFETY_QA_20261011.md`.

## E6A — Country-scoped internal policy duties (11 October; IN PROGRESS)

- [x] Add isolated country/subdivision/category/expiry staff duty grants; deny unauthorised self-provisioning and grant administration; preserve existing roles and database content.
- [x] Replace Phase 2E broad administrator policy access with RLS and server-checked author/reviewer duty scopes, explicit COI recusal and independent review; existing draft/revision state machine remains non-operative.
- [x] Add restricted scoped-compliance entry in Operations without admitting its officers to full administrator menus; preserve Client and Technical applications.
- [x] Local migrations applied; database 50/973 PASS, Node evidence 101/101 PASS; Operations analysis clean, 34 widgets PASS.
- [x] Detached isolated checkout at `e6c8594` passed all 7 Flutter analyses, 122 Client / 34 Operations / 12 Technical widgets without disturbing the locked live Technical build folder. Source release `wantok-vps-e6c8594f3b08.tar.gz` verified (64 migrations, SHA-256 recorded in E6 handover). Feature commit `e6c8594` matched the remote GitHub branch after normal fast-forward push; **not deployed to VM**.
- [ ] E6 remaining: vendor intake/verifications/evidence/revocation scoped RPCs and case-bound RLS; approved role provisioning and additional COI/independence rules; signed-in multi-user/browser negative tests; full cross-app regression and package verification.
- [ ] E6 migration of legacy admin staff to explicit scopes requires authorised provisioning. **No automatic all-country grandfathering.** No uploaded IDs, final KYC, vendor activation or VM deployment.
- Detail: `docs/E6_SCOPED_OPERATIONS_POLICY_DUTIES_20261011.md`.

---

## CX1 — Clearly labelled refresh actions and responsive tap QA (11 October)

- [x] Convert Saved, Inbox and Track icon-only refresh affordances into visible labelled **Refresh** buttons with 48px minimum tap targets, accessibility tooltips and stable UI test keys. Existing read-only owner-scoped data paths and concurrency guards retained.
- [x] Test actual button-centre taps (not merely widget existence) in 12 responsive Saved/Inbox/Track tests; complete seven Flutter analyses and all widget regression suites PASS in detached QA worktree.
- [x] Build and deploy Client Web release to `:3000` / staging `:3300` after SHA-checked rollback and source-candidate snapshot; no Technical/Operations deployment.
- [x] Matching offline-demo Android x64 build **4010** independently SHA-256 checked, installed in place over 4009 and launched, original app firstInstallTime retained. No signed-in or physical-device acceptance inferred.
- [ ] Signed-in browser visual and click acceptance must wait until EAGLT02 Windows desktop is unlocked. Do not access account passwords or falsely claim Web runtime click acceptance because tests passed.
- [ ] Physical HONOR, signed-in Android and six inactive service-family photo approvals and image-upload editor still open. CX1 IN PROGRESS; T2.4 DEFERRED.

## 11 October — ENTERPRISE DELIVERY PROGRAMME & RELEASE READINESS (CURRENT OWNER PRIORITY)

**Latest owner instruction:** Complete the outstanding enterprise security, compliance, trust, Helpdesk and cross-platform acceptance work on **EAGLT02**, but design every increment to remain **versioned, packageable, installable and upgradeable** on a Linux VM. **Do NOT deploy, synchronise or reinstall on the online VM until the owner separately authorises it.** This roadmap checkpoint is documentation/handover only; subsequent feature work belongs to the **next chat**. Start there with `docs/START_NEXT_CHAT_20261011.md` and `docs/ENTERPRISE_RELEASE_READINESS_GATES.md`; retain all earlier CX1 and T2.4 scope without false completion claims.

### Accomplished — local foundation / explicitly not production-ready

- [x] **E1 — Individual & business vendor intake:** category-dependent transport/vehicle/licence, food, trades and machinery metadata; case traceability, contact/location and owner/staff read scoping; Operations review queue. Identifiers remain deliberately partial and documents are not accepted.
- [x] **E2 — Two-person preliminary review:** separately assigned procedural reviews per checklist item, mandatory reasons and audit, information requests/withdrawal; no final KYC decision or provider activation.
- [x] **E3 — Evidence safety foundations:** applicant-bound status preflight always denies upload; limited evidence-request register; isolated scanner/quarantine/custody synthetic lab and service-role-only current manifest comparison; emergency clearance revocation pauses active listings. No production upload/key custody/ID verification.
- [x] **E4 — International policy proposal management (Phase 2E):** country + optional province/state code, service category, privacy notice draft, purpose and unverified legal basis, proposed retention/evidence fields, **mandatory preview**, internal submission, independent administrative review, immutable numbered revisions and audit. All states non-operative; no legal release or consent is implied.
- [x] **Local E4 evidence:** `npm.cmd run db:test` **49 files / 937 assertions PASS**; Operations `flutter test --no-pub` **33 tests PASS**, analyzer clean, Web release build successful and `:3200` served feature checks. Not production, signed-in real-user regulatory acceptance or a penetration test.
- [x] **E5 packaging foundation:** `deploy/vps/` source installer, versioned additive migrations, separate secret/runtime data, release-builder/verifier, backup/upgrade helpers; checked SHA-256 source tarball `.wantok/releases/wantok-vps-af632329546c.tar.gz` (**62 migrations; 11,685,311 bytes**). No VM rehearsal and no production sign-off. The package is a source release, not self-contained offline installer.

### Next engineering sequence — DO NOT mark complete prematurely

- [ ] **E6 (FIRST IN NEXT CHAT) — Country-scoped RBAC and staff trust policy.** Define distinct `policy_author`, `policy_reviewer`, `evidence_officer`, `final_approver`, `safety_investigator`, scopes `country_code`/subdivision/category, least-privilege read/write and immutable actor/decision audit. Replace broad all-country `is_admin` for sensitive paths through additive, backward-compatible migration only after contract review. Negative tests must prove cross-country and same-person actions fail.
- [ ] **E7 — Legally approved notice/consent engine.** Maintain ISO country/subdivision catalogue and locale-specific legal references; require explicit jurisdictional approval, content version/hash, purpose and expiry, user-facing informed consent/withdrawal, data rights, deletion/legal hold and separate effective-date controls. Existing `internal_review_complete` is **not** legal approval.
- [ ] **E8 — Hardened private document admission/custody.** Authenticate sessions, scanner freshness and sandbox, size/type/rate/anti-replay, private encrypted Storage with managed KMS keys, atomic off-host custody, audit, retention and restore drills. Public upload/storage access remains **disabled** until all security gates clear.
- [ ] **E9 — Real KYC/verification and clearance.** Review evidence against authorised government/company/licence/vehicle/insurance sources, verify applicant roles/beneficial ownership and expiry, independent legal/Compliance final approval with denial/appeal, revocation, re-review and maintenance schedule. Never convert procedural review or evidence-request acknowledgement into an activation flag.
- [ ] **E10 — Dedicated enterprise Helpdesk and trust incidents.** Ticket/case states, complaint/SLA/priority queue, assignment, escalation, safety/fraud/regulatory incidents, auditable contact history, restricted attachments, applicant appeals, reporting and on-call ownership. Existing Support Inquiries is not enterprise Helpdesk.
- [ ] **E11 — International production capabilities:** country/region/city provider discovery and restrictions; sector-specific qualifications; currency/tax/time-zone/language/accessibility, anti-fraud, payment and settlement reconciliation; full browser/API/Android/HONOR and multi-role acceptance; critical observability, encrypted off-host backups and DR.
- [ ] **E12 — Release hardening & Linux staging rehearsal:** dependency/image pinning/signatures, SBOM, isolated config/secrets, verified backup/restore/upgrade/downgrade runbooks and monitoring. **Wait for explicit VM test/deployment authorisation; owner said not now.** Never deploy from local `.wantok` data or copy test users into production.
- [ ] **CX1 remaining, tracked in sections below:** actual Web refresh click acceptance for Saved/Inbox/Track; signed-in Android and physical HONOR; approved distinctive pictures and real Technical category image CRUD for six inactive categories; release and visual acceptance. **CX1 IN PROGRESS.**
- [ ] **T2.4 deferred:** Technical Diagnostics, logs and jobs after the owner authorises the appropriate phase; do not treat completed compliance work as starting or completing T2.4.

**Quality gate for every future task:** preserve existing roles, data and category imagery; no uncontrolled activation/payments; update tests/documentation; capture tested Git commit; push only reviewed files to GitHub; maintain source release compatibility. Do **not** bundle unrelated parallel `supabase/snippets/` or private screenshots. See `docs/INTERNATIONAL_VENDOR_POLICY_GOVERNANCE_PHASE2E.md`, `docs/WANTOK_VM_RELEASE_PACKAGING.md` and `docs/START_NEXT_CHAT_20261011.md`.

---

## CX1 — Repeatable read-only local release parity gate (11 October)

- [x] Add scripts/qa/verify-cx1-local.ps1: verify localhost ports 3000/3100/3200/3300/3400; Client and Technical staging/main JS hashes; real Taxi/Public Services pictures; compiled Saved/Inbox/Track refresh labels; optional existing Android package version. Never authenticate to user APIs or mutate data.
- [x] Validate EAGLT02 five HTTP responses, matching main/staging JS, photographs, Android 4009. Fail-closed test requiring version 999999 returned exit 1 without changing emulator state.
- [ ] Controlled signed-in real browser click acceptance for the Saved, Inbox and Track refresh controls. Current served bundle has all labels; previous real screenshots do not establish the actual buttons or interactions. Do not assume cache staleness as the root cause.
- [ ] HONOR physical device, signed-in Android, and six inactive category photographs with actual Technical picture-upload lifecycle remain open.
- **T2.4 (after CX1)**: Diagnostics, logs and jobs — adapters for diagnostics/logs, background job/queue visibility, approved job actions and richer audit views. Not started by this CX1 checker. T2.4 DEFERRED.

## CX1 — Actual signed-in Web read-only journey acceptance (11 October)

- [x] Authenticated live Client Web Track displayed existing completed QA record without editing it.
- [x] Authenticated live Wallet displayed K0.00 preview with inactive payment rails; no transaction attempted.
- [x] Authenticated Inbox displayed Services (0) and one previously existing owner-private Open QA help request; no write/reply.
- [x] Authenticated Wantok Agent showed provider-search and human-help entry points, explicitly **AI chat not connected**; no handoff submitted.
- [x] Account → Saved reopened after a FULL hard Chrome reload and retained the existing QA provider bookmark. Same-session post-reload visibility PASS, not account logout/login or multi-device persistence.
- [ ] Browser click acceptance of Saved, Inbox and Track toolbar refresh actions in an isolated/focus-stable window. An attempted Saved toolbar click landed on vendor onboarding; no data was changed and automation was stopped. Do not mark this passed from source/widget tests.
- [ ] Physical HONOR, signed-in Android, six inactive categories' PNG/Pacific art and actual Technical category-image upload lifecycle. CX1 IN PROGRESS; T2.4 DEFERRED.

## CX1 — Authenticated Saved and Inbox/Track usability (11 October)

- [x] Signed-in real Client Web Account → Saved displayed the previously saved QA provider; no add/remove action. Category-first Specialist Services → Morobe → Lae and provider detail were already accepted.
- [x] Add accessible Refresh Inbox and Refresh activity in the existing enterprise green headers, with guarded read-only reloads on mobile and desktop. Six new focused widget cases plus the complete seven-analysis Flutter regression PASS.
- [x] Promote matching Client Web build to 3000 and Client staging 3300 with full independent SHA-verified recovery copies; keep Technical 3100 and Operations 3200 unchanged.
- [x] Deploy matching offline-demo Android emulator build **4009** in place (adb install -r Success, firstInstallTime unchanged, app launched). SHA-256 E6E529939F6F44D938BD98F94DDF5CA57C72288B7D63081B047576DBF08DB06F, APK D:\Wantok_Project_Backups\wantok-client-cx1-inbox-track-android-preview-4009-20261011.apk. This is not signed-in Android or physical HONOR acceptance.
- [ ] Verify post-browser-reload Saved account collection and actual signed-in Inbox, Track, Wallet and Wantok Agent views. Input was blocked after the reload, so those live gates remain OPEN.
- [ ] Physical HONOR, signed-in Android, media CRUD and six inactive categories' distinct PNG/Pacific photo approvals. CX1 IN PROGRESS; T2.4 DEFERRED.

## CX1 — Saved read-only Web usability / Android parity (11 October)

- [x] Add **Refresh saved items** toolbar button in authenticated Account → Saved page, preserving original pull-to-refresh and Retry and all existing bookmark write permissions. Repeated overlapping refresh requests are suppressed.
- [x] Validate six isolated widget cases: pre-existing provider list, actual toolbar reload at mobile and desktop widths, empty state, error/retry. Full clean Flutter regression PASS across seven analyses and all existing Client, Operations and Technical tests.
- [x] Build, hash-verify and deploy matching Client Web on **3000** and independent Client staging **3300**. Full backup and candidate snapshot saved to `D:\Wantok_Project_Backups`; Technical/Operations not redeployed.
- [x] Package and install matching **Android offline-demo build 4008** in-place; APK SHA-256 backed up, original first-install time unchanged, app launched. Physical HONOR and signed-in phone mode NOT claimed.
- [ ] **Live signed-in Web Account → Saved** content/persistence acceptance still required, preferably with desktop focus isolated; do not change/remove existing bookmarks to manufacture success.
- [ ] Re-check remaining Account / Inbox / Track / Wallet / Agent read-only browser routes, physical HONOR acceptance and six inactive categories' approved PNG/Pacific artwork. **CX1 in progress; T2.4 deferred.**

## CX1 — Signed-in Client Web category discovery and Saved QA (11 October)

- [x] **Real authenticated Web primary discovery PASS** on `:3000`: Services → Browse providers → Explore providers → Specialist Services → Morobe → Lae → QA provider result/detail, **no keyword entered**. Read-only provider detail includes sourced **5.0 (1)** and approved Quote listing. Private screenshots preserved, no profile/bookings/payments changed. See `docs/CX1_WEB_DISCOVERY_ACCEPTANCE_20261011.md`.
- [x] Add four **read-only Saved page** widget acceptance cases at mobile/desktop, empty collection and Retry after a failed read; optional test loader preserves production RLS/data path. No bookmarks changed.
- [ ] Genuine signed-in browser Account → Saved collection verification, read-only. Existing green bookmark in directory is not by itself proof of Saved persistence. Browser automation safety stopped on focus changes, no blind clicks.
- [ ] Authenticated Web Account, Inbox/Support, Track, Wallet preview and Wantok Agent, plus physical HONOR acceptance and six inactive category image reviews. **CX1 in progress; T2.4 deferred.**

## CX1 — Fix Technical category picture placeholders; unify global theme (11 October)

- [x] Transfer all **23 existing category WebPs** and distinct Public Services JPG out of Client-only assets into common `wantok_ui` Flutter package, without duplicating photographs; keep the Client and Technical categories visually identical across Web/Android.
- [x] Add shared category-slug media registry and thumbnail widget to Technical. Reuse published media overrides and category-level uploaded `image_path`; use canonical shared asset as fallback. Drafts missing real pictures remain marked for upload.
- [x] Make Technical use the **global published branding theme**, and restyle category management to match main panel: engineering header gradient, cards, status tags, responsive metrics, and theme-derived accents and radii.
- [x] Isolated Flutter analyses and Client/Operations/Technical widget tests PASS; new tests confirm original Taxi/Public Services images appear on Technical and no narrow-screen overflow.
- [x] Stage/release Client and Technical Web with SHA-256, HTTP photo checks and tested recovery backups; both 3000 and 3100 promoted, 3300 and 3400 staging, Operations 3200 unchanged. Signed-in browser screenshot confirms matching pictures and theme.
- [ ] Complete separately generated **distinct PNG/Pacific-specific images for six still-inactive new categories**, only after individual editorial review. No unrelated artwork or image clones introduced by this correction.
- [x] Install and verify matching Android WebP package: x64 offline-demo versionCode **4007** upgraded in place, first-install timestamp and app data unchanged, screenshot proves shared photographic category tiles. Original Web, Android and Technical image identities remain equal.
- [ ] Continue authenticated Client provider/Saved/Account journeys and physical HONOR acceptance. **CX1 in progress; T2.4 deferred.**

## CX1 — Backend-governed categories and Technical Control editing (11 October)

- [x] Preserve previous 23 categories and records; insert 6 additional service families as **inactive drafts** (`it-electronics`, `automotive-repair`, `agriculture-farming`, `pets-animal-care`, `cleaning-maintenance`, `construction-trades`). Do not enable vendor booking or payment flows.
- [x] Add database-controlled `show_on_home`, `show_in_services`, category `image_path` columns; preserve all existing active entries, enforce admin-only RPC, audit, record locking, slug immutability and archive/delete safety. Local migration applied after full custom PostgreSQL backup. **41 files / 828 pgTAP assertions PASS**.
- [x] Remove Home's hardcoded six-card limit and duplicate Travel tile. App and Web use backend flags and source-ordered category list; Services follows its independent visibility control. New service slugs must have category-specific media, never the More image.
- [x] Implement authenticated Technical Platform Administrator **Service categories** editor (create, edit, sort, Home/Services visibility, image upload/replace, archive/remove unused draft) reusing existing immutable branded image bucket. Technical manager focused widgets PASS on desktop and mobile.
- [x] Compile Client/Technical Web releases and deploy to independently hashed staging **3300 and 3400**. No mutation of customer data or main apps during staging.
- [ ] Complete distinct realistic Pacific/PNG-themed image assets for six new service families. Generation attempt returned an unsuitable complete dashboard composite; do not insert it as a low-resolution category picture. Approve media **before enabling** any draft.
- [x] Promote verified staging builds to Client **3000** / Technical **3100**, with SHA-256 checks, immutable rollback copies and five ports HTTP 200. Authenticated Technical browser shows **Service categories** sidebar and **29 of 29 category rows**; Client Chrome Home renders the expanded backend-driven grid. Operations **3200** unchanged.
- [x] Update Android offline-demo emulator safely in place: matching Flutter build **4006**, APK independently SHA-256 verified, `adb install -r` Success, package 4006 and original user-data installation date retained.
- [ ] Real authorised browser **create/edit/archive/delete/image-upload transactions** not yet accepted; do not mutate existing production-like provider/category settings merely for testing. PostgreSQL transactional pgTAP CRUD/RBAC PASS.
- [ ] Continue CX1 Web Morobe→Lae/provider detail/Saved, Account/Inbox/Track/Wallet/Agent, physical HONOR approval. T2.4 deferred.

## CX1 11 October — Full backend category image coverage (not activation)

- [x] Audited active and inactive slugs through a **read-only PostgreSQL query**: **23 actual backend categories**, including 3 inactive. All 20 active categories already have distinct mapped photographs. Both missing media identities were inactive: `bus-coach` incorrectly fell back to More; `flights` reused `travel-flights` image.
- [x] Prepared unique photographs `category_bus_coach.webp` (bus exterior) and `category_flights.webp` (airport check-in) using separately licensed source photography and WebP cropping. Rejected image-generator outputs that contained whole-page mock-ups. Existing images preserved; provenance recorded in `docs/CATEGORY_PHOTO_ASSETS.md`.
- [x] Add canonical Flutter styles/slug routing for both inactive categories, plus a backend-category registry, avoiding duplicate artwork and incorrect More fallback. No database category state/transactions changed.
- [x] **Full independent QA PASS:** 7 analyses, 106 Client, 21 Operations, 8 Technical tests. Every one of the 23 backend photo assets loads and has unique bytes.
- [x] **Deploy shared Web and Android code:** Client Web 3000 serves both new files (HTTP 200) and has a verified rollback copy; canonical build directory re-synchronised after a denied rename. Android offline demonstration safely upgraded in place to versionCode **4005** (user data retained), APK hash backed up in `D:\Wantok_Project_Backups`. No activation of either inactive category, no change to 3200/3100/3300/3400.
- [ ] Continue authenticated CX1 Web Morobe → Lae/category details/Saved and user journeys; physical HONOR acceptance; separate Operations activation review. **T2.4 deferred**.

## CX1 11 October — Photo-forward categories and shared Web/Android media

- [x] **Public Services** plain government icon replaced by existing project PNG government-building photograph; same Flutter category media renderer on Web/mobile. No fake agency information, emergency contact or public-service state change.
- [x] **All actual service-category pictures audited:** seven unique, locally bundled Unsplash-licensed photographic WebP files added for Hotels, Education & Training, General Labour, Financial Services, Boat Hire, Errands and Venue Booking. Existing category pictures preserved. The **More** navigation entry intentionally remains an ellipsis symbol; distinct category photos are asserted in tests. Provenance in `docs/CATEGORY_PHOTO_ASSETS.md`; commercial/photo-release verification remains a separate editorial gate.
- [x] **Consistent media slots:** Web and Android Home use published Theme & Media `homeIcon` → published `cardImage` → same bundled photograph fallback. Other category cards use `cardImage` → identical bundle. Existing independent appearance settings retained.
- [x] **Visible Operations naming** changed in port directory and applicant UI without renaming internal `wantok_admin` package/RLS/roles. Existing 3200 older Operations runtime is not newly deployed or toggled.
- [x] **Full source tests PASS:** 7 Flutter analysis targets, 103 Client, 20 Operations and 8 Technical widget tests, database 38 SQL files/800 assertions.
- [x] **Web Client release on 3000:** isolated Web release build passed; public government-building image and seven WebP category assets present and respond HTTP 200; previous served files copied and hash-verified for rollback. 3300 staging untouched.
- [x] **Technical 3100 label deployed:** port 3200 labelled Operations in new Technical build with verified pre-change backup; 3400 staging untouched.
- [x] **Android offline-demo update DEPLOYED AND VISUALLY VERIFIED:** recovered emulator Package Manager by a graceful stop/relaunch without data wipe; version 3 was correctly refused as downgrade against installed build 4003, so rebuilt 4004 without app identity change. `adb install -r` Success; installed versionCode **4004**, original first-install date retained. Updated Public Services photographic Home tile and Hotels/Education/Financial/Labour catalogue photographed tiles observed in actual emulator screenshots. APK saved as `D:\Wantok_Project_Backups\wantok-client-photo-parity-android-preview-4004-20261011.apk` (SHA-256 in handover). App remains OFFLINE DEMONSTRATION; no sign-in/bookings/money. HONOR physical-device acceptance still OPEN.
- [x] **Web + Android photographic screenshot checks PASS:** Chrome Web :3000 Home now shows the Public Services government-building photograph and consistent desktop category tiles. Android offline-demo build 4004 shows the same Public Services photo and new education/hotels/labour/financial service images in its real catalogue.
- [ ] **Remaining CX1 acceptance:** owner final visual sign-off on Web and Android; HONOR physical testing; authenticated Web provider-discovery Morobe → Lae/detail/read-only Saved plus Account/Inbox/Track/Wallet/Wantok Agent. No module approval, emergency dispatch, money, live chat or provider status changes. **T2.4 deferred**.

## 11 October — Technical Control local port directory and staged delivery

- [x] Add **Local applications & ports** to the existing authenticated Technical Platform Administrator sidebar and toolbar on `:3100`, listing five distinct development/staging addresses with purposes and clickable manual-open links: Client 3000, Technical 3100, Operations Admin 3200, Client staging 3300, Technical staging 3400. No spurious online indicator, cross-device localhost routing or backend roles.
- [x] Split previously shared Client/Technical static staging directories from main: independent `D:\Wantok_Staging_Builds_20261011\{Client,Technical}`, copied/hashes checked before staging-only rebind, all expected local ports serve HTTP 200; stage builds are snapshots, not a live copy.
- [x] Validate read-only port page at 390/1200 px and link opening with simulated launcher; full isolated Flutter gate **7 analyses / 102 Client / 17 Admin / 8 Technical PASS**, pgTAP **37 files / 789 assertions PASS**. Safely compile and deploy **only Technical 3100**, retaining verified rollback copies and previous 3400 staging preview; authenticated Technical Chrome showed sidebar entry.
- [x] **Partial Client Web CX1F PASS:** signed-in `:3000` opened Services → Explore providers, kept keyword search blank, selected **Specialist Services**, and displayed existing approved QA provider with sourced 5.0 (1) rating. Current Public Services imagery also visibly rendered.
- [ ] **Remaining Client Web CX1F:** continue from category result → **province Morobe → town Lae → provider detail/Saved read-only**; then Account/Inbox/Track/Wallet/Wantok Agent, plus physical HONOR device acceptance. Foreground browser changed during QA; no force-click or sensitive-data inspection. A partial provider result does not close the full category-filter acceptance.
- [ ] Review the **Public Services** module control in Operations Admin when a separate tested Admin build is approved for deployment; do not toggle public directory or publish official emergency contacts without explicit owner sign-off. CX1 IN PROGRESS; T2.4 DEFERRED.

## 11 October CX1 — preserve new Public Services and category imagery

- [x] Verified GitHub fast-forward containing `3199499`, `6508781`, `a83d1b0`, and `7487c8c`; independent full-history source bundle `D:\Wantok_Project_Backups\wantok-services-cx1-public-media-7487c8c-20261011.bundle` passed `git bundle verify`. GitHub publication is **not a production rollout or module toggle**.

- [x] Recognise current local source commits `3199499` Public Services, `6508781` category image mapping, and `a83d1b0` shared Theme & Media appearance workflow. Do not revert to 10 October client worktree or mix Public Services informational pages with commercial booking/dispatch.
- [x] Validate new Client Web asset delivery on `:3000`: Public Services icon and photo, Emergency icon, Government photo and Specialist photo each HTTP 200; served JS includes Public Services. Technical `:3100` JS includes Theme & Media. Test environments `:3300/:3400` respond; no production release action was taken.
- [x] Database contract **37/789 PASS**, source Client **102 widget tests PASS**, Admin **17 widget tests PASS**, and all 7 Flutter analyses after a brace-only lint correction. Technical **4 tests PASS** in isolated worktree because main worktree's `build/unit_test_assets` is locked on EAGLT02; do not forcibly delete the running build directory.
- [ ] Verify new Public Services navigation and the Operations Admin module switch visually on authorised signed-in clients; leave the enabled state unchanged until owner explicitly requests a toggle. Official numbers and service links must be independently verified before publication.
- [ ] Complete **signed-in Web** Client CX1F category-first flow at `:3000` with **empty search**: Services → Browse providers → Specialist Services → Morobe → Lae → provider details/rating and Saved **read-only** state; then Account/Inbox/Track/Wallet/Wantok Agent. Windows Search was covering active Chrome during this attempted session, so browser interactions were not falsely marked PASS.
- [ ] Final visual checks of actual Android/HONOR appearance updates, mobile/tablet/browser widths and distinct icon/media slots; preserve originally supplied imagery and published-theme fallback.
- [ ] T2.4, staff replies, real chat, money, approval changes, emergency operations and production evidence intake remain gated; CX1 **IN PROGRESS**.

## CX1 primary acceptance revised: category-first provider discovery — 10 October 2026

- [x] **Category-first source QA repeated:** 7 Flutter analyses, 94 Client / 15 Admin / 1 Technical tests, PostgreSQL 35 SQL / 767 assertions PASS, plus real signed-in Android read-only interaction. No code changes or database records introduced.
- [x] **Android authenticated category-first PASS (no keyword):** EAGLT02 `emulator-5554`, Services → Browse providers → Specialist Services → Morobe → Lae → provider details, leaving free-text search **empty**; genuine eligible **Wantok QA Plumbing Services** card, sourced 5.0 (1), detail with approved **QA Plumber & Maintenance**, Lae/Morobe and Quote listing. This is category-filter functionality and does NOT restrict the whole category to plumbers. No booking/Saved/review/data mutations.
- [x] **Distinguish workflows:** Home → Specialists opens **Describe the job / Post request** (inspected but never submitted); Services → Browse providers opens the **provider directory/filter**. Do not merge or relabel one as the other without a separate UX decision.
- [x] **Keyword-specific regression remains SECONDARY:** `plumber` + category/location was already Android-tested. Future text queries for electrician/mechanic/ICT, etc. require legitimately discoverable approved records; do not manufacture them.
- [ ] **Primary Web CX1F sign-off:** at signed-in Client `:3000`, navigate Services → Browse providers → Specialist Services → Morobe → Lae **without query**, open provider detail, inspect existing read-only Saved state, then Account/Inbox/Track/Wallet/Wantok Agent. Record actual found/empty/error and authorised RLS behaviour. **Android PASS is not Web PASS.**
- [ ] **Category matrix (additional evidence, not prerequisite synthetic data):** Taxi & Transport, Home Services, Food & Restaurants, Groceries, and other current service families: confirm correct category navigation and realistic loaded/empty/unavailable states; do not infer there are approved providers. HONOR physical responsive checks remain OPEN.
- [ ] CX1 remains IN PROGRESS; T2.4 and money/approval/evidence upload/live staff reply/model gateway gates stay deferred.

## CX1I owner browser evidence and read-only queue reliability — 10 October 2026

- [x] **Authenticated Support & Inquiries queue DISPLAY PASS:** owner screenshot at `:3200` confirms signed-in page, 1 real existing Open CX1 QA handoff, UTC submission date, five filter chips and Refresh button. Neither active filter switching nor Refresh click is established by the screenshot.
- [x] **Refresh/Retry Flutter assertion FIXED:** replace Future-returning `setState` callback with synchronous assignment, ensuring errors can retry without assertion; correct 1-request singular grammar. Eight Support widget tests cover widths 390/850/1440, all five status filters, refresh re-fetch, retry recovery, previous failure/error state. No RLS/schema/business writes.
- [x] **Source validation PASS:** seven Flutter analysis targets, 94 Client + 15 Admin + 1 Technical widget tests, 35 SQL/767 pgTAP assertions, and clean source changes. No live data mutations.
- [x] **Admin-only deployment COMPLETE:** verified GitHub source commit `a69d366` and independent full-history bundle, advanced the clean detached `D:\Wantok_Web_Admin_20261010` worktree from `3342ac0` to `a69d366`, gracefully quit its original Flutter server and restarted only loopback `:3200` with the original local backend defines and sample fixtures OFF. Admin, Client `:3000` and Technical `:3100` all returned HTTP 200; emulator `emulator-5554` remains connected. Browser hard-refresh is needed to see the corrected counter; live click-through post-restart has not been observed.
- [ ] **Remaining CX1:** authenticated Client **Web** primary category-first QA (Services → Browse providers → Specialist Services → Morobe → Lae, **blank search**, provider detail/Saved/Account/Inbox/Track/Wallet/Agent); independent `plumber` text search is SECONDARY; HONOR physical/full Android visual check. Staff responses/assignments, model chat, approval/money/evidence movement remain gated; T2.4 deferred.

## CX1 functional Android evidence + Admin browser shell — 10 October 2026

- [x] **Authenticated browser Admin shell/sidebar PASS** at `127.0.0.1:3200`: live Operations overview, existing signed-in session, Support & inquiries navigation visible; private screen evidence local-only.
- [x] **Real signed-in Android CX1F provider-discovery PASS:** `plumber` search, Specialist Services → Morobe → Lae, QA provider 5.0 (1), provider detail, approved `QA Plumber & Maintenance` Quote listing. No Saved, booking or other user-data writes. Existing emulator userdata preserved.
- [x] **Other Android read-only journey PASS:** Inbox Services (0) / Help & support (1), Track retained completed Specialist booking/Edit review entry, Wallet K0.00 inactive preview, and Profile My Settings/Wallet/Vendor menu. No sensitive request details read or edited. Installed Android Wallet is **blue**, while the newly approved Web style is **green**; update Android only through a verified, non-destructive detached-worktree build and retain this parity as an open check.
- [x] **Admin queue browser DISPLAY acceptance:** owner-provided authenticated screenshot proves the existing 1-open handoff renders; filter and Refresh controls are visible. Interaction through each filter/Refresh remains an optional browser follow-up, although all controls pass synthetic Flutter tests. Private requester text and cookies are not captured or exported.
- [ ] **Still pending Client Web CX1F:** personally signed-in browser search/filter/detail/read-only Saved and Account/Inbox/Track/Wallet/Wantok Agent, then tablet/handset acceptance. Android PASS cannot close Web gate. Real staff replies/assignments, live model gateway and all payment/provider-approval/evidence-intake gates remain disabled.
- [ ] T2.4 starts only after CX1 acceptance, not merely after this evidence.

## CX1I deployment checkpoint — 10 October 2026

- [x] **Read-only Operations Admin Support & Inquiries** deployed on EAGLT02 `http://127.0.0.1:3200/` from source `3342ac0` with original RLS/auth; HTML and Flutter bootstrap HTTP 200, backend read-only request count reports 1 pre-existing open handoff, 7 clean analysis targets, 94 Client + 12 Admin + 1 Technical widget tests and 35 SQL files/767 assertions PASS. `:3000` Client and `:3100` Technical Control still HTTP 200. No schema/role/payment changes.
- [x] **Authenticated queue rendering** accepted from owner screenshot later on 10 October 2026 (see top); HTTP success alone was insufficient at the older checkpoint. Full CX1F authenticated Client Web search/filter/detail/Saved/Account/Track/Inbox/Agent QA and physical HONOR acceptance remain OPEN; T2.4 deferred.

## CX1 owner visual acceptance + support triage foundation — 10 October 2026

- [x] **Owner-approved responsive Client presentation:** after reviewing live, signed-in EAGLT02 Client screenshots at `127.0.0.1:3000`, owner approved the updated enterprise **Home, Services, Explore, Track, Wallet and Inbox** desktop styling and responsive design direction on 10 October 2026; tablet/mobile have automated layout coverage but not physical-device sign-off. The previous visual-approval checkbox in the historical section is superseded by this PASS; it is not proof of authenticated end-to-end provider discovery, OAuth, payment, every populated state, or actual HONOR acceptance.
- [x] **CX1I read-only Operations support intake:** (verified: 7 clean Flutter analyses, 94 Client + 12 Admin + 1 Technical tests, 35 SQL/767 assertions) an authenticated Admin-only **Support & Inquiries** navigation destination queries `ai_agent_handoff_requests` under existing Supabase RLS, shows a bounded recent queue, open/assigned/resolved/closed status filters and safe retry; no new users/roles/schema, no staff responses, no status mutations and no impersonation. Existing agent-owner Inbox remains separate. Local Admin browser QA and staff workflow acceptance remain pending.
- [ ] **CX1 functional gate (updated):** authentic signed-in Web **Services → Browse providers → Specialist Services → Morobe → Lae with the keyword search blank** → sourced existing QA provider detail + read-only Saved state; keep `plumber` text search as a separate secondary check; Account privacy, Inbox Help & support, Track completed booking/review, Wallet preview and Agent entry/handoff; capture verified real browser evidence without exporting any Chrome cookies or writing new records. **CX1 IN PROGRESS; T2.4 DEFERRED.**
- [ ] **CX1I further step:** authorised staff assignment/status update with audit, responses to owner Inbox, and approved live human-chat capability remain unimplemented. Model chat and payment rails remain disabled.

## Unified signed-in Client desktop pages — 10 October 2026 (source PASS; browser review pending)

- [x] **Consistent responsive shell:** `ResponsiveClientCanvas` centres all six signed-in Client destinations on wider screens; Home, Services, Explore and Wallet have a 1480 px maximum; activity/Track and Inbox use a 1160 px reading width. Below 700 px the original handheld flow remains unchanged, and tablet uses available width.
- [x] **Services:** the canonical category grid uses a maximum 245 px tile width within the same centred desktop canvas (not four stretched columns). Existing catalogue search, filters, service navigation, genuine provider data and demo-mode safeguards unchanged.
- [x] **Explore, Track, Inbox, Wallet:** Explore now has a photographic 3/2/1-column editorial grid using original local PNG assets; content is clearly **inspiration, not live bookable listings**. Track and Inbox have green/gold enterprise headers with real booking/conversation views and empty states intact. Wallet's preview hero follows green/gold branding but remains **K0.00 preview, rails inactive**; no fictitious transactions.
- [x] **Focused validation:** `enterprise_client_pages_test.dart` covers 1800 px Services tile width, 1600 px Explore, 390 px Explore/text scaling, 1560 px Track+Inbox, and 1600 px Wallet. New layout has no role, Supabase, payment, review, approval, messaging or transaction mutations.
- [x] **Owner visual review (approved 10 Oct 2026):** reviewed refreshed signed-in Client at `127.0.0.1:3000` following the validated Client-only restart. Technical `:3100`, Operations `:3200` and emulator intentionally unchanged. Full CX1 client journey sign-off still separate, T2.4 remains gated.

## Responsive desktop Client Home correction — 10 October 2026 (source PASS, browser acceptance pending)

- [x] **Desktop Chrome issue addressed:** at 1600 px, the existing three-column mobile photo grid previously stretched to enormous landscape strips. Client Home now uses a **centred maximum 1480 px content region**, photographic tiles with maximum cross-axis size **205 px**, and a desktop-only **Venenssa** provider hero before popular categories. Desktop >=1120 px moves Home/Services/Explore/Track/Wallet to the header; the mobile bottom navigation remains at narrower widths.
- [x] **Mobile/tablet retained:** 390 px maintains original two-/three-column pinch/gesture surface; 900 px shows the width-conscious photographic grid and standard touch navigation; the connected categories/booking links, provider results and Account/Inbox/Wallet routes remain unchanged.
- [x] **Regression:** seven Flutter analysis targets PASS; **88 client + 7 Operations Admin + 1 Technical Control tests** PASS; database **35 SQL/767 pgTAP assertions** PASS. New `enterprise_home_responsive_test.dart` covers 390/900/1600 px and header navigation at 1500 px. Untracked developer-created `supabase/snippets/` is explicitly **out of scope and untouched**.
- [x] **Owner desktop visual acceptance (10 Oct 2026):** loopback Client Web `http://127.0.0.1:3000/` was restarted from the verified source and owner approved the layout; this is not full CX1 functional or physical-device acceptance. Technical `:3100` and Operations Admin `:3200` retain the user's confirmed logins, separate roles and code. Continue remaining desktop Explore/Track/Wallet/Inbox polish later; payment and real vendor actions remain gated.

## Enterprise responsive catalogue and Operations dashboard — 10 October 2026 (source PASS; device review pending)

- [x] **Services desktop/tablet catalogue:** on existing signed-in Services, widths >=700 px now display an enterprise marketplace banner, local service-photo grid (4 desktop / 3 tablet / 2 compact columns), functional category-search/filter chips and a provider discovery panel. Tap destinations still pass through the original `ServicesHubPage`/approved backend routes; missing categories remain informational, not invented providers. Narrow mobile preserves the existing pinch-adaptive entry and the approved **Venenssa** hero photograph (legacy bundled asset filename intentionally unchanged).
- [x] **Operations Admin frontend/backend integration:** existing RLS-protected, role-gated AdminShell now has green desktop sidebar, tablet rail and mobile drawer; overview uses read-only Supabase provider applications, listing reviews, active bookings, recent booking categories and audit events. Financial figures, regional analytics and scheduled modules are clearly labelled **not available**. No sample income/provider records, schema migrations, role grants, upload access or payment activation.
- [x] **Source regression PASS:** 7 clean Flutter analyzer targets; 84 client + 7 Operations Admin + 1 Technical Control widget tests PASS; 35 pgTAP SQL files / 767 assertions PASS; responsive widget tests at Services 840/1440 px and Operations 390/900/1440 px, plus 150% text-scale client regression fixed. `git diff --check` required for commit.
- [ ] **Live visual acceptance / further desktop Home, Explore, Track, Wallet, Inbox polish:** owner-provided PNG reference mockups guide subsequent client UI milestones; these are not yet a pixel-perfect full-screen implementation. Test signed-in browser and admin account against permitted local Supabase before marking CX1 acceptance. Emulator AVD `Medium_Phone_API_36.1` was restarted in active Windows Session 2 without resetting data; rebuilding refreshed client code in a detached worktree is pending after initial main-checkout Gradle asset-lock failure.

## CX1 signed-in Web QA on EAGLT02 — 9 October 2026 (GATE OPEN)

- [x] **Local Web and guest responsive baseline verified:** EAGLT02 clean `feature/flutter-platform-v1` at source `67cad66`. Local Supabase stack responding; real Flutter Web app served **loopback-only** on `http://127.0.0.1:18108/` from a detached `D:\Wantok_CX1_Web_QA_20261009` worktree. An isolated Chrome DevTools guest profile (not the user's existing Chrome profile) rendered the actual sign-in page at **320, 390 and 1280 px** with the approved Wantok Services/Vanessa imagery, green brand, email/password form and create-account link. Human-reviewed screenshots under ignored `.wantok\cx1-guest-cdp-{320,390,1280}.png` show no visible clipping; narrow text wraps rather than overflowing. This is **guest visual-only**, NOT sign-in or provider QA. Baseline checkpoints **PASS**: 7 Flutter analyses clear, 81 client tests + 3 Operations Admin + 1 Technical Control tests, PostgreSQL 35 files / 767 assertions; no app code or schema changes.
- [ ] **Signed-in Web CX1F and client journeys:** a separately isolated **headed Chrome QA browser** is open at `http://127.0.0.1:18108/` pending owner manual sign-in. Do not collect credentials/cookies, copy existing Chrome profile, create test accounts, mutate Saved/reviews or send human-help messages to bypass login. Then perform provider `plumber` query, Specialist Services → Morobe → Lae, rating/save/detail (read-only Saved inspection), Account, Inbox, Track, Wallet, Wantok Agent/handoff, and responsive desktop/mobile authenticated screenshots. Record PASS/FAIL/BLOCKED individually in `docs/CX1_CLIENT_EXPERIENCE_GATE.md`; **CX1 stays IN PROGRESS, T2.4 deferred**.
- [ ] **Development-network containment review:** the local Supabase Docker stack currently reports host listeners on `0.0.0.0` for some development ports (e.g. API/Studio/Postgres). No external reachability was tested and no firewall/container setting was changed. Review host firewall and restrict binding to loopback **only after explicit owner approval**; do not expose Studio/PostgreSQL publicly or disrupt existing data.

## CX1 complete emulator-interface HONOR offline demonstration — 2026-10-09

- [x] **Owner-approved scope:** replace reduced six-category HONOR-only layout with the **real** emulator Home, Services, Explore, Track, Wallet and Inbox Flutter widgets using opt-in, read-only sample data. Preserve Vanessa/scenic PNG cards, original category photography, all twelve S-marked Explore reference scenes, green/gold brand, five bottom tabs and header Inbox/Profile including 2↔3 finger-pinch density.
- [x] **Safety design:** demo fixture category catalogue in memory, injected service/Track/Inbox loaders, no Supabase initialization or developer backend URL. Real component navigation into provider search, booking, saved items, messages and Agent is intercepted to S-marked sample/detail or harmless explanatory pages. Existing VendorHome applicant and illustrative approved-vendor views are for visual review ONLY, without role assignment. Full authenticated provider records, real prices, service orders, ad sales, payment movement and approvals still need separately authorised HTTPS staging.
- [x] **HONOR full-interface offline ARM64 debug build VERIFIED:** detached worktree `D:\Wantok_ARM64_FullInterface_20261009` from commit `a6b164a`; verified APK `D:\Wantok_Project_Backups\WantokServices-HONOR-FullEmulatorInterface-OfflineDemo-arm64-20261009.apk` (105229563 bytes, SHA-256 `755F08A5A5B8B6F052D348A682E85671936225FF01F59CCD77BC5AFE228920AB`). Separate `io.wantok.service.offlinepreview` package and `Wantok Preview` label, minSdk24, verified debug signing, ARM64 Flutter engine, original photographs, no Android Internet/location permissions or checked emulator URL literals / config assets. The standalone build-only Gradle patch and SHA-256 sidecar are archived beside the APK; no regular Android build config or existing phone/emulator data modified. Full source checkpoint: **7 Flutter analyses clean, 81 client + 3 Operations Admin + 1 Technical Control tests PASS; 35 SQL files / 767 assertions PASS; six focused demo tests pass with samples OFF/ON**.
- [ ] **Real HONOR visual acceptance of this NEW full-interface build:** owner installs over the previous Wantok Preview and reviews all six real widget layouts, 17 in-memory example category entries, two S-labelled sample provider cards with zero fabricated reviews, original Vanessa/scenic imagery, sample service details, sample Account/Vendor preview and pinch-dynamic grids. This is NOT a working connected app; CX1 signed-in Web QA and authorised HTTPS staging are separate gates before T2.4. See docs/HONOR_FULL_INTERFACE_DEMO.md.

## CX1 shared pinch-adaptive grids and Profile/Vendor entry — 2026-10-09

- [x] **Owner-approved shared interaction:** category/photo/icon grids in Home, Services (catalogue and See all), Explore reference gallery, and sample preview screens adapt to exactly **2 or 3 columns**; default density follows usable width and large-text scaling. Two-finger pinch **in** selects 3 compact columns, spread **out** selects 2 larger columns. A common notifier shares the choice across grid screens in one client session. One-finger scrolling and regular card taps are unchanged. Detail/forms/lists are not forced into columns. Category text supports two lines. Distinct app build/test still required before HONOR acceptance.
- [x] **Profile dropdown:** the icon beside Inbox now offers **My Settings** (existing account/preferences/security), **Wallet** (Wantok Pay preview only) and **Vendor**. Signed-in, server-authorised providers/drivers go to their existing vendor dashboard; unapproved users go to existing provider application. No automatic approval or bypass of backend RBAC. The offline HONOR design-preview displays same menu with explanatory, nonfunctional My Settings/Vendor sheets and visual Wallet navigation.
- [x] **Vendor panel clarity:** approved vendor dashboard includes entry to existing provider verification/profile details; existing Jobs, Listings, Food/Groceries commerce and industry consoles remain governed by existing authorisation. General-product storefront/sales CX1G, in-app sponsored promotion CX1H, managed external Wantok Ads ADS1 and real earnings/payouts remain **PLANNED / DISABLED**, shown as informational non-action cards rather than fake functioning controls. No real money movement, ad charges, inventory approval, applicant uploads or database role changes.
- [x] **Source regression:** 7 Flutter analysis targets clean, **79 client + 3 Operations Admin + 1 Technical Control widget tests PASS**, 35 PostgreSQL files / **767 pgTAP assertions PASS**; focused pinching 2↔3 and unauthorised Vendor entry checks pass. No DB/schema or permissions changed.
- [x] **HONOR updated visual beta APK verified:** separate detached clean-build source `340f1fa260a4f131f5d0a1c1c9ac449820a841f7` in `D:\Wantok_ARM64_Build_20261009_v2` with the saved build-only patch (Kotlin incremental off, separate `io.wantok.service.offlinepreview` package, `Wantok Preview` label, removed network/location permissions), `android-arm64`, `WANTOK_PHONE_PREVIEW=true`, `WANTOK_SMOKE_DATA=true`, **no emulator/backend credential defines**. New APK `D:\Wantok_Project_Backups\WantokServices-HONOR-PinchProfile-OfflinePreview-arm64-20261009.apk`, **105218839 bytes**, SHA-256 `F1CCFFA22C7F8DE03BD26918DAC189C87AD8D5C58D6709A8D27CA328BB4E2A6B`. `apksigner` verified, ARM64 Flutter engine and original photo assets confirmed; signing certificate matches prior offline preview, and no Android INTERNET/location permission. Debug-only, no backend and no money movement; previous preview retained.
- [ ] **Next acceptance:** owner updates existing `Wantok Preview` on HONOR **without uninstalling**, verifies two-finger pinch 2↔3 on Home, Services and Explore, shared grid density, My Settings/Wallet/Vendor menu, long-scrolling/safe-area and responsive text. Signed-in Web CX1 and approved HTTPS staging remain separate. CX1 stays **IN PROGRESS**; T2.4 later.

## CX1 new responsive grid, Profile menu and updated HONOR build (2026-10-09)

- [x] **Pinch-adaptive categories:** shared two-/three-column photo/icon grid across applicable Home/Services/Explore/HONOR visual-preview surfaces, auto-responsive to width and text size; two-finger pinch inward selects 3, spread outward selects 2 for the app session. Single-finger scroll/tap preserved. Approved photo assets remain unchanged; widget tests verify both gestures.
- [x] **Profile dropdown:** My Settings goes to existing profile/security, Wallet goes to Wantok Pay preview, Vendor goes to existing application/status if unapproved or role-gated vendor dashboard if authorised. Vendor dashboard links to existing jobs/listings/commerce and **labels** ads, general-goods sales and settlements as pending gates; no permissions, approvals, transactions or real ads activated.
- [x] **New isolated HONOR debug offline-preview APK built/verified:** `D:\Wantok_Project_Backups\WantokServices-HONOR-OfflinePreview-PinchProfile-arm64-20261009.apk` SHA-256 `F1CCFFA22C7F8DE03BD26918DAC189C87AD8D5C58D6709A8D27CA328BB4E2A6B`, size 105218839 bytes. Distinct `io.wantok.service.offlinepreview` package; verified ARM64 Flutter engine and APK signature; no Internet/location permissions or emulator-only backend configuration. Build patch and hash sidecar backed up; normal emulator not reinstalled. Git source at `340f1fa` validated 7 analysis targets, 79 client + 3 Admin + 1 Tech Flutter tests and 767 SQL assertions.
- [ ] **Updated HONOR handset visual acceptance:** install this new APK *over the existing Wantok Preview package only* (never uninstall the real Wantok app), verify pinch on actual hardware at 2/3 columns, Profile menu, vendor sample explanation, text scaling and Android bottom safe-area; earlier six phone screenshots predate these changes. Full functional client QA and signed-in Web CX1 are still open; T2.4 remains gated.

## CX1 next milestone — HONOR Android ARM64 visual beta and Web acceptance (2026-10-09)

- [x] **Approved scope:** EAGLT02 source checkpoint `1ccd640` completed Home/Services/Explore separation, photo gallery relocation, green/gold design, Inbox beside Profile and five bottom tabs `Home · Services · Explore · Track · Wallet`; vendor registration remains inside Profile. Android emulator checked with opt-in S-marked samples.
- [x] **Device-build diagnosis:** prior `wantok-android-prior-explore-20261009.apk` is an x86_64 Flutter debug engine build for an emulator, compiled with backend host `10.0.2.2`. It is NOT a working physical-phone build; default Android production signing remains unconfigured and debug-signed. The existing local development Supabase must not be exposed to enable a phone test.
- [x] **HONOR offline phone-preview source and tests:** explicit `WANTOK_PHONE_PREVIEW=true` boot branch **before** Supabase init, approved photographic Home / Services / Explore, S-marked opt-in gallery, five tabs and conspicuous read-only warnings; no backend config, sign-in, bookings or payments. 4 focused phone tests PASS in both sample modes, 7 Flutter analyses clean, 75 client + 3 Admin + 1 Technical tests PASS, database 767/767 PASS.
- [x] **HONOR offline ARM64 packaging — COMPLETE on EAGLT02:** detached clean worktree at `D:\Wantok_ARM64_Build_20261009` from checkpoint `c983cfb`. Resolved the actual Kotlin compiler `C:` Pub Cache / `D:` project different-root error with **worktree-only** `kotlin.incremental=false`; built debug `android-arm64` with explicit `WANTOK_PHONE_PREVIEW=true`, `WANTOK_SMOKE_DATA=true` and **NO** emulator backend config. Final isolated build-only manifest/package adjustments create **Wantok Preview**, ID `io.wantok.service.offlinepreview` (coexists with normal app) and remove Internet/location permissions. APK contains ARM64 Flutter engine, authentic photographs and verified debug signature; local compiled snapshot scans found no listed emulator/loopback endpoint literals or sensitive file paths. SHA-256 `8C9C135659AABF6010B13E580E69511673B7CDF11524B4897E2C936A150B6BCE`, 105209491 bytes. Stored at `D:\Wantok_Project_Backups\WantokServices-HONOR-OfflinePreview-arm64-20261009.apk`. See `docs/HONOR_ARM64_PHONE_PREVIEW.md`. Normal source and emulator unchanged.
- [x] **Physical HONOR offline-preview installation and initial visual QA — 2026-10-09:** owner supplied six screenshots taken on the HONOR showing Wantok Preview Home, Services, Explore gallery (scrolled), Track, Wallet and an opened `Service Listing (Food)` sample detail. APK launches; green/gold brand, Vanessa photo and category imagery render; five client bottom destinations visible; sample `S` markers and **OFFLINE PREVIEW** warning persist; Track/Wallet remain explicitly inactive. This is a **physical-device launch and initial screen-display PASS only**, not a full functional or interaction acceptance; screenshots are evidence in the conversation, **not copied into public GitHub**.
- [ ] **HONOR responsive visual follow-up:** category labels `Home Services` and `Water Transport` truncate in the three-column phone grid; bottom-nav text looks tightly spaced at observed phone scaling; verify bottom/system navigation safe-area on scrolled Food Listing sample detail (last visible card partially behind navigation region). Obtain full Home scroll showing scenic Explore footer, reference gallery full set and small/large text scroll/interaction evidence. Propose two-column categories and adapted navigation labels, but **do not alter the approved UX without owner confirmation**. Confirm Android version and exact device details separately (screenshots do not establish these).
- [ ] **Final physical visual acceptance:** after agreed spacing fixes and screenshot recheck; still **offline-design-only**, debug signed and not a real account/booking/payment release.
- [ ] **Functional physical-phone beta gate:** obtain/approve a dedicated reachable HTTPS staging API/Auth endpoint (not local emulator `10.0.2.2`), signed mobile test accounts and non-production dataset, TLS/network controls, safe mobile signing/update/distribution and end-to-end tests. No public Supabase Studio, PostgreSQL, unrestricted Storage or real money movement. No secrets in Git.
- [ ] **Close CX1:** signed-in Web provider search/filter/rating/save/detail, Account/Inbox/Track/Wallet/Agent handoff, final Android/Web screenshots and documented acceptance in `docs/CX1_CLIENT_EXPERIENCE_GATE.md`. CX1 is still **IN PROGRESS**; T2.4 diagnostics follows acceptance, while CX1G/CX1H/ADS1/GLOB1/TRV1 remain planned.

## CX1 approved Explore restructuring (2026-10-09) — distinct destination and de-duplicated Home

- [x] **Bottom navigation update:** add fifth client tab **Explore** between Services and Track; resulting **Home · Services · Explore · Track · Wallet**; keep Inbox icon beside Profile. Provider registration stays in Profile, vendor navigation unaffected.
- [x] **Home:** move the existing photographic `Explore PNG and beyond` banner to the very bottom of the Home list, separated from Vanessa's existing green/gold provider card; clicking scenic card opens Explore, while Vanessa's card continues to open provider search.
- [x] **Services / Explore:** leave functional Services Categories and search on Services. Relocate all twelve S-marked photographic Reference Screen Samples to the new Explore page without duplicating previews on Services; preserve original assets and sample-detail previews. The gallery is still **opt-in developer-only**. Explore remains available with `WANTOK_SMOKE_DATA=false` through a photographic header, `Browse services` link and non-misleading placeholder copy.
- [x] **Regression gate:** focused tests in default and `WANTOK_SMOKE_DATA=true` modes PASS; **7 clean Flutter analysis targets, 71 client + 3 Operations Admin + 1 Technical Control tests PASS**; **35 SQL files / 767 assertions PASS**. Assets unchanged.
- [ ] **Remaining acceptance:** signed-in emulator and Web visual QA (especially navigational scrolling/small displays), rollout of real Explore experiences only when approved. CX1 remains in progress before T2.4. No live ads, applicant uploads, payment rails or provider approvals enabled.

## CX1 approved interface adjustment (2026-10-09) — green/gold navigation and Home consolidation

- [x] **Global design tokens:** replace bright-blue primary with forest green `#075D3F` / dark `#06482F` and use gold `#FFBD2F` accent; retain original photographic categories and Vanessa portrait/promo card unchanged.
- [x] **Owner-approved navigation placement:** Inbox button beside Profile in the header, **Home · Services · Track · Wallet** in the client bottom navigation; vendor bottom **Dashboard · Jobs · Listings · Me**, Inbox in header. Existing Account/Profile provider-registration and mode switching retained. No route removed.
- [x] **Reduced Home repetition:** remove horizontal category-chip rail (Popular Categories already provides navigation); keep distinct scenic PNG discovery and Vanessa local-provider photo promo, with the latter opening provider search. Services Categories remain functional catalogue navigation; the 12-screen photo Reference Gallery remains development-only, marked `S` and controlled by opt-in `WANTOK_SMOKE_DATA`.
- [x] **Local Android QA:** `Medium_Phone_API_36.1` session 1; new in-place debug APK built with developer-only photo `S` samples on, `MainActivity` foreground with Home/Services/Track/Wallet/Inbox/Profile accessibility labels. Existing emulator sign-in data not wiped or app uninstalled. Source tests 7 analysis targets, 72 Flutter tests and 767 pgTAP assertions PASS.
- [ ] **Remaining CX1 acceptance:** review visual details on signed-in Android and the signed-in Web search/filter/account/wallet/inbox journeys; T2.4 still deferred. Evidence uploads, reviewer access, approvals and money movement remain unchanged/disabled.

## Current security increment (2026-10-09) — read-only custody snapshot consistency, uploads SEALED

- [x] **Synthetic-only offline comparator:** WQE2 encrypted scratch candidate checked against separately supplied SQL-shaped manifest snapshot and claimed/withdrawn status. Flags file/metadata absence, claim mismatch, hash/tamper mismatch, withdrawn claims and interrupted states. A perfect match remains `snapshot_matches_still_pending_independent_reconciliation`, **not proof of custody or authority**. `npm run test:evidence` **85 PASS**, real ClamAV **6 PASS**, local PostgreSQL **35 files / 767 assertions PASS**.
- [x] **Android emulator preserved:** existing `Medium_Phone_API_36.1` launched without data wipe, installed Wantok Services `io.wantok.service` confirmed foreground by ADB. Docker Desktop process-environment issue fixed without system settings or volume changes. See `docs/EVIDENCE_CUSTODY_RECONCILIATION_DRYRUN.md`.
- [ ] **Still required:** authentic restricted server-side database snapshot query and claim-state verification, independent manifest-to-file outbox reconciliation, dedicated service identity/storage, managed keys/rotation, content sandbox, consent/privacy, retention/erasure, off-host audit, restore drills, authorised reviewer access. CX1 signed-in Web QA remains open before T2.4. Live applicant uploads remain disabled.

## Current security increment (2026-10-09) — metadata-linked custody and protected ACL lab, uploads SEALED

- [x] **Local schema only:** single-write, claim-receipt-bound custody manifest capturing bounded plaintext/ciphertext SHA-256 and file metadata under service-role-only RPC; all records remain `pending_independent_reconciliation`, without applicant grants, reviewer access, upload ability or provider approval. Local migration `20261009060000_custody_manifest_metadata.sql` applied; **35 SQL files / 767 pgTAP assertions PASS**.
- [x] **Offline synthetic bridge and ACL validation:** WQE2 synthetic envelope verifies digests and builds non-submitted manifest arguments (no database or Auth service connection). New read-only Windows verifier accepts an empty, inheritance-disabled NTFS lab with exactly SYSTEM/current EAGLT02 account FullControl; rejects the inherited project repository ACL. **73 unit tests + 6 real ClamAV tests PASS**. See `docs/EVIDENCE_CUSTODY_MANIFEST_AND_ACL_LAB.md`.
- [ ] **Not completed:** production-safe ACL/service account, real file/DB transaction and reconciliation outbox, interrupted-write recovery, KMS, actual consent, sandboxed PDF/image validation, off-host audit, retention/erasure and Operations Admin reviewer release. The manifest is **not proof that a file is held**, and the NTFS lab is not a production vault. CX1 signed-in Web QA remains open; T2.4 deferred.

## Current security increment (2026-10-09) — claim-bound offline crash-state prototype, uploads SEALED

- [x] **Local synthetic-only custody:** AES-256-GCM single-envelope authenticated claim/intent/account/application/check/key-ID metadata; exclusive non-overwriting hard-link publish, file `sync()` and read-only inspection of lock/pending/held crash states. Concurrent claims and injected stops before/after publishing tested: **71 scanner/custody unit tests PASS, 6 actual ClamAV integration tests PASS**. Pure local temporary fixtures only; see `docs/EVIDENCE_CUSTODY_OFFLINE_RECOVERY.md`.
- [ ] **Remaining release gates:** verified GoTrue claim-to-file execution, durable DB manifest/outbox, controlled retry after failures, independently accepted dedicated NTFS ACLs/Linux vault, KMS/key rotation and recovery, content normaliser sandbox, consent/privacy/legal holds/erasure, immutable off-host audit, authorised reviewer separation, power-loss and actual restore rehearsal. Scratch hard-link+file sync is not proof of durability/immutability and **does not permit actual applicant uploads**. CX1 stays open; signed-in Web QA precedes T2.4.

## Current security increment (2026-10-09) — ClamAV freshness preflight, uploads SEALED

- [x] **Internal quarantine default gate:** require loopback ClamAV `VERSION` to report signature age at most **48 hours** before `INSTREAM`; reject stale/missing/malformed/version responses, overlong replies, health failures and excessive clock skew before bytes are scanned. 72-hour absolute maximum policy; original injection seam remains test-only. Scanner freshness alone is not content sanitisation or approval. Unit **57 PASS** and actual ClamAV **5 PASS**, including EICAR. See `docs/EVIDENCE_SIGNATURE_FRESHNESS.md`.
- [ ] **Still blocked:** Auth/claim-to-file connection, safe retry/recovery, managed keys, explicit ACL/dedicated volume, durable ciphertext+DB manifest, decoder sandbox, explicit legal/privacy consent, reviewer authorisation, retention/erasure, off-host audit and full restore rehearsal. Uploads, Storage object policies and provider approval stay disabled.

## Current engineering checkpoint (2026-10-09) — server-only one-time claim, uploads SEALED

- [x] **Implemented EAGLT02 locally:** loopback GoTrue account verification adapter, locked-to-`service_role` one-time claim RPC and claimant/check/application eligibility revalidation, atomic state/receipt transaction, and post-claim applicant withdrawal. Local migration `20261009043000_evidence_one_time_claim.sql` and 34-file pgTAP suite **736/736 PASS**; synthetic admission/scanner suite **46/46 PASS**; real ClamAV **4/4 PASS**. No public route, no client account UI changes, no file intake.
- [ ] **Next separate gates:** verified live GoTrue-to-claim end-to-end test and concurrency/crash recovery; real consent/withdrawal notice; dedicated protected storage/ACLs and immutable digest-bound encrypted custody; KMS rotation/recovery; document content normalisation; ClamAV signature freshness and resource quotas; off-host audit; retention/erasure/holds; least-privilege reviewer release; restore rehearsal and authorisation. `docs/EVIDENCE_AUTH_AND_CUSTODY_DESIGN.md` defines scope and limitations. Never activate `staged-provider-evidence` Storage policies or real uploads prematurely.
- [x] **Preservation:** category photographs/unified taxonomy, Flutter theme, `SMOKE_20261008_*` `s` fixtures, emulator/session, existing Operations/Technical role separation and all client journey controls unchanged.

## Prior engineering checkpoint (2026-10-09) — historical 73ea82f baseline

- **Latest implementation source:** `73ea82f` on `feature/flutter-platform-v1`. EAGLT02 local + GitHub commit match; private DB archive and independent local Git bundle verified. Source-specific implementation/limitations in `docs/EVIDENCE_QUARANTINE_ADMISSION.md`.
- **Implemented locally:** account-bound, withdrawable **non-uploading evidence intent** RPC/RLS; sealed Supabase bucket; real ClamAV/EICAR detection; separately injected **AES-256-GCM encrypted quarantine candidate** and integrity checker using synthetic bytes. No live session-verified network gateway, approved consent or reviewer release.
- **Tests at checkpoint:** database **711/711** (33 files), scanner/quarantine **35/35**, real ClamAV **4/4**, Flutter **68 app + 3 Admin + 1 Technical**, seven analysis targets clean. No emulator reset required.
- **Next gated work:** trusted server JWT validation and atomic one-time intent claim, proven secure local filesystem ACLs or Linux isolated volume, KMS/secret recovery, ingestion limits/content normaliser/ClamAV freshness, durable receipts and transaction recovery, audit, data retention/consent, reviewer separation and restore rehearsal. **Do not enable uploads or approval/payment/booking until full end-to-end controls are independently tested and authorised.**
- **UX/fixtures:** approved photo-rich category grid with consistent assets and reversible s-marked fixtures remains unchanged. General CX1 signed-in Web QA and T2.4 are still open; work on evidence does not satisfy those gates.

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

### Navigation decision — CURRENT (supersedes earlier historical layouts)

**Owner-approved current bottom bar: Home · Services · Explore · Track · Wallet.**
**Inbox** is in the global header beside **Profile**; Account/Provider registration stays inside Profile. Vendor bottom navigation remains separate. The Home `Explore PNG and beyond` card opens Explore; photographic `Reference Screen Samples` are development-only on Explore, not Services.

Earlier four/five-tab entries lower in this historical roadmap reflect prior checkpoints and are superseded by the 9 October 2026 CX1 Explore decision. Do not rename navigation to another brand's labels. Product discovery lives in Services; PNG travel/experience design discovery starts in Explore; activity lives in Track.

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

- [x] rebuild the **main Services landing** to the supplied 12-category/3-column reference layout, now upgraded from plain Material icons to twelve realistic AI-generated, locally bundled service pictures with labels underneath. The same shared picture registry is used by **Home shortcuts, Home chips, spotlight cards, Services, real All Services and matching service headers**. Preserve genuine backend catalogue/provider routing, filters, saved buttons and the removable `s`-marked smoke layer. See `docs/CATEGORY_IMAGES.md`.
- [x] extend Services to **18 picture-first categories** (six more cards before More: Delivery, Hotels, Education & Training, Financial Services, Water Transport and General Labour). Add seven information-only backend category records for Shopping, Home Services, Beauty & Wellness, Health & Medical, Travel & Flights, Education and Financial Services through additive migration `20261008214500_client_category_expansion.sql`. Preserve the original 15 backend categories and existing enabled routes. New categories open an honest read-only information page; no fabricated providers, bookings, payment rails or provider onboarding. All new category imagery reuses existing local files; **no new images generated** for this continuation. Database regression 28 files / 607 tests PASS locally; production migration not yet deployed.
- [x] CX1 provider-readiness continuation: category-scoped verified-provider search, real logged-in **provider interest** for seven information-only verticals, private RLS-backed idempotent submission, and an **Admin read-only interest queue**; no formal application/approval, provider role, bookings, payments or auto-notifications. Migration 20261008223000_provider_category_interest.sql is local-only. See docs/PROVIDER_CATEGORY_INTEREST.md and pgTAP test 029.
- [x] implement a separate **preliminary provider application** stage for Shopping & Retail, Home Services and Beauty & Wellness: category-readiness policies, basic applicant/service intake, private RLS, duplicate protection, Admin manual **in_review/declined** triage, and deliberately **no provider verification/role/listing/payment activation**. Regulated and higher-risk Health/Medical, Financial, Travel/Flights and Education/Training remain restricted. See `docs/PROVIDER_STAGED_ONBOARDING.md` and migration `20261008231500_staged_provider_onboarding.sql`.
- [x] add **preliminary verification checklists with Admin-only audit trail** to the three staged provider application categories: policy-requirement snapshot, RLS, applicant read-only progress, Admin confirmed pending/under_review/needs_followup actions, reviewer/time tracking, authenticated audit and explicit rejection of approved. No real credential uploads or provider activation. See `docs/STAGED_VERIFICATION_PROGRESS.md` and migration `20261008234500_staged_verification_progress.sql`.
- [x] establish a **closed, private staged-provider evidence storage boundary** (5 MiB, PDF/JPEG/PNG MIME declarations, no client Storage access policies) and a minimal, RLS-controlled future evidence-planning register with admin-only idempotent plan/cancel RPCs and audit history. Applicant sees an explicit **uploads unavailable** notice; Admin can plan but cannot accept/approve evidence. No files uploaded and no scanning or verification claimed. See `docs/PROVIDER_EVIDENCE_VAULT.md`, migration `20261009011500_evidence_vault_boundary.sql` and test 032.
- [x] implement an **isolated local ClamAV INSTREAM scanner client and fail-closed content gate** (signature-based preliminary PDF/JPEG/PNG checks, SHA-256, 5 MiB cap, local-only scanner address, timeout and malware rejection). Tests use a TCP simulator, not real antivirus signatures. Even clean results are hard-coded **storagePermitted=false, reviewerAccessPermitted=false, approved=false**. No API/upload enabled. See `packages/evidence_scanner/`, `npm run test:evidence`, and `docs/EVIDENCE_SCANNER_CORE.md`.
- [x] provision an **isolated, resource-limited real ClamAV instance** on EAGLT02 after verifying C: had 51.2 GiB free; restrict TCP to loopback, persist signature database, verify FreshClam reloaded current daily signatures 28147, and pass real clean/EICAR tests (3/3). Keep the sample/protocol tests separate (24/24). Document safe operations in `scripts/clamav-local.ps1` and `docs/CLAMAV_LOCAL_RUNTIME.md`.
- [x] introduce an **account-bound but non-uploading intake-intent RPC** with eligibility/withdrawal RLS and a separate **AES-256-GCM encrypted candidate quarantine library** (SHA-256 AAD integrity, exclusive writes, fail-closed clean scanning, no reviewer access). Tests use synthetic document bytes and an injected admission verifier; the live ClamAV integration checks isolated temp-file quarantine. No actual JWT gateway, live consent, cloud upload or release exists yet. See `docs/EVIDENCE_QUARANTINE_ADMISSION.md`, migration `20261009024500_evidence_intake_intents.sql`, tests 033 and `packages/evidence_scanner/src/quarantine.mjs`.
- [ ] design and authorise **actual protected document intake**: trusted server JWT verification + one-time database claim, formally approved privacy notice/consent, filesystem ACLs or dedicated Linux volume, key management/rotation, atomic DB/file metadata, immutable/versioned storage, full decoder and malware controls, controlled reviewer access, retention/deletion/holds, regulated licence checks, tested restore and independent final provider/listing approval. The evidence bucket remains SEALED; do not repurpose the owner-editable `provider-documents` bucket. Existing approval workflow remains authoritative.
- [x] add an opt-in 12-screen **reference sample gallery** with registered `SMOKE_20261008_SCREEN_*` IDs, visible small `s` markers, sample food providers, booking/flight/hotel examples, a demonstration route, and wallet/account examples. All examples are read-only and disabled by default for non-smoke builds; the source screenshot's individual photographs are not separately present, so the examples use existing approved PNG-themed images.
- [x] refine separate smoke-only Food Listing, Taxi, Travel, Bookings, Tracking, Wallet, Account and Home preview layouts. Verify disabled payment/booking controls, smoke identifiers, Flutter analysis and tests; install the x86-64 QA build over the existing Android emulator without clearing saved data. Keep the genuine service modules separate.

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
