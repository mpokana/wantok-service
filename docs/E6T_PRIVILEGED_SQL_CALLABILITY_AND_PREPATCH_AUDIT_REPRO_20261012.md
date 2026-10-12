# E6T — Privileged SQL Callability and Prepatch Audit-Writer Reproduction

**Checkpoint:** 12 October 2026 PNG | **Authorised device:** EAGLT02 | **Scope:** code, read-only local function metadata, isolated rollback-only synthetic SQL. **No shared persistent database writes, no direct HTTP/GoTrue test, no production deployment.** G1–G10 **0/10 approved**. This is a technical G8 finding update, **not a G8 sign-off**.

## 1. Distinguishing EXECUTE grants from direct SQL callability

Source `scripts/qa/e6-privileged-callability.mjs --local` performs a PostgreSQL `BEGIN TRANSACTION READ ONLY` catalog inquiry against `public` SECURITY DEFINER routines, classifying each by effective SQL role EXECUTE and whether it returns PostgreSQL `trigger`. It reads no function bodies, user rows, account data or credentials.

| Read-only local catalog metric | E6T observed |
| --- | ---: |
| `public` SECURITY DEFINER functions | **152** |
| `anon` effective EXECUTE | **95** |
| `anon` effective EXECUTE, trigger return | **6** |
| `anon` effective EXECUTE, non-trigger return | **89** |
| `authenticated` effective EXECUTE, non-trigger return | **127** |

The six trigger-return functions cannot be directly called as ordinary SQL RPCs by clients, even when they show an EXECUTE ACL. **89 is only a triage universe, not 89 confirmed public HTTP endpoints.** Check explicit PostgREST exposed schema, function argument types and overloads, callable application context, nested grants and actual HTTP access on a separately approved stage. Likewise, ordinary public functions may correctly enforce `auth.uid()` within their bodies. All 152 remain subject to independent G8 review, including owner privilege and name resolution.

Examples of apparently internal or privileged names with untrusted effective SQL EXECUTE include `write_audit_event`, `enqueue_notification`, `record_technical_module_health_report_internal`, `refresh_technical_module_health_state_internal`, `grant_user_role`, `grant_technical_module_access` and `set_technical_module_state`. A name or grant is not by itself an exploit. Technical functions are **investigation-only** while T2.4 is paused.

## 2. E6T-01: rollback-only positive SQL evidence for E6O-01

The previous E6O stage showed both `public.write_audit_event` and `public.enqueue_notification` carried untrusted EXECUTE grants in the current local database, despite original source specifying trusted server-only grants. E6T adds `supabase/tests/065_prepatch_audit_writer_reproduction.test.sql`, invoked **only** within the fresh `--network none` disposable test container **after rebuilding the known local test-only ACL baseline but before the proposed E6O migration**.

Test `065` uses a transaction, a synthetic audit action `E6T_SYNTHETIC_PREPATCH_QA`, a NULL actor, and `SET LOCAL ROLE anon`. It proves **8/8**: precondition with zero synthetic rows, the relevant observed untrusted EXECUTE permissions, the fact that a synthetic anonymous SQL-role call to the definer audit helper completes, exactly one synthetic audit row exists in that transaction, and no authenticated actor is required. It then issues **ROLLBACK**. No real person, company or actual data row is used or kept.

After this positive prepatch reproduction, the same isolated harness applies pending E6H + T2.4 compatibility + E6N + **E6O** migrations and reruns post-patch test `061`. Its **14/14** checks ensure anonymous/authenticated direct SQL audit and notification calls are denied (42501), with service-role EXECUTE retained, and prior function search-path/owner checks unchanged.

**Evidence hierarchy:** E6T proves a reachable privileged write under a *local synthetic anonymous SQL role in a disconnected database*. It **does not prove** browser or PostgREST anonymous invocation, production deployment, a live attack, forged production logs, or material operational impact. The unmodified current local DB *does* expose the corresponding EXECUTE grants, but no actual call was made to that persistent DB. The audit integrity threat therefore remains an OPEN serious G8 issue to resolve before public release.

## 3. Isolated integration and regression

- `npm.cmd run test:e6:crossstream-local`: **7 proposed migrations, 15 SQL suites, 294/294 pgTAP assertions PASS**, including `065` 8/8 prepatch and existing 14 post-migration suites 286/286. Positive synthetic audit write was ROLLED BACK, all other fixtures rolled back, no entries or new RPCs persisted in shared DB, and disposable container removed.
- `npm.cmd run test:e6t:callability-local`: read-only catalog **PASS**; 95 anonymous SQL grants partition into 6 trigger returns and 89 non-trigger returns. Only `public` schema is considered.
- Unchanged main: proposed E6S privacy contract source-only and PostgreSQL READ ONLY validators PASS; signed synthetic-JWT negative HTTP **23/23 PASS**, E6 independent-case **106/106 PASS**, evidence scanner **101/101 PASS**. These are not real G7 sessions or human decisions.
- Exact-source detached E6T Flutter `scripts/flutter/check.ps1` **exit 0** after supplying a missing Windows `ProgramFiles(x86)` environment variable *only for the test process*: seven static analyses clean; Client **132/132**, Operations **43/43**, Technical **38/38** widget tests PASS. Initial run had failed at Flutter test setup because the variable was missing despite seven clean analyses; no Dart source change was needed.
- G8 finding E6O-01 mitigation remains **SOURCE ONLY** (`20261012152000_e6_shared_internal_rpc_execute_boundary.sql`). Applying it to the shared database, production, or backed-up stage still requires explicit separate authority, exact owner/ACL/RLS role parity, rollback proof, independent application security sign-off and real GoTrue/PostgREST positive/negative tests.
- Existing E6S D1–D5 policy choices and S-01–S-09 stage preflight remain **NOT SUPPLIED / NOT EXECUTED / BLOCKED**. E6K public provider-field privacy, E6O-02 Technical internal report, E6R cross-person metadata remain OPEN.

## 4. Parallel G1–G10 acceptance preparation

The authoritative runbook is `docs/E6G_FORMAL_ACCEPTANCE_RUNBOOK_20261011.md`; the register is `docs/E6G_PARALLEL_ACCEPTANCE_REGISTER_20261012.md`.

New **G7-29 PLANNED / NOT EXECUTED**: on an independently authorised, backed-up dedicated staging environment, have Security QA and Operations QA witness that an anonymous client cannot invoke the audit writer over the published REST API after the independently approved mitigation, with an independently witnessed positive internal trusted-worker path. Capture request/result (redacted), stage migration and exact role-grant parity, rollback, audit checks and cleanup in private evidence storage. **Do not test a positive arbitrary public audit write on a real/shared environment.**

All **G1–G10 remain 0/10 approved**. No HR, legal, geography, COI, key-custody, real GoTrue, security, DR or release sign-offs have been invented or inferred.

**Programme:** E-series P0 active; G1–G10 evidence preparation parallel; CX1 queued; T2.4 paused; production and E7+ sealed. No GVE resources affected.
