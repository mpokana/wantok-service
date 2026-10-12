# E6O — Full Public-Schema SECURITY DEFINER Inventory and Internal RPC Guard

**Date:** 12 October 2026, Papua New Guinea. **Device:** authorised EAGLT02 only. **Scope:** read-only catalogue plus source-only hardening validated in network-disconnected disposable SQL. **Disposition:** security finding reproduced at privilege-metadata level; mitigation validated in isolated stage; **NOT applied to shared local Supabase, real staging or production**. **G1–G10: ALL BLOCKED.**

## 1. Scope expansion beyond selected E6 functions

The E6J–E6N reviews explicitly checked **19 selected** Operations functions. New `scripts/qa/e6-public-definer-surface.mjs --local` inspects `pg_catalog` metadata for **all** local `public` `SECURITY DEFINER` functions with a PostgreSQL **READ ONLY** transaction; it does not access function bodies, data rows, tokens or personal records.

| 12 Oct local snapshot | Count |
| --- | ---: |
| Total `public` SECURITY DEFINER functions | **152** |
| Owned by a role with BYPASSRLS | **152** |
| `anon` can EXECUTE | **95** |
| `authenticated` can EXECUTE | **133** |
| `service_role` can EXECUTE | **152** |
| Explicit function search_path configured | **152** |
| Explicit `pg_temp` last | **0** *in the currently applied local database* |

**Meaning:** EXECUTE permissions alone do not establish an exploit. Many of the functions are deliberately public-facing, while their bodies may enforce identity and tenancy. The 19-function E6N search-path source migration remains **unapplied**; therefore the live *local* 0 value is expected. The 152-function catalog is limited to `public` schema; functions in `auth`, `storage`, extensions and additional future migrations are not covered.

## 2. Specific internal shared RPC grant discrepancy — G8 finding E6O-01

The running local catalogue showed that `public.write_audit_event` and `public.enqueue_notification` both have explicit EXECUTE privileges for `anon` and `authenticated`, and run as privileged definer owner `postgres`. The checked-in `20261005010000_enterprise_platform.sql` originally specifies **only** `service_role` EXECUTE for these internal helpers, but its `REVOKE ... FROM PUBLIC` alone does not remove the explicit `anon` and `authenticated` grants observed in this running local database.

Both current SQL bodies perform internal writes under the definer without a separate caller check; the audit writer additionally accepts a supplied actor identifier. This is a **potential audit-integrity and notification-abuse risk** if reachable by untrusted API roles. Actual hostile requests through PostgREST, real login sessions, and production access were **not attempted or asserted**. No private records were read; no non-synthetic rows were inserted.

**Conservative source-only remediation**, proposed as `supabase/migrations/20261012152000_e6_shared_internal_rpc_execute_boundary.sql`: explicitly REVOKE EXECUTE from `PUBLIC`, `anon`, and `authenticated` for these **two** infrastructure helpers, and explicitly preserve `service_role` EXECUTE. No function SQL body, owner or RLS policy is changed. The checked-in app does not call these two functions as direct Client RPCs; other privileged routines invoke `write_audit_event` under their definer privileges, so compatibility has been regression-tested in a disposable database. **Independent G8 approval and backed-up parity stage remain prerequisites for any persistent migration.**

### Separate Technical Control review — G8 finding E6O-02

The local catalogue also exposes `record_technical_module_health_report_internal` to untrusted roles. Its name and body indicate a privileged health-report writer. **No T2.4 source, Technical grants, internal worker or migration was changed.** Its exact caller model and expected trusted-only grants require the Technical owner/independent G8 reviewer before any corrective change. Existing `Technical` widget tests do not establish this RPC is safe.

Other potentially sensitive callable names (role grants/revocations, Technical controls, admin visibility/publishing, branding and account changes) were flagged for **manual function-body/role checks**; many explicitly verify current roles, and an anonymous EXECUTE grant does not by itself bypass those checks. Do not blanket REVOKE all public functions without an API compatibility and role analysis.

## 3. Disconnected staging acceptance (source-only)

Existing `scripts/qa/e6-crossstream-isolated-staging.ps1` clones **schema and seven non-personal reference tables** into a temporary `--network none` PostgreSQL with no published ports. The shared database remains untouched. It applies **seven pending source migrations** in order: E6H (1), Technical T2.4B–E (4; compatibility only), E6N (1), and E6O (1), all **only in the disposable environment**.

