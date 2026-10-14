# CX1R — Disposable loopback HTTP Track contract witness

**Date:** 15 October 2026 | **Baseline:** CX1Q `c4d8b16` | **Host:** authorised EAGLT02 | **Disposition:** **36/36 temporary-loopback HTTP tests PASS**; real GoTrue and production **NOT** tested or approved.

## 1. Task scope

The owner requested continuation after CX1Q's signed-token *pure-function* test. CX1R tests how that existing **synthetic contract** behaves over **real loopback HTTP**, without exposing any endpoint to HONOR, Tailscale or a persistent process. This is a safe engineering precursor to — **not a replacement for** — the independently authorised role-equivalent real-GoTrue staging gate. The untouched Client still requests direct nested `service_bookings` records, not the illustrative four-field function.

Added **only** `scripts/qa/cx1r-loopback-http-fixture.mjs` and `scripts/qa/cx1r-loopback-http-fixture.test.mjs` under test tooling. The test creates a random ephemeral Ed25519 signing pair and 108 fully fictional booking rows. It starts a Node.js HTTP server on kernel-selected port **0** bound explicitly to `127.0.0.1`, checks the bound address and excludes `54321`, submits real loopback `fetch` plus raw Node HTTP requests, and shuts down the server in `after()`. No other app imports the temporary adapter; it does not persist signing keys, listen on an external interface, call live GoTrue/PostgREST or change any shared DB state.

## 2. Actual HTTP conformance

- Owner A receives at most their own latest 100 fictional rows. Owner B receives their own two rows in descending date order. Fictional provider and administrator users cannot obtain other people's customer-only Track results; an account with no records receives `200 []`, distinct from a backend outage.
- A successful mock payload has exactly `booking_id`, `booking_status`, `scheduled_start`, `created_at`; synthetic notes, beneficiary phone and metadata never leave the handler. Responses use `Cache-Control: no-store` and `X-Content-Type-Options: nosniff`.
- Rejects absent/tampered credentials, wrong issuer/audience/role, expired or premature claims, a deliberately revoked **mock** session, altered customer/filter/projection, direct private-table paths, foreign or missing Origin, unexpected client headers and non-GET write methods.
- Exercises actual HTTP `OPTIONS` CORS preflight: exact synthetic Origin, GET method and only `authorization,accept` pass; unexpected headers, POST and foreign Origin are rejected. Raw GETs with `Content-Length` or `Transfer-Encoding` are denied. These are **mock transport constraints**, not attestation of compatibility with actual Supabase browser request headers.
- Initial harness run **31/36** exposed a non-security test implementation discrepancy: undici automatically sends some zero-length request headers for POST/PATCH/PUT, and does not permit crafted GET transfer-encoding. The fixture now rejects all non-GET/non-OPTIONS methods **before** body inspection (HTTP 405); two malformed GET cases use raw Node HTTP. The corrected run was **36/36 PASS**.

## 3. Important design gaps identified

**Do not deploy the test adapter.** Its EdDSA test keys are ephemeral, its fabricated `cx1q-offline-only` key ID and `.invalid` issuer/audience are not installed GoTrue, and its session-revocation set is not GoTrue revocation. The strict test adapter rejects `apikey` and `x-client-info` headers. Actual `supabase_flutter` / PostgREST browser calls may include those headers and preflight declarations. A real allowlist must be drawn from captured, *sanitised* request shapes on an **approved isolated stage**, with correct signature/JWKS/expiry/session verification and no leakage of keys. CORS Origin is not user identity.

This transport does **not** prove current PostgreSQL `service_bookings` RLS, view/RPC definer semantics, direct `54321` host firewall, user-A-to-user-B account isolation or any embedded category/provider/resource/quote/review restrictions. The four-field mock is **not** an API-compatible replacement for the existing Flutter Track query. No test fixture or credentials were inserted into the installed database.

## 4. Exact runnable checks

```powershell
node --test scripts/qa/cx1r-loopback-http-fixture.test.mjs
node --test scripts/qa/cx1q-offline-track-jwt-contract.test.mjs
node --test scripts/qa/cx1k-tailnet-api-boundary.test.mjs scripts/qa/cx1n-track-stage-readiness.test.mjs scripts/qa/cx1o-disposable-track-stage.test.mjs scripts/qa/cx1p-track-local-privilege-audit.test.mjs
node scripts/qa/cx1k-tailnet-api-boundary.mjs --local
./scripts/flutter/check.ps1
git diff --check
```

**Verified QA at this source checkpoint:** CX1R loopback transport **36/36 PASS**; CX1K/CX1N/CX1O/CX1P/CX1Q unchanged source/JWT regressions **114/114 PASS** (**150/150 total**). Five-route Tailnet metadata guard `CX1K_SERVE_ROUTE_SCOPE_MATCH`, with private REST intentionally omitted. Flutter **7/7 analyses clean**, Client **135/135**, Operations **43/43** and Technical **38/38** tests PASS (**216/216**). The first complete-suite remote session ended after Client/Operations (evidenced by saved local test log); Technical was rerun **independently** and passed, exit 0. No Flutter application source was modified.

No `npm run db:test` was launched in this milestone because it targets shared local Supabase/migration state. Green source or ephemeral HTTP checks are **not** independently witnessed G7/G8, real user acceptance or permission to publish an endpoint. The CI/Flutter programme was verified as 7 analyses plus the three separately evidenced test suites, **not** asserted as a single successful overall shell exit.

## 5. Authorisation-required next stage

A real stage requires **named owner/Security/DBA/Privacy approval**, a database/schema/role/ACL parity and recovery plan, two separately authorised GoTrue staging accounts with synthetic booking ownership, verification of genuine GoTrue/JWT/PostgREST and RLS cross-user negatives, real browser CORS header reconciliation, privacy-minimised output and direct Tailnet-IP port isolation testing. No unreviewed `/rest/v1` route, service-role proxy, function grant, shared database write, account reset or production change is permitted.

**Programme status unchanged:** CX1N's 10 external stage gates **NOT WITNESSED**, G7 **31/31 unexecuted**, E6 G1–G10 **0/10**, E6O-01 and D1–D5 open, T2.4 paused, production false. The HONOR Track error remains because account-private REST access is intentionally not published.
