# E6N — Privileged Search-Path Hardening (SOURCE / ISOLATED QA)

**Checkpoint:** 12 October 2026 PNG. **Repository/branch:** `mpokana/wantok-service`, `feature/flutter-platform-v1`. **Authorised device:** EAGLT02. **Disposition:** source-only prospective migration + disconnected SQL tests; **NOT applied to shared Supabase or production**. G1–G10 formal gates **ALL BLOCKED**.

## Why a narrow change was proposed

E6J–E6M independently recorded 19 *selected* Enterprise/Operations `SECURITY DEFINER` functions. Their local database owners are `postgres` with `BYPASSRLS`, function grants currently prevent anonymous EXECUTE, and the selected checked-in SQL uses schema-qualified relation references under a limited lexical scan. All selected routines had an explicit `search_path=public,auth` but no explicit final `pg_temp`. Ordinary roles lack CREATE in the inspected permanent schemas but have database TEMP permissions. These facts justify **defence-in-depth**, not a confirmed exploit.

PostgreSQL's own SECURITY DEFINER guidance recommends searching trusted schemas followed by an explicitly last `pg_temp`: https://www.postgresql.org/docs/current/sql-createfunction.html. This is not a substitute for independent body/call-graph review or service-role key custody verification.

## Implemented source (unapplied)

- New migration: `supabase/migrations/20261012140000_e6_operations_definer_search_path.sql`.
- **Exactly 19 explicit `ALTER FUNCTION public.<name>(<signature>) SET search_path=public,auth,pg_temp` operations**, wrapped in one SQL transaction. The migration is ordered **after** the pending E6H `20261011233000` replacement definitions.
- It intentionally changes **only** the per-function path configuration. It does **not** modify function source bodies, change the function owner/EXECUTE grants, switch RLS, activate any provider, collect KYC material, or create any account.
- New `supabase/tests/060_operations_definer_temp_path.test.sql`: **25/25** pgTAP assertions in disposable SQL to check all 19 exact paths, the selected function inventory, no unauthorised anonymous/trusted bootstrap grants, a preserved requester grant, service-role trusted use and denial of an unauthenticated scope claim.
- Existing `scripts/qa/e6-crossstream-isolated-staging.ps1` extends the existing five E6H/T2.4 pending SQL migrations to six, and 9 tests / 181 assertions to **10 files / 206 assertions**. The four T2.4 migrations remain **compatibility fixtures only**, not an unpause of Technical Control.

## Isolation and precise limitation

Harness copies local **schema only and seven non-personal reference tables** into a fresh Postgres container using `--network none` with no published ports, then applies six migrations there only. Synthetic pgTAP fixtures rollback. It verifies the source DB still lacks those pending migration ledger entries and relevant RPCs, and it removes the disposable container.

The first E6N stage run failed two function grant assertions because its schema restoration intentionally uses `pg_restore --no-acl`; the missing EXECUTE restrictions were **test-fixture ACL differences**, not confirmed shared database grants. The isolated fixture grant reconstruction was amended for `configure_operations_provisioner` and `decide_operations_duty_change` to match their observed current local role privileges. On rerun **206/206 PASS**, shared DB unchanged.

An additional pre/post-stage fingerprint over the **19 selected functions' owner ID, ACL text, SQL body hash and OID** remained exactly identical while applying the new ALTER migration: `E6N_19_FUNCTION_BODY_OWNER_ACL_UNCHANGED=true`. This verifies intended non-mutation *within the disposable stage*, **not production owner/role/ACL parity**. It cannot certify all functions, full PostgreSQL SQL semantics, registered human reviewers, real GoTrue sessions, recovery or a production release.

### Additional regression check

Additional unchanged-main-E6 regressions were rerun: **23/23 local signed synthetic-JWT HTTP negative boundaries**, **106/106 E6 case-independence SQL assertions**, **101/101 evidence-scanner assertions**, and the E6L read-only function-trust catalogue check PASS. These are not independently witnessed positive GoTrue sessions.

The full detached source `scripts/flutter/check.ps1` completed **exit 0**, with **seven clean static analyses** and all **132 Client, 43 Operations and 38 Technical** widget tests PASS. No Flutter app code changed. These tests are source regressions and not a real browser/GoTrue user witness.

### Rollback and promotion conditions (proposal; not executed)

The intended rollback for a separately authorised stage is to restore each function's previous proven `search_path`, or restore the captured function metadata/backup. **Do not run such rollback on the shared database now**. Before any persistent change, obtain G8 independent review of original and replacement per-function grants, effective ownership/role membership and body/call graph; verify positive/negative PostgREST/GoTrue tests in an independently authorised, backed-up, parity-equivalent stage; capture witness and rollback evidence outside GitHub; and have security and product owners determine release readiness separately.

## G1–G10 acceptance preparation, genuinely parallel

The **authoritative ten gates remain** `docs/E6G_FORMAL_ACCEPTANCE_RUNBOOK_20261011.md`. The live workboard remains `docs/E6G_PARALLEL_ACCEPTANCE_REGISTER_20261012.md`.

| Gate grouping | Safe work now | What still blocks an independent PASS |
| --- | --- | --- |
| **G1–G3** HR, two-person authority, trusted bootstrap | Capture empty scoped evidence templates and code-level negatives | Actual HR delegation, different human signatories, verified custody of trusted keys, bootstrap provenance |
| **G4–G6** geography, service legal map, related party | ISO/sector review worksheet and synthetic recusal QA references | Current legal/ISO source attestation, actual restricted-service policy, independent COI investigation and witness |
| **G7** authenticated tenancy | Exact 18-case GoTrue/PostgREST role matrix and expected denial/positive outcomes | Dedicated approved staging, real separate test identities, browser + direct API witnessed sessions and clean-up |
| **G8** application security | E6J–E6N catalog/source findings, prospective pg_temp migration, 206/206 isolated SQL evidence, exception register | Independent full privileged call-graph/RLS/ACL review and test of real API bypass and stage owner parity |
| **G9** incident/recovery | Backup, key rotation, expiry/offboarding rehearsal plan | Witnessed restore and revocation/refresh test with DR/security officers |
| **G10** final release | Collate safe references to above evidence | G1–G9 independently PASS and product + security/compliance signed go/no-go |

**No reviewer identities, approval dates, test tokens or fake acceptance results have been entered. Current external disposition: 0/10 gates approved.**

## Next safe priorities

1. Review all *other* relevant SECURITY DEFINER routines/overloads, nested calls, expression/operator/type resolution, and the approved provider public-column privacy contract. Selected 19-function static review cannot cover all E-series paths.
2. Prepare G7/G8 independent staging authorisation and the 18-case test witness evidence intake in secure storage without creating accounts or bypassing the separate human approvals.
3. Preserve programme order: **E-series P0 ACTIVE; G1–G10 preparation PARALLEL; CX1 P1 QUEUED; T2.4 P2 PAUSED.** No shared DB migrations, real user/provider/payment changes or production deployment.
