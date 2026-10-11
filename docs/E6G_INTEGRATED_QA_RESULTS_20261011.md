# E6G Integrated Acceptance — QA Evidence

Date: 11 October 2026  
EAGLT02 / `feature/flutter-platform-v1`  
Source checkpoint: `3958e10` (read-only HTTP auth, runbook and living roadmaps).  
Independent detached worktree: `D:\Wantok_E6G_Independent_QA_3958e10_20261011` at exactly `3958e10`.

## Verified local results

| Check | Evidence | Result |
| --- | --- | --- |
| Scoped Operations/marketplace PostgreSQL tests | Explicit selection of original, unmodified 001–056 SQL files via local Supabase CLI | **56 files / 1,139 assertions PASS** |
| Evidence scanner/quarantine/custody | `npm.cmd run test:evidence` | **101 / 101 PASS** |
| Actual loopback PostgREST signed-token negative requests | `npm.cmd run test:e6:auth-local`; ephemeral JWTs, no users/records written | **23 / 23 PASS** |
| Flutter static checks | Clean detached `scripts/flutter/check.ps1` | **7 / 7 targets PASS** |
| Client Flutter widgets | Same isolated checkout | **132 / 132 PASS** |
| Operations Flutter widgets | Same isolated checkout | **43 / 43 PASS** |
| Technical Control Flutter widgets | Same isolated checkout | **22 / 22 PASS** |
| Source whitespace/staging | `git diff --cached --check` before source commit | PASS |

## Integrated SQL runner limitation

Latest shared source contains migration `20261011240000_technical_scoped_health_log_adapter.sql` and test `090_technical_scoped_health_log_adapter.test.sql`, owned by the separate T2.4 stream. The local database has **not** been migrated to T2.4. As a result, the default full `npm.cmd run db:test` invoked 57 test files but failed the Technical Control test: `public.list_technical_module_log_events(text,integer)` does not exist. No T2.4 migration was applied by E6G. Do not claim that 57-file combined suite passes. Coordinate a separate approved additive T2.4 migration and rerun full suite.

## Scope and withheld acceptance

The read-only HTTP test uses short-lived HMAC-signed test JWTs validated by the local API on 127.0.0.1:54321. They do **not** represent real GoTrue human logins, independently witnessed browser sessions or positively granted roles. There was no account/profile/vendor insertion, KYC, document upload, status change or remote VM operation.

Formal E6 remains **OPEN**, and E7 is **not authorised** until the ten gate sign-offs in `docs/E6G_FORMAL_ACCEPTANCE_RUNBOOK_20261011.md` have independent evidence. Any release package is source-only with `productionApproved: false`. GitHub and package identifiers are confirmed separately at delivery.
