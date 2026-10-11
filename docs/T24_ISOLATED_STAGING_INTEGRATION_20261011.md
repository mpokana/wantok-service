# T2.4 — Reproducible isolated PostgreSQL staging acceptance

**Date:** 11 October 2026 (PNG)
**Origin:** EAGLT02, feature/flutter-platform-v1, baseline `0fd7ede`
**Scope:** Reproducible schema/API migration integration with no persistent SQL changes to the app's Supabase database and no online VM interaction. **T2.4 IN PROGRESS**, not browser/user acceptance or production deployment.

## New QA runner

`powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\scripts\qa\t24-isolated-staging.ps1`

- Starts a **fresh disposable** `public.ecr.aws/supabase/postgres:17.11.0.002` container with `--network none`, no exposed host ports, 1024 MiB RAM cap and tmpfs database; random local password. Automatically stops and removes it after the checks, including most error paths. Debugging can explicitly retain the container using `-KeepContainer`.
- Uses `pg_dump --schema-only --no-owner --no-acl` to copy structural definitions (including the installed pre-T2.4 E6 functions) from local Supabase. **No source data from auth.users, profiles, payments, notifications, or messages is copied.** Only five small non-personal technical reference tables are exported: `app_roles`, `technical_modules`, `technical_access_levels`, `technical_permissions`, `technical_access_level_permissions`.
- Restores into a brand-new `t24_stage` database, grants the minimum test-harness access to schemas and pgTAP functions for `authenticated`, then applies the two T2.4 migrations in order:
  1. `20261011240000_technical_scoped_health_log_adapter.sql`
  2. `20261011241000_technical_messaging_queue_snapshot.sql`
- Executes `090_technical_scoped_health_log_adapter.test.sql` and `091_technical_messaging_queue_snapshot.test.sql` with `ON_ERROR_STOP=1`, checks that pgTAP returns the expected number of **ok** results and no **not ok** output; unlike plain psql exit status, this detects negative pgTAP assertions. Both test files are themselves transaction-wrapped and roll back synthetic users, grants and sample outbox rows.
- Verifies **both RPCs remain installed in the isolated DB**, all synthetic fixture users and notification-outbox records are absent, and the shared application database still has **neither T2.4 RPC** installed. Deletes temporary schema/reference dump files; default container cleanup confirmed.

## Test results

- Initial manual isolated staging restore encountered stock Supabase role/ACL differences; resolved with a clean `template0` database restored as `supabase_admin`, with test-role grants applied explicitly. This restore approach intentionally differs from exact production table/function ownership and ACLs. Do **not** claim byte-for-byte production permission parity.
- Verified initial manual run on separately network-disabled isolated DB: **12/12** Log and **13/13** Messaging queue pgTAP assertions PASS with both new functions installed. Both SQL suites rolled back their data; source Supabase RPCs absent.
- Automated fresh run of `t24-isolated-staging.ps1`: exit 0, same **2 migrations and 25/25 pgTAP assertions PASS**, fixtures absent, source database unchanged, disposable container removed. No real credential or customer content copied.
- Standard `npm run db:test` attempted in the isolated Git checkout; first attempt blocked by missing local `supabase.cmd` CLI path (present only in the main worktree's node_modules). Reran with that executable on PATH; **58-file runner FAILS only at tests 090/091 because both RPC migrations are purposefully unapplied to shared Supabase**. Earlier tests 001–057 complete; reported 58 files, 1143 encountered assertions, with two missing-RPC pgTAP files short of their full plans. **This is NOT a global SQL PASS**.
- Clean detached checkout `0fd7ede` **full `scripts/flutter/check.ps1` PASS (exit 0): seven analysis targets / 132 Client / 43 Operations / 28 Technical widget tests.** This includes the existing protected Logs and Messaging queue UI code; no browser interaction or database migration is implied.

## Security / remaining limitations

- No Supabase production/staging Web sign-in, GoTrue account session or actual PostgREST API role assertion was performed. Only synthetic PostgreSQL role/pgTAP checks passed.
- Schema restored without owner/ACL mapping; **production SECURITY DEFINER function ownership and grants require separate review**, as do real RLS privileges, host TLS, staging API publication, log-source retention and performance of whole-outbox COUNT queries.
- The actual running local Technical Control `:3100` and older `:3600` preview were not rebuilt or changed. No real message delivery is implied by `sent` status; no live worker heartbeat, central log ingestion, job retry/cancel/run, provider activation, KYC, payments or online VM work.
- Keep the two migrations un-applied to shared Supabase until separately authorised, backed-up real staging migration. Browser sign-in and full 58-file SQL suite must be rerun on correctly migrated dedicated staging before release.

## Next T2.4 tasks

1. Harden exact-role/ACL test fidelity and add dedicated authenticated PostgREST staging role matrix without copying real credentials.
2. Define safe allowlisted central/module log provenance and retention with server-side scope/redaction and audit.
3. Add actual worker liveness and per-module queue adapter metadata, with freshness and costs; no job execution without independent policy and explicit approvals.
