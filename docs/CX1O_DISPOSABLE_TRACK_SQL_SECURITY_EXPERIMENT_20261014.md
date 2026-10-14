# CX1O — Disposable synthetic PostgreSQL Track actor-read test

**Date:** 14 October 2026 | **Host:** authorised EAGLT02 only | **Git baseline:** CX1N `d34a554` | **Status:** SYNTHETIC SQL QA PASS, **no authorised parity staging or private API release**.

## Scope and outcome

The owner said "Proceed" following CX1N preparation. CX1O exercises a *candidate* minimal, actor-scoped Track SQL function in an isolated, temporary PostgreSQL database using only fabricated data. It does **not** connect to or copy schemas, accounts, customer rows, Storage assets or credentials from the persistent Supabase instance.

The existing local `public.ecr.aws/supabase/postgres:17.11.0.002` Docker image was used. `scripts/qa/cx1o-disposable-track-stage.ps1` launches a random-name `--rm` container with **`--network none`**, **no published ports**, **no bind mounts**, **256 MB tmpfs database storage**, 1 GB memory limit and 1 CPU. A fresh `cx1o_stage` database is created from `template0`. It receives only the two source-owned SQL files below, runs tests and **destroys the container in `finally`**, including after errors. No shared database `pg_dump` or `docker exec` occurs.

## Included files and commands

- `scripts/qa/cx1o-disposable-track-fixture.sql` — fabricated two-customer/three-privileged-actor tables, deliberately wide legacy-style OR row policies, generated synthetic history, and an **illustrative** `SECURITY INVOKER` SQL function `list_my_track_bookings_candidate()`. It is **not** a `supabase/migrations` file and is **not installed** in local Supabase.
- `scripts/qa/cx1o-disposable-track-assertions.sql` — 21 positive/negative PostgreSQL assertions under simulated actor claim settings and actual `SET ROLE authenticated`, plus explicit `anon` execution-denial checks.
- `scripts/qa/cx1o-disposable-track-stage.ps1` — stage lifecycle, no-network/port/mount inspections, 108 synthetic rows verification, and teardown.
- `scripts/qa/cx1o-disposable-track-stage.test.mjs` — 14 offline guards, including tests that deliberately remove the actor predicate, switch to SECURITY DEFINER, widen the limit, inject a private column, enable Docker networking/mounts or remove teardown.

Run only on an authorised machine with the pinned image already available:

```powershell
./scripts/qa/cx1o-disposable-track-stage.ps1
node --test scripts/qa/cx1o-disposable-track-stage.test.mjs
```

## Synthetic assertion matrix

| Actor and condition | Result in disposable SQL stage |
| --- | --- |
| Anonymous | Cannot invoke proposed private function; raw table SELECT denied |
| Customer A | Receives only their own latest 100 of 106 synthetic bookings |
| Customer B | Receives only their two bookings; requested A booking ID never returned |
| Legacy provider | Can see another user's assigned booking under the **toy base-table policy**, but receives **zero** from the actor-only candidate |
| Qualified open-request provider | Toy base table permits an unassigned request; candidate still returns **zero** |
| Legacy administrator | Toy base table permits all records; candidate still returns **zero** if the admin has no bookings as a customer |
| Valid customer with no bookings | Receives zero records (distinct from unavailable server) |
| Missing simulated actor claim | Returns zero rows |
| Projection | Exactly four fields: `booking_id`, `booking_status`, `scheduled_start`, `created_at`; private notes/beneficiary emails/addresses omitted |
| SQL function privileges | Invoker semantics, zero caller ID parameters, authenticated-only execution under this simplified fixture, bounded 100-row result |
| Container lifecycle | Verified `--network none`, no ports/mounts; 108 synthetic rows inserted; temporary container deleted |

**Validated:** **21/21 SQL assertions PASS**; **14/14 source-drift guards PASS**. Combined unchanged CX1K/CX1N/CX1O source guards **54/54 PASS**. Full isolated `scripts/flutter/check.ps1` **7/7 analyses clean**, Client **135/135**, Operations **43/43**, Technical **38/38** widget tests PASS (**216/216**). `git diff --check` PASS, no CX1O container left running. The runner's initial attempt was aborted and its container removed after a PowerShell output-parsing error. The corrected rerun passed. Initial guard-test defects were corrected without touching any production or shared data. The full shared-database `npm run db:test` was **not** run because it targets the existing local Supabase/migration state and is not an isolated non-mutating CX1O test.

## Strong limitations: what this does NOT establish

1. **Not a real identity test.** The fixture deliberately defines `auth.uid()` using a locally set `request.jwt.claim.sub` parameter. This parameter can be forged by a direct SQL client. Only a separately secured PostgREST path receiving a *validated* GoTrue JWT can supply a trustworthy actor identity. **Do not expose this toy function or simulated identity path to users.**
2. **Not PostgreSQL privilege parity.** This is a *small synthetic reproduction* of the critical source-policy behaviours, not a restore of actual object owners, effective grants, default privileges, schema relationships, indexes, migrations or storage/transaction security. It does not certify active local RLS, definer helpers or protected joined relations.
3. **Not a complete Track data contract.** The four-field result is intentionally privacy-minimised and **cannot directly replace** the existing Flutter query (which renders category/provider/resource/quote/review details). No Flutter code, API routes, migrations, schemas or UI were changed.
4. **No authenticated HTTP / JWT validation.** No real GoTrue test users, refresh/expiry/revocation, cross-user REST GET, rate limits, CORS, permitted gateway handler, browser cookie or host firewall were exercised.
5. **No persistent stage approval.** CX1N's ten external authority/privacy/DBA/Security gates remain **NOT WITNESSED**; G7 31/31 pending; E6 G1–G10 0/10, E6O-01 untrusted writer issue open, D1–D5 unresolved, T2.4 paused, production approval false.

## Next action after this source-only synthetic stage

Request separate authority and independent staffing for a truly **role-equivalent isolated environment**. First approve secure handling of a schema/ACL-only snapshot and a backup/restore plan; then create separately authorised real GoTrue staging principals and test JWT verification, owner A/B cross-read denial, provider/admin/open-request negative cases, projection joins, revoked/expired sessions and direct Tailscale-IP port denial. An HTTP route may be proposed only after those witnesses and an approved rollback, and production remains a distinct final decision.

**Current HONOR outcome remains unchanged:** Home public categories pass; Track still reports backend unavailable because its private API has not been enabled.
