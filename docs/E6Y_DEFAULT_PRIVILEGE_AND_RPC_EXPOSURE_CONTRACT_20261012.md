# E6Y — Default Privileges and Candidate RPC Exposure Contract

**Date:** 12 October 2026 PNG | **Authorised machine:** EAGLT02 | **Branch:** `feature/flutter-platform-v1`

**Disposition:** Local-only engineering and stage-readiness preparation. **NOT** independent G7/G8 acceptance, exploit confirmation, production authorisation or migration approval. E-series ACTIVE; CX1 QUEUED; T2.4 PAUSED.

## Purpose and evidence basis

E6X produced a read-only G8 PostgreSQL metadata snapshot. E6Y isolates **future-object default privileges** from **existing function EXECUTE** and distinguishes static API configuration from actual PostgREST RPC publication. The new `scripts/qa/e6y-default-acl-rpc-contract.mjs` reads the checked-in `supabase/config.toml` `[api]` section and, in `--local` mode, queries only PostgreSQL **system catalogues**, using one `BEGIN TRANSACTION READ ONLY` session against authorised local `supabase_db_wantok-service`. It calls no HTTP routes and reads no user/application records or credentials.

Use from repository root:

- `node scripts/qa/e6y-default-acl-rpc-contract.mjs --source-only`
- `node scripts/qa/e6y-default-acl-rpc-contract.mjs --local` (keep full output only in ignored `.wantok/`)
- `node --test scripts/qa/e6y-default-acl-rpc-contract.test.mjs`

The function signature inventory is intentionally restricted to E6W's **14 exact selected local functions** (12 audit-writer call candidates, two shared writers). The SQL query identifies privileges with `aclexplode(pg_default_acl.defaclacl)`, and checks selected function `pg_get_function_result`, default argument counts, owner/definer metadata and effective SQL EXECUTE. It does **not** export SQL function definitions, create test functions, or issue privileged mutations.

## Local facts observed

| Evidence | Current EAGLT02 observation | What it does **not** prove |
| --- | --- | --- |
| Checked-in `[api].enabled` | `true` | Running PostgREST schema/config parity |
| Checked-in `[api].schemas` | `public`, `graphql_public` | A successful or safe HTTP call |
| `auto_expose_new_tables` | Commented/unset; source comment describes fallback to `true` | Actual running override or cloud setting |
| Selected public functions | **14**, including one trigger-return function | All are ordinary callable RPCs |
| Selected functions with SQL `anon` EXECUTE | **14/14** | Successful role-authenticated business action |
| Selected functions with SQL `authenticated` EXECUTE | **14/14** | Real GoTrue JWT test |
| Non-trigger functions for API route *review* | **13** | 13 published/exploitable RPCs |
| Internal writers with direct untrusted SQL EXECUTE | **2/2** | External exploit or production exposure |
| `pg_default_acl` catalogue rows | **27** | 27 security incidents |
| Future `public` functions created by local `postgres`: `EXECUTE` to `anon`, `authenticated` | **2 explicit default-grant entries** | Past/current function ACL is altered |
| Future `public` tables created by local `postgres`: grants to `anon`/`authenticated` | **16 privilege entries** (8 per role, including `TRUNCATE`) | Database rows readable or writable despite RLS |
| Future `public` sequences created by local `postgres`: grants to `anon`/`authenticated` | **6 privilege entries** | Actual sequence exposure over REST |
| Future table `TRUNCATE` default grants | **2** | Existing objects have identical permissions |

**Important rule:** The `pg_default_acl` entries describe grants for *new objects created by the matching owner in the matching schema*. They do not themselves add grants to already existing functions, tables or sequences. The existing E6O-01 shared-writer grants are a **separate already-installed** ACL issue; the newly observed default grants are an additional **prospective object-creation risk**, not an independently proven abuse.

The `audit_status_change()` function returns `trigger`. It has SQL EXECUTE grants in the catalogue but is not a normal direct PostgREST callable function. For the other 13, the `candidate_for_rest_review` flag is intentionally based only on **static checked-in API schema + non-trigger return + effective SQL EXECUTE**. It never asserts real runtime exposure, parameter routing, authorisation bypass or successful function invocation.

## Security decisions needed before any corrective migration

