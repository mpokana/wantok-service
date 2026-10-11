# E6J — Trust Catalogue and Five-Migration Cross-Stream QA

**12 October 2026 | EAGLT02 only | E-series P0 source/test milestone**

## Result and non-authorised actions

1. `node scripts/qa/e6-trust-inventory.mjs --local`: **PASS as read-only catalog execution; REVIEW REQUIRED for policy/privilege findings.** It inspected **19 selected E6-relevant `public` functions** (all currently `SECURITY DEFINER`) and **20 selected operational tables**, without reading client/business rows or changing database content.
2. `npm.cmd run test:e6:crossstream-local`: **164/164 pgTAP assertions PASS across eight rollback-only suites** with all **five pending** migrations applied only in a disposable, network-disabled, no-port PostgreSQL database. Test container removed; shared local DB unchanged.
3. The ordinary **61-file** shared Supabase `npm run db:test` is **not green/has not been repeated as a full successful test** because all five pending migrations remain unapplied. No real GoTrue signed-in user acceptance or production-equivalent ACL/owner parity is claimed.

## Exact SQL integration

| Migration | Subject |
| --- | --- |
| `20261011233000` | E6H applicant case/self-review + clearance investigator separation |
| `20261011240000` | T2.4 restricted module health-transition logs |
| `20261011241000` | T2.4 Messaging queue aggregates |
| `20261011242000` | T2.4 privacy-minimised module action history |
| `20261011243000` | T2.4 metadata-only disconnected central source-contract readiness |

| Rollback-only pgTAP suite | Assertions |
| --- | ---: |
| 051 Operations case jurisdiction | 35 |
| 052 Scoped independent clearance | 34 |
| 056 Immutable conflict recusals | 18 |
| 057 Applicant/clearance reviewer independence | 19 |
| 090 Restricted health logs | 12 |
| 091 Messaging aggregate queues | 13 |
| 092 Scoped Technical Activity | 14 |
| 093 Central-log source contract | 19 |
| **Total PASS** | **164/164** |

The isolated stage uses the existing local **schema-only/no-owner/no-ACL** dump, seven non-personal reference tables and test-only grants/revocations, **not** real production PostgreSQL function ownership and privilege grants. It copies no customer, authentication, payment, evidence or queued-message data. Do **not** use its clean assertions to approve staging/production DB migrations without independent exact ACL parity and backups.

## Current real local catalogue snapshot

The `e6-trust-inventory.mjs` tool uses a **fixed local Docker Desktop Supabase container**, requires `--local`, forces read-only PostgreSQL transaction mode and queries `pg_catalog` metadata without function bodies or personal records.

- Selected **19 E6-relevant functions**, all 19 `SECURITY DEFINER`. All have an explicitly configured `search_path`. No selected sensitive trusted-only provisioning/emergency/recusal function had unexpected effective `anon` or `authenticated` EXECUTE rights under the script's narrow tested predicate.
- **20 selected Operations/applicant tables**, all have RLS enabled. The table-privilege catalogue reports `anon` SELECT privilege for `provider_profiles` and `provider_services`. **This alone is not a leak finding**, because public verified marketplace discovery may intentionally permit SELECT and RLS governs row access. Independently review policies, column exposure and service activation filters before signing off.
- All 19 selected SECURITY DEFINER configurations specify `search_path` without explicit `pg_temp` ordering. This is an **audit review item**, not automatic proof of an exploitable SQL-injection/search-path vulnerability. Review each function's qualification of relations/functions and the PostgreSQL temp-object resolution rules before deciding any additive hardening migration.
- **Five pending migration versions** absent from persistent local `supabase_migrations.schema_migrations` ledger; current local runtime therefore **does not yet carry E6H/T2.4 E features**. The overall database has other functions/tables outside the selected inventory; absence of findings here is *not* a whole-database security certificate.

## Next E-series steps

- Inventory the real effective policies, column grants, function owners and test-specific SECURITY DEFINER ownership in a dedicated planned stage; review the two public marketplace tables against intended public catalogue visibility without removing required discovery access.
- Write precise negative/positive GoTrue/PostgREST role matrix and approved reversible dedicated staging setup; no synthetic self-signed JWT is a witnessed staff login. Source audit is not permission parity.
- Obtain independent human records and authority for E6-G1–G10: staff delegation, dual approvals, maintained ISO jurisdiction and legal category mapping, related-party conflict review, real role/browser witnesses, security audit, DR/key custody and owner sign-off. These remain **ALL BLOCKED**.
- Keep actual identity upload, final verification/activation, payments, E7+, production deployment and **all persistent shared database migration** operations gated.
- Per owner sequencing, continue **E-series P0**; then CX1 direct signed-in Web/mobile acceptance; **T2.4 functionality remains PAUSED** even though its previous code was included here for E6 compatibility checks.

**Runbook:** `docs/PROGRAM_EXECUTION_PLAN_20261012.md`; formal acceptance `docs/E6G_FORMAL_ACCEPTANCE_RUNBOOK_20261011.md`; archive of earlier four-migration test `docs/E6I_ISOLATED_CROSSSTREAM_INTEGRATION_20261012.md`.
