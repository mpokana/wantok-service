# E6M — Latest SECURITY DEFINER Source Review (Selected E6 Operations)

**Checkpoint:** 12 October 2026 (PNG) | **Scope:** source-only review on EAGLT02, `feature/flutter-platform-v1` | **Result:** 19-function static baseline PASS; **independent semantic/source-owner review and formal G7/G8 remain BLOCKED**.

## Reproduce and boundaries

Run `npm.cmd run test:e6:source-definers` from the tracked repository. New source-only scanner `scripts/qa/e6-source-definer-review.mjs` uses the migration order and checks the **latest checked-in definition** for 19 explicitly selected E6 privileged functions (including `CREATE FUNCTION` and `CREATE OR REPLACE FUNCTION`). It does NOT connect to a database, read customer records or keys, modify roles or execute privileged SQL. It flags obvious unqualified relation references and `EXECUTE` in these bodies. This is **a conservative lexical aid, not a PostgreSQL parser or security certificate**. The local E6L catalogue audit remains a separate observation of the *currently applied* function metadata.

### Current findings

- **19/19** selected latest source definitions contain `SECURITY DEFINER` and explicitly configure `search_path=public,auth`.
- Scanner finds **zero obvious unqualified FROM/JOIN/UPDATE/INSERT INTO/DELETE FROM relation references** in the latest source definitions and **zero explicit `EXECUTE` dynamic SQL statements**. All cases require human inspection for expression/alias, function/type lookup, implicit operators, nested calls, privilege escalation and unsafe data access.
- **Two source definitions are ahead of shared local DB**: E6H `20261011233000_operations_independent_case_review.sql` replaces `public.has_operations_case_scope(text,uuid)` and `public.has_operations_clearance_scope(text,uuid)`. The E6H migration is pending; do NOT claim that current local GoTrue/API behaviour represents those new definitions.
- Direct source spot-check: `public.request_operations_duty_change` binds `v_actor:=auth.uid()`, requires active country-matched requester, enforces different grant subject, verifies region and expiry, and records events; `public.decide_operations_duty_change` requires a different active approver, disallows requester/subject, checks duplicate/expiry, and writes signed-in actor events. These are *observed safeguards*, not an independent G2 sign-off. `public.configure_operations_provisioner` is restricted by current local function ACL to service-role use but takes an externally supplied `p_verified_by` identifier: **trusted bootstrap provenance requires human G3 verification**, not inference from the function body.
- Source spot-check: `public.admin_set_provider_service_status` explicitly denies `active` and permits a scoped safety pause; `public.review_provider_application` raises a denial. These restrictions remain security-critical legacy boundaries for future direct REST tests.
- All selected functions currently run under a local `postgres` owner with `BYPASSRLS`, based on the read-only E6L local catalogue. Their internal identity, duty, recusal and cross-case checks are therefore important despite static qualified-name findings.
- **No explicit trailing `pg_temp` in the selected search paths.** PostgreSQL documentation recommends placing temporary schema last for SECURITY DEFINER functions, even when normal schemas are locked from untrusted CREATE. This is a hardening-review issue rather than proven exploitation of these functions; current SQL source is largely schema-qualified. Reference: https://www.postgresql.org/docs/current/sql-createfunction.html (Writing SECURITY DEFINER Functions Safely).

### Important parser limitations and correction

A first pass of the lexical check falsely flagged `ON CONFLICT DO UPDATE SET` and `IS NOT DISTINCT FROM p_region` as table references. The scanner now specifically excludes those expressions rather than treating them as attacks. It still cannot resolve SQL ASTs, overloads, transient objects/types, operators, CTE semantics, entire call graphs, trusted key custody, or actual signed-in role behaviour. **Zero scanner flags does not mean zero vulnerabilities.**

## G8 remediation decision queue (proposal only; no migrations applied)

1. **Complete call-graph/ownership review:** inspect each chosen function body, every function it calls, nested RLS/business invariants, error behaviour, `auth.uid()` trust assumptions, inputs and table/grant parity; expand outside the selected 19 functions where necessary.
2. **Harden function path in an isolated replica only:** evaluate a minimal follow-up migration `ALTER FUNCTION ... SET search_path=public,auth,pg_temp` for exact signatures. First demonstrate unchanged positive and negative synthetic cases in a network-disconnected ephemeral DB with role/owner parity. **Do not apply to the shared local DB** or assert an exploit.
3. **Check actual caller channels:** real GoTrue sign-in with different profiles and a separately approved staged DB must test ordinary public REST, legacy approval RPC denial, provisioning, role expiry, recusals, consent/evidence seal, owner/subordinate cross-scope and forged JWT. Existing signed synthetic JWT 23/23 negatives and SQL 181/181 are useful automated support, **not witnessed G7/G8 acceptance**.
4. **Approve exceptions/redaction before privilege narrowing:** E6K public marketplace policy still exposes all columns for qualified public rows. Decide public field projections and compatibility migration separately; no blanket anonymous SELECT removal.
5. **Independent sign-off:** G8 independent application-security reviewer reviews reproducible metadata/source logs, exact stage ACL and rollback, documented exceptions and attack-surface limitations; only then may a human change G8 status.

## QA evidence at this E6M checkpoint

- Source-only scanner `npm.cmd run test:e6:source-definers` **PASS** (19/19 selected latest source definitions, zero simple unqualified table refs, zero explicit dynamic SQL, two E6H source definitions pending application).
- E6L/E6K local catalogue inventories **PASS within stated metadata scopes**; no real records or secrets read.
- Disconnected five-migration SQL staging **181/181 assertions PASS** across nine suites. Synthetic records rolled back, original persistent local Supabase DB unchanged and temporary PostgreSQL container removed. The four T2.4 migrations were used **only** for E6 compatibility regression; T2.4 development remains paused.
- Main repository synthetic signed-JWT HTTP negative tests **23/23 PASS**, E6 independent-case SQL **106/106 PASS**, evidence scanner **101/101 PASS**. These do not establish genuine signed-in GoTrue G7 evidence.
- Exact-source detached E6M Flutter `scripts/flutter/check.ps1` **exit 0** with **7/7 analyses clean**, **Client 132/132**, **Operations 43/43**, **Technical 38/38** widget tests PASS.
- The shared persistent combined SQL suite is **NOT claimed as passed**, as five SQL migrations are still absent from the shared ledger. No production approval, human attestation or remote deployment.

### Scope/status

- Code/QA source static selected 19: **PASS** for reported simple checks. Extended analysis/owner parity and G7/G8 human approval: **NOT COMPLETE**.
- Shared local migrations: five source migrations pending; no migration, profile, account, provider listing, payment, identity evidence or production change.
- **E-series ACTIVE**, **G1–G10 preparation PARALLEL / all formal gates BLOCKED**, **CX1 QUEUED**, **T2.4 PAUSED**.
