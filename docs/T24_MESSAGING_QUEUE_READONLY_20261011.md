# T2.4 — Messaging notification queue read-only adapter

**Date:** 11 October 2026 (PNG)
**Scope:** New authenticated, read-only, aggregate-only Messaging queue monitor and Flutter presentation. Source/QA only; **not deployed**, no database migrations applied in the shared local or online database.
**Base commit:** a2a34a796a8c1e7ef6062df5672a84911284f983
**Test worktree:** D:\Wantok_T24_Messaging_Queue_QA_20261011

## Real source and interpretation

The existing `public.notification_outbox` table has real notification delivery records with `pending`, `processing`, `sent`, `failed`, and `cancelled` status values. It also stores private recipients, payloads and last_error values. T2.4 must **not** expose those records, identifiers, attempts, or internal payloads to ordinary technical module staff.

The new `public.get_technical_messaging_queue_snapshot(text)` security-definer RPC is restricted to the exact module key `core.messaging`, a current authenticated principal, and **both module.view and module.jobs** permissions verified by PostgreSQL. It reads only aggregate counts and max(updated_at), returning `module_key`, `adapter_key`, observation timestamp, last-outbox-update timestamp and status totals. It makes no data writes, checks no arbitrary queue name, and grants no table privilege. `PUBLIC` and `anon` cannot EXECUTE the function.

The Messaging Jobs screen now renders authentic aggregate status totals and UTC freshness timestamps only; every other module keeps its original **not connected** state. A genuine empty Messaging outbox shows **0**, while a disconnected module shows **unavailable**; these must not be confused. The UI refresh performs only the authorised read. No Run, Retry, Cancel, recipient drilldown, message preview, worker control or payment/dispatch mechanism was introduced.

**Limits:** a `processing` row is only a database state, not independently observed worker liveness; a `sent` row is not independent delivery proof. Queue counts may include all Messaging delivery recipients across the current deployment, and the technical permission model is global to the module (not additionally partitioned by region); do not reuse this adapter for cross-tenant or ordinary customer access. No actual queue consumer probe or guaranteed delivery SLA is claimed.

## Code and test coverage

- `supabase/migrations/20261011241000_technical_messaging_queue_snapshot.sql`: additive, read-only server RPC.
- `supabase/tests/091_technical_messaging_queue_snapshot.test.sql`: 13 negative/privacy/aggregation assertions.
- `packages/wantok_api/lib/src/technical_control_repository.dart`: strict typed queue aggregate model and RPC wrapper, rejecting inconsistent counts, unsupported module and invalid server values.
- `apps/wantok_tech/lib/src/dashboard/technical_observability_page.dart`: Messaging-only read path, real status card, UTC timestamps, authenticated read-only Refresh, and disconnected-module boundary.
- `apps/wantok_tech/lib/src/dashboard/technical_shell.dart`: navigation requires module.view AND module.jobs; capability description distinguishes connected Messaging and disconnected other modules.
- `apps/wantok_tech/test/technical_observability_page_test.dart`: responsive 390/1200px, refresh only, queue data/empty/disconnected distinctions, denied permission zero reads, invalid model handling.

The 13 pgTAP tests executed on the local PostgreSQL inside **BEGIN … ROLLBACK** with migration and synthetic rows together, under `ON_ERROR_STOP=1`. All 13 PASS; a subsequent read-only query confirmed the new function and fixture principal are absent. No schema/rows/grants were persisted. UI focused suite: **12 PASS**. Complete clean isolated `scripts/flutter/check.ps1`: **PASS (exit 0)**, seven analysis targets, **132 Client / 43 Operations / 28 Technical** widget tests. This full Flutter run does **not** install a database migration or replace authenticated staging/browser acceptance.

## Required gates before staging/production

1. **Order matters:** apply and verify prior T2.4 server log adapter migration `20261011240000` and this Messaging queue adapter `20261011241000` in a backed-up isolated staging database **before** releasing the Flutter build that calls them.
2. Validate real authorised and denied Technical roles via authenticated staging browsers, including module permission expiry and module key isolation. No credentials copied into code or messages.
3. Inspect actual notification-outbox volume and count-query cost on representative data. Counts scan the actual table and are manually refreshed, with no automatic polling; large-scale aggregation/index strategy may need review.
4. Confirm UTC time/freshness and external email/SMS worker transport separately. Do not label stored status as actual worker activity or delivery.
5. Separate signed, immutable technical audit, privacy retention rules, source allowlists, other queue adapters and approved idempotent/dual-controlled job actions. None is delivered here.
6. CX1 owner-reported acceptance is not independent release proof. No online VM, physical device, category records, payments or operational provider roles touched.

**T2.4 remains IN PROGRESS.** The independently existing local Technical preview on port 3600 is from an older commit; it is NOT evidence of the new adapter running against a migrated staging database.
