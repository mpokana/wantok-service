# E6U — G8 Privilege-Parity Preflight and Trusted Audit-Worker Continuity

**Checkpoint:** 12 October 2026 PNG | **Authorised machine:** EAGLT02 | **Programme:** Wantok Services (PrjM) | **Scope:** metadata-only READ ONLY catalog of the existing local database plus transaction-rollback synthetic SQL in a disconnected disposable clone. **No customer data, account, shared Supabase, GVE device or production modifications.** G1–G10 **0/10** independently approved, production **NO**.

## 1. What was actually established

E6T reproduced a synthetic anonymous SQL audit-record write on the disconnected **pre-E6O** permission baseline (8/8 pgTAP, rolled back). E6O proposed a source-only migration `20261012152000_e6_shared_internal_rpc_execute_boundary.sql` to REVOKE anonymous/authenticated EXECUTE on two internal writers, `write_audit_event` and `enqueue_notification`, leaving service-role EXECUTE.

E6U closes two **technical** gaps only:

1. New rollback-only `supabase/tests/066_postpatch_trusted_audit_worker.test.sql` **7/7** checks after the proposed E6O fix: `anon` and `authenticated` EXECUTE denied, `service_role` permitted and an *actual fake trusted-worker* SQL-role invocation creates one synthetic audit event. It is rolled back. This is NOT genuine service process/API authentication, nor does it test positive notification delivery.
2. Updated disposable cross-stream harness fingerprints the exact two selected shared writer functions' **OID, SQL body, owner and configured search path** immediately before and after E6O. **Unchanged PASS**; only the EXECUTE grants are intentionally altered. The previous E6N 19-function fingerprint also remains unchanged. This proves invariance **only in the disposable stage**, not owner parity with production.

Combined network-disabled isolated regression: **seven unapplied prospective E6H/T2.4/E6N/E6O migrations, 16 pgTAP files, 301/301 assertions PASS** (including E6T 8 prepatch positive + 286 old postpatch + E6U 7 trusted-worker). All fixtures ROLLBACK, test container removed; persistent local migration ledger and data untouched. Four Technical T2.4 migrations were compatibility fixtures **only**, and Technical implementation remains PAUSED.

## 2. New machine-readable, read-only G8 catalogue

`scripts/qa/e6u-privilege-parity-preflight.mjs --local` queries **only** `pg_catalog` role flags, function ownership/configuration/grants and public-table RLS policy metadata in a PostgreSQL `BEGIN TRANSACTION READ ONLY`. It does **not** inspect application table rows, JWTs, function bodies, private identities or credentials.

| Local EAGLT02 snapshot metric | Observed |
| --- | ---: |
| Selected high-impact exact function signatures | **10/10 present, SECURITY DEFINER** |
| Selected functions with BYPASSRLS-capable owner | **10/10** |
| Selected shared audit/notification writers currently callable by untrusted SQL roles | **2/2** |
| Public base tables | **93** |
| Public tables with RLS enabled | **93** |
| Public tables with RLS forced | **0** |
| Public RLS policies | **117** |
| Local `anon` and `authenticated` roles | Neither is superuser nor BYPASSRLS |
| Local `service_role` | BYPASSRLS enabled |
| Local `postgres` (current owner of selected 10) | BYPASSRLS enabled |
| Local `supabase_admin` | Superuser and BYPASSRLS, used in **test fixture restoration** |

The ten selected functions are the two shared writers plus the eight role/Technical helper signatures from the E6S **proposed, not approved** privacy contract. Existing E6S D1–D5 decisions remain **NOT SUPPLIED**.

**Crucial limitation:** This is a *local metadata snapshot*, **not an exact production/staging parity validation**. The disposable harness deliberately executes `pg_restore --no-owner --no-acl` and reconstructs only specific fixture grants. Its effective owners, exact ACLs, role membership, `BYPASSRLS` semantics, RLS/column grants, default privileges and PostgREST publication cannot be assumed equal to the persistent environment. Although 93/93 tables enable RLS, BYPASSRLS-definer routines still require independent scope checks. No real GoTrue login or user-facing REST witness was performed.

## Regression checkpoint

The E6U detached-source Flutter QA `scripts/flutter/check.ps1` **exit 0**, **seven** static analyses clean; Client **132/132**, Operations **43/43**, Technical **38/38** widget tests PASS. The unchanged main local E6S proposed privacy-contract validators (source-only and PostgreSQL READ ONLY) PASS; local signed synthetic-JWT HTTP negatives **23/23**, E6 independent-case SQL **106/106**, evidence scanner **101/101** PASS. No real GoTrue or independent reviewer witness. No Flutter code changed.

## 3. G8 parity comparison needed before any persistent test/promotion

The separately authorised, backed-up dedicated stage must capture **before and after**:

- Exact PostgreSQL major/minor image and extension versions; schema migration ledger, function identity signatures, current function body hashes, owner name, owner `BYPASSRLS`/superuser flags, effective and explicit EXECUTE grants to `PUBLIC`, `anon`, `authenticated`, `service_role` and privileged application roles.
- All policies/roles relevant to `audit_events`, `notifications`, `notification_outbox`, `profiles`, applicable Operations and marketplace tables, plus FORCE RLS and column-specific privileges; verify no ownership/ACL differences masked by `--no-owner --no-acl`.
- Application POST/REST exposed schemas, RPC overload/default args, real JWT role claims, backend trusted-worker callers, audit event readers, actual app dependencies and expected denial/error response without leaking data.
- Witnessed positive server-worker audit and notification paths; witnessed unauthorised anonymous/ordinary-auth direct RPC denial after the agreed fix. Use only privacy-safe synthetic accounts and stage backups with documented restore/cleanup, protected evidence pointers and independent Security/Operations QA witnesses.
- Independently assess E6K 18 profile + 23 service public column selection, E6R other-person staff-role disclosure, and the Technical `record_technical_module_health_report_internal` exposure **without** silently changing paused T2.4.
- Record separate product/privacy/legal/security decisions and G1–G9 evidence before any G10 go/no-go.

**Stop conditions:** missing authority, backup/restore hash, role/owner/policy equivalence, trusted-key custody, approved privacy/notification contract, independent reviewers, test identities or rollback plan; any unexplained stage privilege difference; service worker regression; unintended data/role/privilege writes. **No stage creation or migration deployment is authorised by this document.**

## 4. Parallel G-series acceptance workboard

Source-of-truth gates: `docs/E6G_FORMAL_ACCEPTANCE_RUNBOOK_20261011.md`. Execution register: `docs/E6G_PARALLEL_ACCEPTANCE_REGISTER_20261012.md`. **G1–G10 remain BLOCKED, 0 signed**, despite the green source/isolated regressions.

Add planned **G7-30**, explicitly **NOT EXECUTED**: verify a *real* authorised backend trusted service-role worker can still record a synthetic audit action and enqueue/complete a test notification on a **separately approved dedicated stage**, while anonymous and ordinary signed-in callers are denied, with observable rollback/cleanup, role parity, Security/Operations witnesses and redacted evidence. This is distinct from existing G7-29 postpatch *negative* direct REST audit-write denial. Actual stage and real GoTrue testing remain gated by G1–G8 owners.

**Programme priority:** E-series P0 active, G1–G10 preparation in parallel, CX1 queued, T2.4 paused, E7+ and production SEALED. This checkpoint does not contain a new SQL migration.
