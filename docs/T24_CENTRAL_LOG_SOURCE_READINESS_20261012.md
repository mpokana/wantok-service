# T2.4E — Secure Central Log Source Readiness Contract

**Date:** 12 October 2026, PNG. **Environment:** EAGLT02 isolated development worktree. **Status:** Source + isolated SQL verification; no real collector, log stream, worker heartbeat, local shared database migration, or production release.

## Handover and concurrency

Owner provided the T2.4 handover after latest E6I work. Latest source baseline is `b5b060c` (later than T2.4's previous `da2e42d` handover) and includes E6H/E6I. This milestone is developed in a separate detached worktree `D:\Wantok_T24_Log_Source_20261012` without writing the main branch or changing its pre-existing `AGENTS.md`, `docs/E6_T24_PARALLEL_HANDOFF_20261012.md`, or `supabase/snippets/`. Other chat sessions cannot be forcibly stopped by Git; prior owner handover is based on the user's instruction, not a verified exclusive lock. Commit/push only after remote HEAD and shared worktree checks.

## Actual new capability — contract readiness, not central logging

New migration `20261011243000_technical_central_log_source_contract.sql`:

- `technical_log_source_contracts`: trusted-only metadata registry to plan future per-module application/container/worker/gateway log sources. Accepts only a restricted `SEC-...` provenance ticket, 1–90-day retention policy and fixed `strict_metadata_only` redaction policy. No raw event, endpoint URL, customer data, API key, private notes or credential fields.
- `connection_state` is constrained by PostgreSQL to **`not_connected`**. Even the trusted role cannot claim a live central collector merely by inserting or updating a contract.
- Registry is RLS-enabled; anonymous and authenticated browser users have no direct table privileges. Only `service_role` receives registry CRUD. No source records seeded or approved here. Registering real sources still requires separate authorised security/provenance review.
- `get_technical_central_log_readiness(p_module_key)` requires signed-in **`module.view` AND `module.logs`** scoped to the requested module; returns only observed timestamp, module key, registered-contract count, hard-false collector/central-events status, `not_connected` and `unknown` source health. It never returns source keys, ticket references, collector credentials, full logs or other modules' counts.
- Typed `TechnicalCentralLogReadiness` rejects claims of connected status, true collector/event availability, invalid timestamps, negative counts and unexpected output fields. `TechnicalControlRepository.loadCentralLogReadiness` calls the server RPC.
- The existing protected Logs page now shows a separate **Central log source readiness** panel using real readiness RPC data, alongside the already-existing health-transition log view. No claim that health history or Technical Activity is a central application/container log. Refresh remains read-only. Test-injected historic transition mocks are not coupled to the live backend.

### Exact tests and limits

`093_technical_central_log_source_contract.test.sql` contains **19** synthetic rollback-only assertions: authentication, scoped duties, cross-module isolation, trusted-only source metadata grants, rejecting non-ticket provenance and false connected state, reduced response fields, no secret output, fail-closed capability revocation. The T2.4 disposable PostgreSQL staging script now applies **four** T2.4 migrations in order (240000, 241000, 242000, 243000), runs 090–093, verifies fixture rollback and absence of the new RPC in the shared DB, and removes the network-disabled/no-port container. Total staged T2.4 SQL assertions: **58/58 PASS**.

The E6I prior integrated stage (E6H + earlier three T2.4 migrations) passed **145/145** at `b5b060c`. This T2.4E runner is separate; **full 61-file shared SQL suite is not green** until the four T2.4 and E6H pending migrations are applied in a properly backed-up, separately authorised staging DB. The isolated source clone uses test-specific `supabase_admin` ownership and grants, not production ACL/SECURITY DEFINER parity. No GoTrue multi-user witnessed staging, live central log ingestion, collector timestamp, worker liveness, or job execution has been tested.

## Next T2.4 priorities

1. Independently identify/verify real source processes and collectors, sign off provenance, secure retention/erasure/redaction and inventory indexing before enabling any ingestion. Do not insert real source contracts without human-reviewed ticket/custody evidence.
2. Verify Messaging worker identity and heartbeat process; distinguish real worker liveness, outbox state and delivery acknowledgement. No inferred status.
3. In dedicated backed-up staging, verify exact role/ACL/owner fidelity; reconcile E6H + four T2.4 migrations and execute full 61-file SQL suite with actual GoTrue/PostgREST/browser role boundaries.
4. Only after independent security and operational approvals, design idempotent/audited/dual-controlled job actions. No Run/Retry/Cancel now.

**Release boundary:** No shared/local Supabase mutation, actual source activation, online VM deployment, production status change, provider/KYC flow, payment or background job execution.
