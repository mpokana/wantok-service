# CX1Q — Offline Signed-JWT Track Contract and Real GoTrue Staging Test Matrix

**Date:** 15 October 2026 | **Baseline:** CX1P `77738cd` | **Host:** EAGLT02 | **Status:** OFFLINE CONTRACT TESTED; REAL G7/G8 JWT/REST NOT TESTED; PRIVATE API UNPUBLISHED.

## 1. Scope and results

The owner directed continuation after the successfully resumed CX1P audit. This milestone adds `scripts/qa/cx1q-offline-track-jwt-contract.mjs` and a `node:test` suite. Both files live only under `scripts/qa`, outside deployed apps, migrations, gateways, `.wantok` runtime and any Supabase volume. All identities and records are fabricated, and a fresh **Ed25519 keypair is created in test memory**, never persisted or used by real GoTrue. The pure `simulateTrackRead` function **does not start an HTTP listener**, connect to PostgREST, read an application row or deploy anything. It examines an in-memory request shape and returns only synthetic data.

**Focused suite: 44/44 PASS.** This is **cryptographic signature/claim behaviour in an isolated mock**, **not real GoTrue/JWKS/session validation**, database RLS, a deployed private API, or any acceptance/production grant.

## 2. Candidate simulated private Track contract

- **Illustrative route only, NOT published:** exact `GET /rest/v1/rpc/list_my_track_bookings_v1` with no query parameters. This is a contract target, not confirmation that the installed PostgREST accepts this SQL function as GET. The CX1O toy function remains uninstalled.
- A Bearer credential must validate against the **ephemeral offline testing key** and the **fabricated test issuer/audience**, supported algorithm and exact key ID. The test harness refuses missing/malformed signatures, unrecognised header fields, wrong issuer/audience, non-authenticated role, absent/invalid subject, expiry/not-before/time anomalies, unsupported claims, missing session and a **simulated in-memory revocation set**.
- The in-memory actor is taken exclusively from the verified **test JWT subject**, not from a requested customer ID, account filter or user-supplied row relationship. A and B see only their own synthetic bookings; provider, qualified-provider and administrator subjects see no other customers' rows through the mock candidate, despite wider source table policies.
- Response projection: `booking_id`, `booking_status`, `scheduled_start`, `created_at`, limited to newest **100**, with `Cache-Control: no-store` and one explicitly allowed mock Origin. No `notes`, `beneficiary_email`, address, metadata, provider details, quotes, reviews or unrestricted join output.
- Reject unknown query filters, wildcard projection, unrelated private-table routes, modification methods, unapproved/missing Origin, extra headers, malformed bearer and missing session. Errors are generic and omit sensitive fixture values.

**Mock limitations:** the URI, claims profile, strict `Origin` rule and four-column projection are **illustrative controls**. They may require alteration after independently reviewing actual browser preflights, GoTrue v2 JWT format (symmetric vs asymmetric keys, JWKS rotation, real audiences, session revocation), PostgREST function volatility/HTTP verb behaviour, and the existing Flutter data model. A browser Origin is **not** an authentication mechanism, and a mock revocation set is **not** GoTrue sign-out or refresh-token revocation.

## 3. Real GoTrue and actor-privacy witness plan — NOT EXECUTED

