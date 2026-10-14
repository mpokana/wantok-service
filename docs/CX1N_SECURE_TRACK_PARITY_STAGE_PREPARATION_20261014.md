# CX1N — Secure Track API: source-only staging preparation and hard-stop runbook

**Date:** 14 October 2026 · **Baseline:** CX1M `e51fdb9` · **Host scope:** authorised EAGLT02 only · **Disposition:** PREPARATION READY, **STAGING NOT AUTHORISED**, no new private route or deployment.

## 1. Why Track fails, and what this checkpoint does

The owner tapped Refresh on HONOR at 14:37 PGT; Track still displays **“Could not load your activity”**. The same authenticated private Web preview can access public service categories (CX1L), but the existing HTTPS Serve allowlist covers **only** Web, GoTrue Auth, public branding, and exact active-only service categories. There is **no account-private `/rest/v1/service_bookings`** route. Keeping that request closed is intentional until security acceptance. This is an unavailable data source, not an empty bookings list or erased account.

This CX1N deliverable adds `scripts/qa/cx1n-track-stage-readiness.mjs`, a strict decision register and synthetic negative tests. They **only inspect checked-in source** and ensure every security gate is still unapproved; no HTTP traffic, GoTrue token, SQL connection, raw row read or network mutation is performed. Source contract PASS is **not** permission to deploy an endpoint.

## 2. Source-derived exposure and trust boundaries

- `ActivityPage._refresh()` invokes `ReservationRepository.loadMyReservations()` again and retains the failure state when it throws. Its injected Flutter retry tests historically pass, but a client retry cannot create a missing backend route.
- The current repository SELECTs up to **100** rows of `public.service_bookings`, ordered by `created_at DESC`, with `.eq('customer_id', _userId)` and embedded `service_categories`, `provider_profiles`, `provider_resources`, `service_quotes`, `service_reviews`. The selection includes **beneficiary phone/email, addresses, private notes, quote messages** and review fields, which require a documented privacy projection.
- The original migration `20261005002000_marketplace_core.sql` enables RLS and grants SELECT on `service_bookings` to `authenticated`. `service_bookings_read_participants` admits **customer, provider or administrator**. A second SELECT policy admits qualified providers for some **unassigned open requests**. `service_quotes` grants actor/provider/admin reads; CX1's `service_reviews_authenticated_read` permits reviewer, admin and visibility-based registered/public reads. PostgreSQL combines permissive RLS policies with **OR** semantics. A browser-supplied `customer_id` constraint alone is **not** an authorisation boundary.
- These statements come from **migration source**. Actual installed role ownership/grants, RLS policy definitions, `search_path`, JWT role and direct PostgREST access require an independently witnessed parity-stage audit; they are **NOT certified here**.
- The existing HTTP listener for developer Supabase at host port **54321** was previously reachable directly over the owner Tailscale network. A narrow Serve route is not an inbound host firewall, and any private-route release must account for this bypass. **Do not modify the tailnet-wide all-device grants.**

## 3. Proposed design (NOT implemented or approved)

Prefer a separately reviewed, **actor-derived, column-minimised, read-only** API contract over exposing `public.service_bookings` via generic REST. Consider a versioned PostgreSQL `STABLE SECURITY INVOKER` function with **no caller-provided `user_id`**: derive identity from PostgREST-validated `auth.uid()`, reject NULL, use a mandatory `b.customer_id = auth.uid()` predicate, explicit ordering and bounded pagination. The proposed function name `list_my_track_bookings_v1` is **illustrative and not deployed**. An invoker function must have independently reviewed table/column grants and RLS for **every** joined relation. Its API may use an exact allowlisted GET only if proven supported by the selected PostgREST version/function volatility; **do not publish POST merely because the SQL has no obvious writes**. Definer execution, generic service-role credentials, non-versioned `SELECT *`, user-id parameters and dynamic SQL should fail review by default.

Before design approval, map each exact client display field to a purpose and privacy decision. A **candidate** minimal display could be booking ID, status, scheduled time, created time, an approved category label and provider display label. Quotes, reviews, delegated beneficiary fields, addresses, notes and internal amounts remain **excluded by default** pending explicit necessity/consent review. Do not silently remove genuine booking data from the existing UX; preserve the current application and require an approved API/UI migration plan that accounts for the omitted fields. Keep Taxi, Commerce, Events, Water, Inbox, Saved and Wallet **separately gated** rather than expanding this Track milestone.

Avoid putting a service-role key in a Python proxy or Flutter bundle. Never trust a client-supplied JWT claim without server-side signature/expiry/audience verification; use GoTrue/PostgREST identity enforcement with reviewed RLS, not unsigned JWT decoding or Tailnet device presence as identity. HTTP adapter must reject all unapproved routes/methods/params, unknown JSON shapes, unauthenticated requests and requests outside bounded size/time. It must not log credentials, PII or raw row payloads.

## 4. Acceptance matrix for an independently approved *isolated* stage

