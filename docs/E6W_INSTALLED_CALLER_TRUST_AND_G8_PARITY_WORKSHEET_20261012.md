# E6W — Installed Privileged-Caller Trust and G8 Parity Worksheet

**Prepared:** 12 October 2026 PNG | **Machine:** EAGLT02 only | **Branch:** `feature/flutter-platform-v1`
**Classification:** Source engineering and PostgreSQL **READ ONLY** catalog evidence; not security certification, delegated authority, production permission or independently witnessed staging.

## 1. Objective and method

E6V counted 16 historical SQL call candidates to `write_audit_event`, including superseded definitions. E6W separates those historical references from the **latest checked-in source declaration per function name** and checks the corresponding currently installed **local** PostgreSQL function metadata in a `BEGIN TRANSACTION READ ONLY` session.

Run from the existing repository root:

- `node scripts/qa/e6w-installed-caller-trust.mjs --source-only`
- `node scripts/qa/e6w-installed-caller-trust.mjs --local`

The second command uses the authorised local `supabase_db_wantok-service` Docker PostgreSQL only. It reads `pg_proc`, `pg_namespace` and `pg_roles`; returns public function identities, owners, ACL, search path, effective role EXECUTE and Boolean regex references to each writer. **The SQL function bodies are inspected inside PostgreSQL but not exported.** No application row, customer record, token, real account or personal data is read. It does not authenticate over GoTrue, exercise HTTP/PostgREST, create stage accounts or deploy SQL.

## 2. Checked-in source versus installed local catalogue

| Inventory | Finding |
| --- | ---: |
| SQL migration files inspected | **77** |
| Dollar-quoted CREATE FUNCTION definitions parsed | **227** |
| Unsupported body declarations in this scan | **0** |
| Historical function definitions with a writer mention | **16** |
| Latest checked-in source declaration names containing a writer call | **12** |
| Installed local selected signatures, including both writers | **14** |
| Installed selected signatures missing | **0** |
| Selected current local caller definitions with audit-writer mention | **12** |
| Selected current local caller definitions with notification-writer mention | **0** |

The 12 latest-by-name call candidates are: `audit_status_change`, `grant_user_role`, `revoke_user_role`, `set_technical_module_state`, `grant_technical_module_access`, `revoke_technical_module_access`, `update_technical_module_configuration`, `admin_set_public_services_enabled`, `save_wantok_branding_draft`, `publish_wantok_branding_draft`, `restore_wantok_branding_version` and `manage_service_category`.

All **14 selected local functions** are currently `SECURITY DEFINER`, locally owned by `postgres` with `BYPASSRLS`; effective SQL EXECUTE is present for both `anon` and `authenticated` across the selected sample, although internal checks within an individual function may still reject unauthorised actions. The `postgres` owner can execute the two shared internal writers. The existing untrusted direct EXECUTE grants for `write_audit_event` and `enqueue_notification` therefore remain an **OPEN E6O-01 security finding** in the persistent local database.

This is **not** proof that all 12 functions are exploitable through a public endpoint. The `audit_status_change` routine returns `trigger` and is not a normal direct SQL RPC; actual published schemas, function overloads/default arguments, caller JWT identity, internal guards, application privileges and nested effect paths require independent examination. The checked-in E6O privilege correction is **not applied**.

## 3. Compatibility and authority groups for the G8 reviewer

| Review group | Current checked-in source candidates | Required independently witnessed stage result |
| --- | --- | --- |
| Trigger path | `audit_status_change` | Authorised status change creates exactly the expected attributed audit event; forbidden update has no business/audit side-effect |
| Operations role grants | `grant_user_role`, `revoke_user_role` | Properly delegated two-person/role policy, successful allowed audit, denial of unrelated role and self-approval paths |
| Technical controls — **PAUSED** | `set_technical_module_state`, `grant_technical_module_access`, `revoke_technical_module_access`, `update_technical_module_configuration` | Source compatibility inventory only; no Technical staging mutation until separate unpause/authority |
| Public services switch | `admin_set_public_services_enabled` | Only approved test account may invoke reversible change, audit attribution verified and restore observed |
| Branding/category | `save_wantok_branding_draft`, `publish_wantok_branding_draft`, `restore_wantok_branding_version`, `manage_service_category` | Distinct unauthorised/authorised tests, immutable audit and explicitly reverted staged content |
| Notification | `enqueue_notification` | Actual approved service-worker enqueue, outbox handling and idempotency/delivery positive and denied direct untrusted RPCs |

## 4. Exact privilege-parity worksheet for a *future authorised* stage

Every row is **PENDING**; this document contains no independent production/staging snapshot or sign-off.