| Case family | Minimum approved real-stage witness | Status |
| --- | --- | --- |
| User A | Real GoTrue account A, signed JWT, A-only bookings via independently reviewed actor-derived SQL/RLS | NOT WITNESSED |
| User B | Real separately administered B session, B-only bookings, cannot retrieve A by crafted actor/booking filters | NOT WITNESSED |
| Missing/invalid identity | Anonymous, malformed, expired, not-yet-valid, wrong-audience/issuer, unexpected role/header | NOT WITNESSED |
| Signature/key lifetime | Real deployed GoTrue algorithm/issuer/JWKS, rotation, clock skew and expiry verified independently | NOT WITNESSED |
| Session lifecycle | Actual logout, refresh, revoked/disabled user and token/session validity according to GoTrue server semantics | NOT WITNESSED |
| Provider / administrator | Verify broad source table policies never permit foreign Track customer history, even on direct REST path | NOT WITNESSED |
| Qualified open-request provider | Unassigned request cannot appear in a customer-only Track API without that same actor owning it | NOT WITNESSED |
| Related records | Every embedded quote, review, provider and resource field approved and separately protected by RLS/column grants | NOT WITNESSED |
| Method/projection | Exact route only, read-only handling, bounded page, unexpected methods/columns/query params denied | NOT WITNESSED |
| Direct host port | Unauthorised Tailnet peer fails to reach `EAGLT02:54321` directly while required other Tailnet traffic still works | NOT WITNESSED |
| Recovery and custody | Independently approved isolated equivalent database/user state, backups and successful rollback/restore | NOT WITNESSED |
| Human witness | Owner, Security, DBA, Privacy and E6/G7/G8 delegates sign real-stage evidence | NOT WITNESSED |

The source-only matrix makes **no claim that the above behaviour is secure in actual Supabase**. No real test users, session tokens, evidence rows or permissions have been created or changed.

## 4. Safety and boundaries

The current deployed HONOR `:8443` and desktop Client remains unchanged. It uses `ReservationRepository.loadMyReservations()`, a full nested `service_bookings` query. It **cannot consume the four-column mock contract without a separate, approved backend and Flutter client migration**. This milestone does not implement that migration.

The earlier CX1P installed catalogue check confirmed both broad booking read policies, a `SECURITY DEFINER` `is_admin` helper owned by an RLS-bypass role, and seven sensitive authenticated-selectable columns. Those issues require independent review. Existing public category routes remain exact and private Track reads remain blocked, so the HONOR message `Could not load your activity` is still expected and is **not** proof of an empty account.

CX1N's **10/10 human staging gates remain NOT WITNESSED**. E6 G1–G10 **0/10 approved**, G7 **31/31 unexecuted**, E6O-01 audit/notification writer concern unresolved, D1–D5 unprovided, T2.4 paused, production **not approved**. No live SQL, DB grants, GoTrue account, key, Tailscale route/firewall, checkout reset or deployment change is authorised by this checkpoint.

## 5. Reproducible tests

Run from the isolated CX1Q worktree:

```powershell
node --test scripts/qa/cx1q-offline-track-jwt-contract.test.mjs
node --test scripts/qa/cx1k-tailnet-api-boundary.test.mjs scripts/qa/cx1n-track-stage-readiness.test.mjs scripts/qa/cx1o-disposable-track-stage.test.mjs scripts/qa/cx1p-track-local-privilege-audit.test.mjs
node scripts/qa/cx1k-tailnet-api-boundary.mjs --local
./scripts/flutter/check.ps1
git diff --check
```

**Actual CX1Q verification (15 October):** New offline signed-token contract **44/44 PASS**. Prior CX1K/CX1N/CX1O/CX1P fail-closed source tests rerun **70/70 PASS**, giving **114/114** tests across the two separate suites. Full isolated Flutter check completed successfully with exit code 0: **7/7 analyses clean**, Client **135/135**, Operations **43/43**, Technical **38/38** (**216/216** widget tests). No frontend/backend app code changed. `git diff --check` must pass before checkpoint.

No `npm run db:test` is run in this source-only milestone: it depends on local shared Supabase/migration state, which is not an approved disposable stage. These checks demonstrate offline source regression only, not real GoTrue, PostgREST or database actor isolation.

## 6. Next action

Obtain **explicit, separately documented** owner/Security/DBA/Privacy approval for an independent role/ACL-equivalent isolated stage, synthetic real GoTrue accounts, backup/restore validation, privacy-minimised fields, and JWT/cross-user/http/direct-port witnesses. Only after independent G7/G8 acceptance should any private API be proposed for the HONOR preview. Production release still requires a separate decision.