| Gate | Minimum required witness / proof | Current |
| --- | --- | --- |
| G1 stage authority | Owner, Security, DBA and Privacy name purpose, stage, separate user roles, scope and permissible test data | NOT WITNESSED |
| G2 equivalent stage | Isolated host/container with same effective PostgreSQL object owners, schemas, versions and grants; no shared-db connection | NOT WITNESSED |
| G3 recoverability | Consistent PostgreSQL + Storage backup, verified archive/ACL, **restoration test**, documented abort/backout | NOT WITNESSED |
| G4 real GoTrue | Two or more individually authorised GoTrue principals with separate sessions; no role grants through frontend | NOT WITNESSED |
| G5 JWT lifecycle | Expired, revoked, malformed/wrong-audience JWT fail; session isolation and authorised logout | NOT WITNESSED |
| G6 privacy schema | Explicit allowlisted response fields, quote/review/delegate joins, legal basis, retention, log minimisation | NOT WITNESSED |
| G7 positive/negative reads | Owner A sees only permitted A records; B cannot see A even with crafted filters/IDs; anonymous denied | NOT WITNESSED |
| G8 embedded relation/privacy | Quote/review visibility, provider/admin eligibility, nested joins, missing records and malformed query denial | NOT WITNESSED |
| G9 host port isolation | Authenticated HTTPS path access as designed; direct Tailscale-IP TCP 54321 blocked to unauthorised peers while other device communication survives | NOT WITNESSED |
| G10 independent acceptance | Actual E6/G7/G8 security/DBA/privacy evidence signed; stage and production remain separate decisions | NOT WITNESSED |

All ten machine-readable gates are **false** in `docs/CX1N_TRACK_STAGE_DECISION_REGISTER_20261014.json`. Never mark them passed from source tests, historical pgTAP assertions, a successful login screenshot or this conversation. The preflight is designed to fail on fabricated sign-off.

### Stage execution sequence — hold until G1/G2/G3 authority

1. Approve scope separately; select an isolated parity target and verify restoration **without copying real personal records into an unapproved stage**. Confirm pinned Supabase/PostgREST versions, `anon`/`authenticated`/operator grants, function owners, service roles, schema exposure and active RLS policies.
2. Collect **sanitised, synthetic** actor fixtures in the isolated stage and create two separate real GoTrue test identities under the approved procedure. Never reuse the owner's account tokens or change the shared database to manufacture green tests.
3. Independently review the exact smallest read projection, server-derived actor predicate, join visibility, revocation and default-deny semantics. Prepare additive versioned SQL and rollback on a stage-only branch/migration; **no implementation is approved by this document**.
4. Run real network requests: zero records versus server unavailable, own records, other-user negative, forged customer filter, provider/admin open-requests, anonymous/malformed/expired/revoked JWT, unexpected columns, unbounded scans, SQL/RPC writes, CORS, device direct-port bypass, rate/time/size limits, error disclosure, audit privacy.
5. Only after independent gate sign-offs, propose a **single exact** tailnet-only route with owned rollback, then perform owner-observed HONOR and desktop read-only tests. Keep the current working Home/Services/branding route hashes intact.
6. Separately seek any production authorisation. **The absence of independent G7/G8 and E6 approvals means production remains sealed.**

## 5. Reproducible safe commands and result semantics

From this exact isolated CX1N worktree:

```powershell
node scripts/qa/cx1n-track-stage-readiness.mjs --source-only
node --test scripts/qa/cx1n-track-stage-readiness.test.mjs
node scripts/qa/cx1k-tailnet-api-boundary.mjs --local
git diff --check
```

Only the CX1N source preflight and tests need **no network or DB**. The CX1K `--local` variant inspects existing local Tailscale Serve metadata without changes. **Passing any of these is source/readiness evidence, not a Track API functionality or privacy pass.** Full Flutter/combined database regression status must be separately reported, including skipped suites caused by unapplied migrations.

## 6. Validation at this exact source checkpoint

- Source-only CX1N readiness preflight: **PASS**, explicitly reports `SOURCE_PREPARED_STAGE_BLOCKED`, **10** human gates still open, no private endpoint exposed or actor-HTTP test.
- Synthetic fail-closed tests: **CX1N 21/21** and existing CX1K **19/19** (**40/40 combined PASS**). Existing CX1K `--local` current Serve metadata also returned `CX1K_SERVE_ROUTE_SCOPE_MATCH` with **five** previously approved handlers only, no generic REST.
- Full isolated `scripts/flutter/check.ps1`: **7/7 analyses clean**, Wantok Client **135/135**, Operations **43/43**, Technical **38/38** widget tests PASS (**216/216**); no code changes to Flutter apps.
- `git diff --check`: PASS. The full `npm run db:test` suite was **not run** in this checkpoint because it depends on the shared local Supabase/migration state; no automated DB change is authorised in a source-only gate. Existing historic DB PASS figures are not a CX1N stage-witness substitute.
- The existing Tailnet preview, owner account, shared PostgreSQL volumes, served Web bundle and current private REST restrictions are unchanged. There are **no GoTrue, JWT, RLS, gateway handler or real user-row tests** in CX1N.

## 7. Project state

Existing E6O-01 untrusted audit writer privileges remain OPEN, E6-S D1–D5 remain unavailable, G7 **31/31 NOT EXECUTED**, G1–G10 **0/10 ACCEPTED**, T2.4 PAUSED. Host direct-port control and real GoTrue/private REST remain unresolved. All modifications for CX1N are in isolated source/docs only on EAGLT02; no SQL, accounts, Tailscale Serve, firewall, Docker volumes or production changes.