1. **Existing internal-writer grants (E6O-01) — OPEN / high-priority independent assessment.** The unapplied proposed `20261012152000_e6_shared_internal_rpc_execute_boundary.sql` restricts the two shared writers in source and passed prior disconnected SQL tests. Before authorised deployment, verify true owner, nested audit triggers, trust-worker notifications, PostgREST route denial and rollback on a separately approved owner/ACL-equivalent stage.
2. **Future function defaults — REVIEW REQUIRED.** An independent reviewer must decide if functions created as `postgres` in `public` should receive `anon`/`authenticated` EXECUTE automatically. If explicit grants are required instead, design a **separate** reversible migration and compatibility plan, accounting for expected anonymous discovery functions and existing dependent services.
3. **Future tables/sequences — REVIEW REQUIRED.** Local `postgres` default ACLs include eight public-table privileges per client role, including `TRUNCATE`, plus sequence privileges. Assess `RLS`, table/column access, trigger/sequence behavior and provisioning defaults independently. A table having RLS enabled is not blanket evidence that all other table privileges are safe.
4. **RPC contract — HUMAN PRIVACY AND SECURITY DECISION PENDING.** Inventory the 13 exact signatures, defaults, public schema registration, real runtime PostgREST exposed schemas, backend authenticated identity, HTTP route behavior, function-internal actor checks and potential side-effects. Confirm intended public role-helper metadata and E6S D1–D5/privacy restrictions before considering changes.
5. **Technical source — PAUSED.** Four of the 12 audit-caller candidates are Technical controls. Document their dependencies but do not mutate/unpause the T2.4 module or its ACLs.

No `ALTER DEFAULT PRIVILEGES`, `REVOKE`, `GRANT`, public schema move or new SQL migration was executed or introduced during E6Y. In particular, changing default privileges without testing newly created object workflows could break provider discovery and operational application paths; **do not modify the working shared DB to make findings disappear**.

## Future independent G7/G8 staged evidence matrix

| Witness | What must be verified | Current |
| --- | --- | --- |
| G7-23/G7-29 | Anonymous and authenticated real PostgREST direct denial for both internal writers after separately approved fix | **BLOCKED / NOT EXECUTED** |
| G7-30 | Real trusted server audit plus test-only notification enqueue/outbox continuity, separate worker and cleanup witness | **NOT EXECUTED** |
| G7-31 | Correct authorised nested audit under true owner/ACL equivalence versus prohibited direct access | **NOT EXECUTED** |
| G8 default-object parity | Exact matching `pg_default_acl` per owner/schema/object kind and legitimate new object provisioning, synthetic stage-only data and cleanup | **NOT AUTHORISED** |
| G8 RPC publication | Configured schema, effective role grants, PostgREST route discovery, GoTrue session identity and denied side effects | **NOT AUTHORISED** |
| Human gates | Separate Security/Operations/Privacy/DR approval, backup integrity, D1–D5 and G1–G10 signatures | **0/10; NOT SUPPLIED** |

Do not treat `--no-owner --no-acl` disposable SQL as role-equivalent stage. This plan does not add another completed G7 test or grant programme release approval. All **31/31 G7 cases remain unexecuted**.

## Regression and repository boundaries

**EAGLT02 engineering regression PASS:** E6Y synthetic analyser **12/12** (config parsing, missing/invalid settings, role/grant separation, trigger exclusion, writer grants, route scoping, missing/duplicate functions); E6Y source config and local READ ONLY catalogue scan PASS. Detached exact prior checkpoint Flutter source `4de0af5`: **7/7** clean static analyses, Client **132/132**, Operations **43/43**, Technical **38/38** widget tests PASS, process exit 0. Existing E6W/E6V source/caller audit PASS; network-disabled seven-pending-migration cross-stream SQL **301/301 across 16 suites PASS**, all fixture changes ROLLBACK and disposable container removed, persistent shared DB unchanged. Synthetic JWT HTTP negatives **23/23**, E6H independence **106/106**, evidence scanner **101/101** and E6S privacy source/local validators PASS. **No real GoTrue/G8 witness.** Shared combined `npm run db:test` is **NOT claimed green** while pending E6H/T2.4/E6N/E6O migrations remain unapplied.

**Never commit** private `.wantok/e6y-default-acl-local.json` output, secrets, credentials, user rows or source dumps. The stable source code and this worksheet may be committed to the existing feature branch after applicable regressions. Continue into owner-approved *dedicated* staging or non-mutating CX1 preparation only after the outstanding E6 safe engineering checklist; **productionApproved:false**.
