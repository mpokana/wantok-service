# CX1M — HONOR Track retry diagnosis and private API gate

**Date:** 14 October 2026 | **Platform:** Wantok Services Client mobile Web private Tailnet preview | **Status:** Visual presentation passes; live activity retrieval BLOCKED. **Not production acceptance.**

## Owner evidence and interpretation

Owner retried the green **Refresh** control on HONOR and supplied a 14:37 PGT screenshot from private HTTPS :8443, still showing **"Could not load your activity — Check your connection and try again"**. The green Refresh control sits beneath the Track hero without overlap. The screenshot and report show no successful activity retrieval and do **not** establish that the user's account contains zero bookings.

The same owner has already visually confirmed CX1L Home public category cards and removal of the green diagnostic banner. Public category access is a separate, narrower contract than account-private activity access.

## Source and deployment diagnosis (read-only)

- `apps/wantok_app/lib/src/home/activity_page.dart` uses `ReservationRepository.loadMyReservations` in initial load and the `_refresh` callback. The latter requests the same data again and retains a retryable error UI on failure.
- `packages/wantok_api/lib/src/reservation_repository.dart` uses an authenticated `service_bookings` SELECT of account activity and nested category/provider/resource/quote/review relations, filtered on `customer_id`, ordered newest first, maximum 100.
- EAGLT02 `tailscale serve status` exposes only the Web roots, `/auth/v1`, exact public `service_categories`, and exact published-branding RPC. It does **not** expose `/rest/v1/service_bookings`. Existing owner-tailnet direct host port 54321 bypass is **not** a permitted substitute.
- Supabase Auth loopback health returned HTTP **200**. This is service health, **not** private-row entitlement or a witnessed user JWT test.
- Unchanged client-source regression: `flutter test --no-pub test/cx1_inbox_track_refresh_test.dart` on existing EAGLT02 checkout **8/8 PASS**, including 320/390/1440 px Track Refresh click/reattempt and a failed-then-recovered injected repository read. The test uses injected local responses; it does **not** prove signed-in HONOR requests, data access, RLS or security acceptance.

## Security decision and next work

**Do not** turn on a generic `/rest/v1` route, forward untrusted bearer tokens into a service-role proxy, bypass RLS with user-supplied IDs, change user roles, invent empty activity, or expose booking details to all Tailnet peers. The `customer_id` filter in Flutter is not an authorisation control. Retained `service_bookings` joins include potentially sensitive personal and provider fields.

The staged solution requires separately authorised isolated parity staging and full database/role backup, verified GoTrue JWT actor identity, restrictive row/column permissions and embedded relation exposure, real same-user and cross-user HTTP negatives, expiry/revocation tests, no write methods, host-firewall enforcement for direct 54321, and independent E6/G7/G8 privacy/security witnesses. Only after approval should exact account-scoped live reads be enabled for private Web and then separately tested on HONOR.

**Programme:** CX1 Track presentation/layout PASS, button synthetic retry PASS, user-observed repeated backend failure, private data-path OPEN. E6O-01, G7 31/31, G1–G10 0/10, D1–D5, T2.4 PAUSED and production NOT APPROVED all unchanged.

**This checkpoint makes no source, SQL, role, data, firewall, Tailscale, Docker, account, app build or production changes.**
