# E6I — Disposable Cross-Stream Security Integration

**12 October 2026, Papua New Guinea | EAGLT02 only | development QA**

## Outcome and scope

A repeatable disposable, network-disabled, no-exposed-port PostgreSQL stage successfully installs the four pending additive security/observability migrations in their real version sequence, then executes seven existing transactional pgTAP suites. **145/145 assertions PASS.** This is E6+T2.4 migration compatibility evidence only, **not** the full source database's 60-file suite, production permission equivalence, signed-in API/browser acceptance or human E6 approval.

### Source-only migrations tested in a separate PostgreSQL container

1. `20261011233000_operations_independent_case_review.sql` — E6H prevents enterprise applicant self-review and prior identity/approving officers reading their own clearance as investigators.
2. `20261011240000_technical_scoped_health_log_adapter.sql` — T2.4 module-scoped health logs.
3. `20261011241000_technical_messaging_queue_snapshot.sql` — T2.4 scoped Messaging queue counts.
4. `20261011242000_technical_scoped_activity_audit.sql` — T2.4 redacted module activity.

### Reproducible command

From `D:\Project-M.2\wantok-service-recovery` on authorised **EAGLT02**:

```powershell
npm.cmd run test:e6:crossstream-local
```

Equivalent direct command: `powershell.exe -NoProfile -ExecutionPolicy Bypass -File scripts/qa/e6-crossstream-isolated-staging.ps1`.

The test runner adapts the proven T2.4 isolated staging script, using:
- disposable container `wantok-e6i-qa-<random>` on Docker `--network none`, no published ports, 1024 MiB cap and PostgreSQL temp filesystem; container automatically removed, even on failed SQL testing;
- `pg_dump --schema-only --no-owner --no-acl` on **local** Supabase, then restores to disposable `e6i_stage` (no real auth/users/applications/financial/notification data);
- reference-only dump of seven finite non-personal tables: `app_roles`, `technical_modules`, `technical_access_levels`, `technical_permissions`, `technical_access_level_permissions`, `service_categories` and `provider_onboarding_policies`; current source has 29 category rows and seven generic onboarding policies;
- explicit **test-harness-only** role grants for pgtap and applicable E6 RLS read tests, plus explicit trusted-only function ACLs from the source definitions. Since original ACLs and ownership are intentionally omitted, **this is not an exact production grants/SECURITY DEFINER ownership reproduction**;
- pgTAP files that each begin a transaction, generate synthetic auth/users/cases and end with `ROLLBACK`; assert exact `ok` counts and zero `not ok` results;
- post-test checks that E6H and T2.4 procedures exist inside the disposable container and all created auth users/intake cases/outbox rows are absent; confirm the four migrations are **not** in the shared local `supabase_migrations.schema_migrations` ledger and all three T2.4 procedures remain absent from that local DB;
- delete transient Docker-local dump files and stop the disposable DB. Nothing is pushed or deployed to an online VM.

### Exact cross-stream assertions

| Existing pgTAP suite | Assertions |
| --- | ---: |
| 051 — Operations case jurisdiction | 35/35 |
| 052 — Independent safety clearance | 34/34 |
| 056 — Immutable case recusal | 18/18 |
| 057 — E6H independent enterprise case review | 19/19 |
| 090 — T2.4 scoped technical log events | 12/12 |
| 091 — T2.4 scoped Messaging queue | 13/13 |
| 092 — T2.4 scoped activity audit | 14/14 |
| **Total** | **145/145 PASS** |

Successful runner prints `E6I_STAGING_PASS=4 migrations,145 assertions,fixtures rolled back`, `E6I_SHARED_DB_UNCHANGED=true` and `E6I_ISOLATED_CONTAINER_REMOVED=true`.

An initial expanded run exposed a **schema-only restore test ACL mismatch** (unlike the actual local DB, restored functions defaulted to PUBLIC EXECUTE and `service_role` could not execute pgtap). Explicitly applying synthetic staging grants/revocations reproduced *only the specific tested ACL properties*, after which all 145 assertions passed. This does **not** demonstrate complete production-grant parity, and those grants never touched shared Supabase.

`pg_dump` prints a warning about self-referencing `service_categories`, but the exact snapshot restored and all seven suites passed with the current non-personal reference data. Treat future restore warnings or missing baseline reference categories as reasons to revalidate.

## Remaining blocks — no premature E6/E7 completion

- Full `npm run db:test` on the persistent shared local DB remains blocked by intentionally unapplied E6H/T2.4 migrations; do **not** apply another stream's migrations just to make that command green.
- Positive independently witnessed GoTrue sign-ins, real users and credentials, PostgREST access enforcement for properly provisioned role holders, official ISO subdivisions/category regulation, HR delegation, business relationship/conflict screening, operational key custody, recovery/restore, formal security and product-owner approval remain **NOT DONE**.
- No local Supabase schema was permanently migrated by this E6I test; it is not a deploy/activation test. Production release stays `productionApproved:false`. No KYC upload, provider activation, payment, online VM or other machine touched.
- Source files remain on `feature/flutter-platform-v1`; preserve unrelated T2.4 commits and preexisting untracked `supabase/snippets/`. The next candidate task is a dedicated approved staging backup and precise ACL/owner equivalence plus signed-in QA after explicit human assignments; **E6 gates G1–G10 remain OPEN**.

See `docs/E6G_FORMAL_ACCEPTANCE_RUNBOOK_20261011.md`, `docs/E6H_ENTERPRISE_CASE_INDEPENDENCE_20261011.md`, and `docs/T24_ISOLATED_STAGING_INTEGRATION_20261011.md`.
