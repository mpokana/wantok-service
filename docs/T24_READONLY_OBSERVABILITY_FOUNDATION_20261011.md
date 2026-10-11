# T2.4 — Read-only Technical Observability Foundation

**Date:** 11 October 2026 (PNG)
**Authority:** owner explicitly instructed "Continue T2.4" after declaring eight CX1 manual checklist items complete. The previously saved owner attestation remains distinct from independently observed signed-in browser/device evidence; a new phase can begin locally without silently certifying the entire CX1 release.
**Machine:** EAGLT02. No Linux VM changes permitted.
**Phase:** T2.4 **IN PROGRESS** (first code increment only); not T2.4-complete or production approved.

## T2.4 scope from the authoritative roadmap

1. Diagnostic adapters
2. Central/module log adapters
3. Background job and queue visibility
4. Approved job actions
5. Richer technical audit views

## Implemented in first read-only increment

- New `TechnicalObservabilityPage` in the existing authenticated Technical Control module workspace. Capability cards open per-module pages. No global Overview-wide data aggregation.
- **Diagnostics:** read-only adapter to existing `get_technical_module_health`, `list_technical_module_health_probes` and `list_technical_module_dependencies` via `TechnicalControlRepository`. Shows reported/effective state, report timestamp, probe status/staleness and dependency visibility. Hidden dependencies remain generically labelled.
- **Logs:** explicitly **health-transition history only**, not raw application/audit/container/security logs. The existing `list_technical_module_health_history` RPC is requested with `p_limit:30`; UI also caps 30. No log body, actor email, summary or exception detail is shown. A missing transition never implies all services healthy.
- **Background jobs:** honest `No background queue adapter is connected` state. Does not display a misleading zero-job count, schedule, job IDs, payloads or retry/execute/cancel controls.
- **Access:** navigation tiles appear only with the corresponding technical module capability (diagnostics + view, logs + view, or jobs). Direct page construction also fails closed before loaders for missing capability. Existing backend RPCs additionally apply their existing module-health read scope; **no new server-side `module.logs` SQL check has been added to the pre-existing health history RPC**, and health history is not relabelled as privileged raw logs.
- **Safety:** read-only refresh and generic recoverable errors; no invocation of the existing writable `run_technical_module_health_probe` RPC. No arbitrary HTTP endpoint probing, token exposure, VM access, data changes, account editing or background execution.

## QA coverage

`apps/wantok_tech/test/technical_observability_page_test.dart` verifies:
- 390px and 1200px diagnostic data display and two read-only refreshes
- restricted dependency detail is not shown
- ungranted permissions cause zero data-loader calls
- 30-item log cap, truth-in-labelling and no sensitive summaries
- missing queue adapter never implies zero jobs or allows job execution
- backend read failure keeps errors generic and recovers on Retry

Focused widget tests **six PASS** after finding and correcting a Flutter `setState` callback returning a Future.
**Full validation PASS:** `scripts/flutter/check.ps1` exit 0: all seven Flutter analyses, **132 Client / 38 Operations / 22 Technical** widget tests. Local `npm.cmd run db:test` PASS **52 files / 1,043 assertions**. No SQL migration was introduced by this T2.4 milestone. Source changes are isolated in detached `D:\Wantok_T24_Readonly_Observability_QA_20261011` at Git revision `155dd47`, with no production/Web deployment and no schema migration.

## Remaining T2.4 work / acceptance

- Define safe, canonical per-module diagnostic adapters beyond current health/probe state, with **server-side** scope, timeouts, freshness and data minimisation.
- Central/module log adapter contracts, allowlist/redaction, retention, pagination, true log-source provenance, RPC permissions and audit. Current health history **is not central logging or technical action audit**.
- Queue registry/provider integrations and truthful queued/running/failed counts with freshness and tenant/module permissions; no worker/control-plane writes until independently reviewed.
- Approved job actions (run/retry/cancel) must require scoped server permissions, preflight idempotency/concurrency, impact preview, explicit confirmation, signed immutable audit and dual control where necessary. No actions in this milestone.
- Dedicated richer technical audit query models; do not reuse the broad Operations evidence or private applicant event content.
- Independently authenticated browser acceptance in Technical Control and staging/physical client gates remain separate; no deployment without backed-up staging and owner authority. E6 hardening and CX1 evidence reconciliation remain open.

**Rollback:** revert only the isolated T2.4 commit (once created); all existing core applications, database schema, categories, images, payment and provider flows remain unchanged.
