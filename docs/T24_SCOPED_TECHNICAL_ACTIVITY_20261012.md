# T2.4 — Module-scoped Technical Activity audit (12 October 2026)

**Scope:** Additive read-only Technical Control activity feed from existing `public.audit_events`. Code and QA **only**, not applied to shared Supabase, local served Web UI, public staging or online VM.

## Source and intended trust boundary

The existing database already writes audit actions for technical module state, typed configuration updates, and technical module access grants/revocations. The shared audit table also carries actor UUIDs, target identifiers, request IDs, free-form metadata, sensitive configuration metadata, provider/Operations audit and other information. The new adapter must **not** treat that table as unrestricted central logs or expose private audit fields.

Migration `20261011242000_technical_scoped_activity_audit.sql` adds `list_technical_module_activity(p_module_key, p_limit)`:

- Authenticated caller must have **both** `module.view` and `module.logs` for **that specific module** checked in PostgreSQL; anonymous, view-only and other-module callers fail closed.
- Server returns latest **1–30** events only, ordered by timestamp and identity key. The selected records must match an exact `metadata.module_key` and a **hard-coded allowed pair** of action/entity: module state changed, module configuration changed, module access granted, or module access revoked.
- Response has **only** `id`, `occurred_at` and `action_code`. No actor identity, recipient/target UUID, changed field, before/after values, role metadata, free-text message, request ID, applicant/Operations/customer event or arbitrary log text.
- SECURITY DEFINER uses an explicit search path; PUBLIC/anon function EXECUTE revoked; authenticated role receives EXECUTE, with permission checks made inside function. No direct table grant or source writes.
- This is **Technical action-history provenance** from an existing audit table, not an immutable/signed audit store, live worker health, central application/container logs or an independently verified monitoring/retention system.

## UI and typed client

- New `TechnicalActivityPage`, reachable by a separate module card only if the user has module.view plus module.logs. The page also checks both capabilities before making its first network request; backend is authoritative.
- Real RPC `TechnicalControlRepository.loadModuleActivity` returns a typed `TechnicalActivityEvent`, rejecting invalid action codes, timestamps and IDs. UI shows fixed safe action labels, UTC recorded time, bounded 30 records, read-only Refresh and generic errors with Retry; no writing, role edits, job execution or actions.
- Empty activity is explicitly **not** interpreted as absence of all events. No attempt to show unknown/operational activity as technical records.

## Verified QA and caveats

- Updated `scripts/qa/t24-isolated-staging.ps1` to restore non-personal technical references into a network-disabled PostgreSQL instance, apply **three** T2.4 migrations in order, run **12 + 13 + 14 = 39 pgTAP assertions** on three rollback-only test suites, prove synthetic test users/queue rows removed, prove shared DB still lacks all three RPCs, and remove the disposable test container. **PASS, exit 0**.
- New `092_technical_scoped_activity_audit.test.sql` validates 14 backend tests: auth, permission, server cap, narrow fields, action allowlist and exclusion of unrelated Operational/unapproved records. **14/14 PASS** in the isolated persistent staging schema with the two earlier T2.4 migrations.
- New Technical Activity widget/model test suite **6 PASS**, responsive at 390/1200 widths, refresh, denied-role no-read, zero-event caveat, safe error/retry and invalid event parsing.
- Full clean isolated Flutter `scripts/flutter/check.ps1`: **PASS (exit 0)**, seven analyses, **132 Client / 43 Operations / 34 Technical** widget tests. New Technical Activity focused suite **6 PASS**. This is source QA only, not browser acceptance.
- Ran ordinary shared database `npm.cmd run db:test` from this checkout with the main worktree's Supabase CLI on PATH: **FAIL, as expected**, 60 SQL test files; unapplied E6H migration causes 057 assertions to fail and unapplied T2.4 migrations cause 090, 091 and 092 to fail. This is **not** a global SQL PASS. Staging schema uses test-specific `supabase_admin` function ownership/test grants, **not guaranteed exact production owner/ACL parity**. Real signed-in Auth/PostgREST/Technical browser testing and full migrated SQL suite are still open.

## Next gates

- Review module-scoped audit retention, record integrity, source allowlist, ownership/grants, time-bounded cursor pagination, logging of audit reads (without logging secrets), and workload indexing for large installations.
- Establish approved central system log contracts (source provenance, retention and redaction) and verified worker-heartbeat infrastructure independently; no fabricated queue-running status.
- Deploy only into separately approved, backed-up real staging with real role-bound authentication after the E6H migration ordering is reconciled; full regression and security matrix before any further release.
- Run/Retry/Cancel jobs, provider/KYC workflows, live database updates, online VM, payment and production remain gated.

**T2.4 remains IN PROGRESS.**
