# T2.4 Messaging queue — E6G integration checkpoint

**Date:** 11 October 2026 (PNG), EAGLT02 only.
**Integrated source HEAD:** `30c03fb3c111807cceb6e3f375f551e8f0f28b4f` (E6G commit `3958e10` + T2.4 queue commit, cherry-picked from separately tested `58005e1`).
**Scope:** source QA/rollback, no deployed app, no retained database migration, no online VM.

## Results

- Clean detached integration tree `D:\Wantok_T24_Queue_E6G_Integrated_QA_20261011`, created from `30c03fb`.
- Complete `scripts/flutter/check.ps1`: **exit 0**, seven Flutter analyse targets PASS; **Client 132 / Operations 43 / Technical 28 widgets PASS**.
- Messaging queue focused Technical test suite **12 PASS**, covering 390px/1200px layouts, authenticated read-only Refresh, actual status totals, zero-vs-disconnected distinction, scope/permission rejection, model count consistency and error recovery.
- SQL new migration `20261011241000_technical_messaging_queue_snapshot.sql` + `supabase/tests/091_technical_messaging_queue_snapshot.test.sql`: **13/13 assertions PASS** in one local EAGLT02 PostgreSQL `BEGIN … ROLLBACK` with `ON_ERROR_STOP=1`. Following query confirmed the new function and synthetic test user were absent from the shared database.
- The baseline global pgTAP suite is **not** certified against a retained schema containing the new T2.4 migrations. The previous protected Log RPC and new Messaging RPC remain unapplied pending independent staging approval.

## Safety and precise limitations

- The new Messaging adapter is an aggregate of real `notification_outbox` DB statuses only. It returns **no recipient ID, content, idempotency key, last error or worker command**; requires `module.view` AND `module.jobs` for `core.messaging` at the PostgreSQL RPC boundary. Other module queues show *not connected*. No automatic polling.
- Neither `processing` nor `sent` proves that a background worker is live or that email/SMS was delivered. Counts cover the module's shared outbox and are not tenant-partitioned. Review large-table aggregation cost and privacy boundary before production.
- The earlier T2.4 log source remains **health transition history**, not centralised application logging, and its older view-authorised RPC is not retired.
- No job Run/Retry/Cancel, account login, external connection, identity evidence, payment, dispatch, role provisioning, on-VM deployment or real customer record changed.
- Concurrent E6G acceptance evidence and `supabase/snippets/` are preserved; manual E6/CX1 acceptance remains separate from this source milestone.

## Next release gates

1. Back up an independently isolated local/staging database and migrate both new T2.4 server RPCs in the documented order **before** deploying dependent UI; verify combined SQL suites after migration.
2. Demonstrate actual permitted/denied technical role access, tenant considerations, freshness and sanitisation using authorised staging accounts in browser.
3. Implement separately allowlisted central log sources, true worker/transport heartbeat and additional queue adapters. Review service-side read audit before any production exposure.
4. Require independent approval for executable job actions with concurrency locks, idempotency, impact preview, immutable audit and high-risk two-person control.

**T2.4 remains IN PROGRESS.**