| Parity field to compare for all 14 signatures | Persistent EAGLT02 local baseline | Approved stage expected/observed | Independent witness |
| --- | --- | --- | --- |
| PostgreSQL image/extension build and migration ledger | Local catalog only | NOT SUPPLIED | NOT ASSIGNED |
| Signature, overloads, default parameter routing and installed body digest | 14 identities inventoried; body not exported | NOT SUPPLIED | NOT ASSIGNED |
| Owner name; SUPERUSER/BYPASSRLS and inherited privileges | 14/14 local `postgres` BYPASSRLS | NOT SUPPLIED | NOT ASSIGNED |
| SECURITY DEFINER, explicit search path and `pg_temp` ordering | Selected local paths reported, pre-E6N | NOT SUPPLIED | NOT ASSIGNED |
| Explicit ACL, `PUBLIC` grant, `anon`/`authenticated`/`service_role` effective EXECUTE | 14/14 sample has untrusted SQL EXECUTE | NOT SUPPLIED | NOT ASSIGNED |
| RLS, FORCE RLS, policies, table/column grants and default privileges | Local only; prior E6U baseline 93 public tables/117 policies | NOT SUPPLIED | NOT ASSIGNED |
| PostgREST published schema, RPC argument matching, genuine GoTrue identity | NOT TESTED | NOT SUPPLIED | NOT ASSIGNED |
| Nested positive audit call, denial side effects, notification outbox/worker continuity | Disposable SQL audit-only 301/301 at E6U | NOT EXECUTED | NOT ASSIGNED |
| Backups, checksum, rollback rehearsal, synthetic test IDs and clean-up witness | NOT SUPPLIED | NOT SUPPLIED | NOT ASSIGNED |

**Stage prerequisites:** separate written owner approval for the exact dedicated environment and staged changes, validated backup/restore, exact owner and permission parity, scoped non-personal test identities, independently authorised Security + Operations witnesses and planned cleanup. If a signature, role, publisher configuration or RLS policy differs unexpectedly, stop before migration or positive mutation. The existing `pg_restore --no-owner --no-acl` disposable regression is not an equivalent stage.

## 5. Engineering regression (not human acceptance)

EAGLT02 validation after source-only E6W changes:

- `node --check`, E6W source and local-catalog scanners and prior E6V historical source scanner: **PASS**.
- Disconnected PostgreSQL seven-pending-migration cross-stream suite: **301/301** assertions, **16/16** suites PASS; transaction fixtures rolled back, isolated container removed and shared DB unchanged.
- Synthetic signed-JWT negative HTTP boundary tests: **23/23 PASS**, not real GoTrue acceptance.
- Independent E6 rollback-only cases: **106/106 PASS**; E6S proposed role privacy contract source and local READ ONLY validation **PASS**; evidence-scanner **101/101 PASS**.
- The combined shared `npm run db:test` is **not represented as green**: unapplied E6H/T2.4/E6N/E6O SQL remains pending, so the disconnected compatibility harness is the appropriate safe integration evidence. No persistent migrations were promoted.

Fresh detached unchanged Flutter source checkout at `D:\Wantok_E6W_Flutter_QA_20261012` (E6V exact committed baseline `2476e10`) returned **exit 0**: **7/7 clean static analyses**, Client **132/132**, Operations **43/43** and Technical **38/38** widget tests passed (**213/213 total**). No Flutter source was changed in E6W, and the main checkout's previously locked build artefacts were not removed. The new scanner and report files are not part of those Flutter app artefacts.

## 6. E6 disposition and next checkpoint

- **E6O-01 OPEN:** Current local internal-writer direct grants remain exposed; correction source validated only in disposable testing. Independent G8 prioritisation is required before authorised staging; this report does not delay emergency handling under separately approved procedures.
- **E6O-02 OPEN:** Technical internal health-report route belongs to paused T2.4; do not change that module's source/grants in E6W.
- **G8 privacy D1–D5 NOT SUPPLIED:** public provider columns, unrelated-user role metadata, trusted routes and permitted disclosures still need human decisions.
- **G7-31:** specific future nested audit and notification continuity test is **NOT EXECUTED**. Total G7 planned **31**, none signed; **G1–G10 = 0/10**. E7+, payments, staff provisioning, provider activation and production remain sealed.

**Scope limit:** The source scanner is regex-based, keyed by *function name* rather than full SQL identity, may count comments/strings, may miss dynamic SQL and cannot guarantee function-body equivalence. The installed catalog returns Boolean regexp indicators and ACL facts only; **not** full call-graph assurance or actual API exposure. Continue with a separately approved role-parity stage plan or non-mutating CX1 preparation; no implicit authority to deploy.