Because its `pg_restore --no-acl` intentionally omits original grants, the isolated harness explicitly reconstructs the **observed local** `anon`/`authenticated` EXECUTE baseline for these two helpers. Before E6O it checks both can be executed at the ACL layer, then applies the narrow REVOKE+GRANT migration. New `supabase/tests/061_internal_rpc_execute_boundary.test.sql` verifies both untrusted roles are denied, `service_role` retains EXECUTE, definitions remain definer functions with explicit paths, and **actual direct calls under anonymous and signed-in SQL roles fail with SQLSTATE 42501**. All synthetic tests run inside transaction rollback and no real notification or audit event is created.

**Important parity limitation:** the fixture is not a complete clone of real ownership, ACL, role memberships or all current data. E6O direct role assertions in a disconnected database do **not** equal witnessed signed-in PostgREST/GoTrue G7 testing. Only two shared helpers are addressed, not all 95 anonymously callable functions. E6N's earlier staged function-body/owner/ACL fingerprint checks continue to protect the 19 selected Operations routines.

### E6O checkpoint regression scorecard

- Expanded local `npm.cmd run test:e6:definer-surface-local` **PASS as inventory**, with **152** definer entries and three open internal-helper ACL findings. A successful inventory script is not an all-clear finding.
- Network-disabled seven-migration SQL stage: **220/220 PASS** across **11 SQL files**, including **14/14** direct ACL/denied-call cases in test 061 and the previous 25/25 E6N search-path checks. Fixture grants explicitly reconstruct the two known untrusted EXECUTE grants before the E6O REVOKE test. Source database unchanged, all fixtures rolled back, container removed.
- Unchanged main's local synthetic-JWT HTTP negative boundaries **23/23 PASS**, E6 independence **106/106 PASS**, evidence scanner **101/101 PASS**, read-only E6L function catalogue baseline **PASS**.
- Exact-source detached E6O Flutter `scripts/flutter/check.ps1` returned exit **0**: **seven static analyses clean**, **Client 132/132, Operations 43/43, Technical 38/38** widget tests PASS. No Flutter files changed.
- Shared combined SQL suite is intentionally **not claimed green**: seven prospective source migrations are not in persistent local schema ledger. External genuine GoTrue signed-in/browser tests and G1–G10 independent approvals remain blocked.

## 4. G1–G10 parallel evidence and blocking conditions

The gate authority is `docs/E6G_FORMAL_ACCEPTANCE_RUNBOOK_20261011.md`; the working evidence queue is `docs/E6G_PARALLEL_ACCEPTANCE_REGISTER_20261012.md`. **All ten gates remain BLOCKED.** Use this E6O report as a G8 independent review input, **not** a signed G8 PASS.

- **G1–G3:** obtain real HR delegation, separate requester/approver, provenance for the original trusted bootstrap and service-role secrets; no fictitious verification references.
- **G4–G6:** obtain maintained ISO+country geography, legal category approval, beneficial ownership/COI/recusal evidence from independent reviewers.
- **G7:** separately approve dedicated staging with genuine isolated GoTrue test identities; witness all 18 positive/negative browser plus direct API cases. Current negative synthetic JWT tests do **not** satisfy G7.
- **G8:** independently audit the full 152-function exposed surface including trigger versus public callable, nested definer paths, audit/notification/Technical internal helper grants, effective owner privileges and E6K public column privacy. Verify exact role/owner/ACL parity before promotion.
- **G9–G10:** witness backup, restore, revocation/offboarding and independent signed go/no-go after all earlier gates pass.

## 5. Promotion/rollback (NOT executed)

The intended least-privilege correction can be reverted *only in separately approved staging* by restoring captured, individually justified EXECUTE grants from its prechange snapshot. Reopening untrusted access to an internal writer is not recommended without independent security review. Do not run migrations or revoke trusted keys in the existing shared DB. Treat any newly discovered external dependency on direct audit/notification RPC calls as a stop condition requiring authorised owner decision and compatibility test.

**Programme:** E-series P0 ACTIVE; G1–G10 evidence preparation PARALLEL and 0/10 approved; CX1 queued, T2.4 paused; E7+, sensitive KYC/payment and production remain blocked.
