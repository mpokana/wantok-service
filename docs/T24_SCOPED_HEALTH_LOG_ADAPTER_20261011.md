# T2.4 â€” Server-guarded module health-transition log adapter

**Date:** 11 October 2026, PNG (EAGLT02 local)
**Scope:** Additive module-log read API and Technical Control wiring, source-only until separately authorised database migration and staging deploy.
**Prior T2.4 commit:** `cbad6d2`
**T2.4 status:** IN PROGRESS. Centralised application logs, real queue providers, job actions and privileged audit views are NOT ready.

## Problem

The original `list_technical_module_health_history(text, integer)` RPC checks `module.view` but not `module.logs`. The new read-only T2.4 Logs panel was initially using this broader health-history RPC. Client-side card visibility is not adequate backend authorisation.

## Increment

- Add a **distinct** `public.list_technical_module_log_events(text, integer)` SECURITY DEFINER function, checking both effective `module.view` and `module.logs` for the **requested module** and authenticated caller.
- Bound limit on the **server** to 1â€“30 and sort by timestamp plus monotonically increasing history ID.
- Return only module health status transitions with a restricted-format transition reason. Suppress free-text summary and probe identifier on this new adapter, including if a registered probe embeds sensitive details. Do not return raw log text or actor-identifying metadata.
- Revoke generic/anonymous function EXECUTE and grant only to authenticated role; existing health-history backing table remains locked down under RLS/table GRANTs.
- Wire new `TechnicalControlRepository.loadModuleLogEvents` into the module Logs page without enabling any write, job execution or arbitrary event-source access.
- **Important residual risk:** the older `list_technical_module_health_history` RPC still has the original `module.view` authorisation because the separate Health & dependencies page depends on it. This increment does **not** revoke that legacy capability or claim global health-history log confidentiality. A later contract audit should move existing Health history to a scoped/redacted API without breaking consumers.

## Tests and deployment separation

`supabase/tests/090_technical_scoped_health_log_adapter.test.sql` contains **12 pgTAP checks**:
- function present, unauthenticated refusal, anon denial
- allowed module view + logs
- backend cap of 30 (requesting 200)
- blank summary/probe ID and safe transition reason shape
- cross-module refusal
- view-only denial (without logs)
- authenticated EXECUTE grant

These were run on the existing EAGLT02 local PostgreSQL **only inside one explicit BEGIN ... ROLLBACK transaction** which temporarily included the new migration and test. All 12 checks PASS with `ON_ERROR_STOP=1` and returned exit 0. The migration **was not retained** in the shared database; no existing user records, grants, or category paths persistently changed. The synthetic `auth.users` and history rows rolled back.

Flutter analysis and widget suite results to be recorded at end of checkpoint. No online VM, external account, user session, Chrome click, job command, service restart, route activation, payment, provider approval or real customer evidence access.

## Next

- Deploy this new additive migration only in a separately authorised, backed-up **staging** database, then run the full 56-test SQL suite in a deterministic migrated environment and verify two separately authenticated role accounts through real Technical Control UI/API.
- Do not ship this new UI to an environment before the server has this RPC; its Logs page would correctly show an unavailable/error state.
- Introduce real allowlisted central/module log sources with independent server enforcement, source provenance, UTC timestamp, redaction, bounded pagination and retention/immutable audit.
- Read-only queue adapter and job definition registry next; do not add Run/Retry/Cancel until explicit approval with idempotency/concurrency, actor audit and high-risk dual-control protections.
