# E6K — Public Marketplace Row Security and Column Disclosure Review

**Date:** 12 October 2026, PNG. **Stream:** P0 E-series security. **Environment:** authorised EAGLT02 only. **Status:** read-only catalogue and isolated synthetic pgTAP **PASS**; public-field/privacy determination **NOT APPROVED**. No application UI changes, schema migrations or production work.

## Security question

Prior E6J found that anonymous PostgreSQL table-level SELECT privileges exist on both `public.provider_profiles` and `public.provider_services`. That is **not automatically a security bug**: provider discovery intentionally requires public visibility of verified and active listings. The critical separate questions are (a) which **rows** PostgreSQL RLS exposes, (b) which **columns** can be selected from those rows, and (c) which fields are independently approved for public use.

### Actual local `pg_catalog` evidence (zero real rows read)

Run `npm.cmd run test:e6:marketplace-local`. This script requires `--local`, connects to the fixed EAGLT02-only local Docker Supabase, starts a PostgreSQL `READ ONLY` transaction and reports **only** policy definitions, owner names, RLS flags and column names/counts.

| Observed local privilege | Profile table | Service table |
| --- | --- | --- |
| Owner | `postgres` | `postgres` |
| RLS enabled | YES | YES |
| RLS FORCE | NO | NO |
| Columns with anonymous SELECT | **18/18** | **23/23** |
| Anonymous INSERT/UPDATE/DELETE privileges | None | None |
| Relevant policy | `provider_profiles_public_read`: active **and** verified | `provider_services_public_read`: active service **and** matching active/verified profile |

The eight *candidate public-field privacy review points* are `provider_profiles.base_address`, `base_lat`, `base_lng`, `metadata`; `provider_services.service_address`, `lat`, `lng`, `metadata`. **Metadata is arbitrary JSON rather than an allowlisted public structure** in the existing table declarations. Presence of these SELECT privileges does not prove real secrets are stored or that publication is always inappropriate; it means eligible rows can be queried for those columns. Real provider field contents were **not** read or copied.

The public row policies are not equivalent to column projections. The shared `is_admin(auth.uid())` clause in authenticated table reads is a **legacy marketplace administration surface** and must not be treated as E6 independent country-duty case/evidence authorisation. No role or RLS changes were made.

## Isolated synthetic RLS regression

New `supabase/tests/058_public_marketplace_visibility_boundary.test.sql` inserts four synthetic auth identities, three synthetic profiles and three synthetic provider services in a PostgreSQL transaction that ends `ROLLBACK`. It tests anonymous versus signed-in role restrictions and deliberately probes synthetic `metadata` to **document** the present exposure; no private production rows, personal evidence or business identity data are queried.

- **17/17 pgTAP assertions PASS** for RLS configuration, no anonymous writes, anonymous-only active/verified profiles and active services, denied draft/unverified/inactive records, own unpublished provider visibility, and synthetic public metadata exposure.
- `npm.cmd run test:e6:crossstream-local` now applies exactly five pending source migrations inside **network-disabled, no-port disposable PostgreSQL**, executes 051/052/056/057/**058**/090/091/092/093 and expects **181/181 PASS**. It reproduces **test-only** anonymous schema/pgTAP/table grants omitted by `pg_restore --no-acl`. These are NOT proof of production-equivalent object owner/ACL. Synthetic fixtures all roll back; original local DB remains unchanged; disposable container removed.
- **Important assertion-maintenance warning:** The two synthetic `metadata` visibility assertions record the existing **unapproved baseline**, not a good security property. When an approved privacy-narrowing migration changes these grants, **replace** them with *negative* tests verifying forbidden columns fail closed; do not keep the baseline exposure as a permanent expected behaviour.
- **Independent Flutter regression:** exact E6K detached source worktree ran `scripts/flutter/check.ps1` with exit **0**: **7/7 Flutter analyses clean**, **Client 132/132**, **Operations 43/43**, **Technical 38/38** widget cases PASS. Current E6K changes are SQL tests, a catalogue script, and documents only; this validates that unchanged Flutter app code remains regression-green.
- **Other tests from unchanged main repository CLI:** local synthetic-JWT HTTP auth **23/23 PASS**, E6 independence **106/106 PASS**, evidence scanner **101/101 PASS**. The detached E6K worktree did not have the npm Supabase CLI; an attempted auth run there was NOT executed; the main repository rerun had the correct CLI and succeeded.
- The earlier E6J **164/164** stage remains historical evidence (before suite 058). The persistent shared full **62-file** database suite is not green until five pending migrations are applied in separate, approved and backed-up staging. No real GoTrue account, browser login, production object-owner privileges or human policy approval is established.

## Proposed safe remediation sequence — not executed

1. **Record the authorised public field contract** for individual, business and organisation provider cards and active service pages. Obtain a privacy/compliance decision specifically addressing home/business address precision, coordinates and each `metadata` key (including indirect nested embeds). Do not store sensitive identity/evidence in public marketplace metadata.
2. Inventory *all* Client and public API query shapes: `provider_discovery_repository`, Client and shared service/event/commerce/water-transport repositories, PostgREST embedded relations, `select(*)`, and Auth vs anonymous paths. Maintain public search/rating functionality and distinguish data needed only by vendor/Operations from public data. SQL policy checks do not replace Web/mobile regression.
3. Introduce a **public-safe, explicitly typed and allowlisted read projection** (view/RPC with underlying RLS and carefully reviewed security-invoker/definer semantics). Test direct REST/table bypass and all computed/embedded relationships; avoid assuming a view automatically inherits secure RLS.
4. On a dedicated backed-up, role-equivalent stage only, migrate Client reads to the approved contract, then narrow `anon` direct table/column SELECT **without** accidentally denying required RLS policy subqueries or authenticated own/vendor reads. Fail closed on metadata and address fields not authorised for public access. Validate proxy, browser, Android, rating/filter/Saved and legacy API behaviour against positive + negative role fixtures.
5. Obtain independent security/privacy sign-off and deployment/rollback approval before persistent staging or production changes. No high-risk provider activation, KYC document ingestion, job execution, payments or online VM modifications are authorised.

## Next E-series gate

Complete E6-G8 independent direct REST/RLS/column-grant review, **with actual GoTrue/PostgREST role sessions** after separate human-approved test identities and staging exist. The pending `E6-G1` through `E6-G10` acceptance gates remain **BLOCKED**. This E6K stage is an executable **baseline and regression**, not evidence of public-data privacy approval. Continue E-series/Operations before CX1; T2.4 remains paused under `docs/PROGRAM_EXECUTION_PLAN_20261012.md`.
