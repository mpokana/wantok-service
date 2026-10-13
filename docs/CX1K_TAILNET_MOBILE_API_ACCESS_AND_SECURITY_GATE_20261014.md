# CX1K — HONOR private HTTPS API route boundary and blocked live-data matrix

**Date:** 14 October 2026 | **Machine:** authorised EAGLT02 | **Client:** Flutter Wantok Services | **Current branch baseline:** `b330ba9` | **Disposition:** P1 Client Experience security/source readiness, **not** E6/production acceptance.

## Owner-observed HONOR result

User screenshots from the existing private Tailscale network show **successful authenticated login and navigation** in the CX1 HTTPS test site on the HONOR device using mobile data without USB. Visual layouts for **Home, Services, Explore, Track and Inbox** load. Category cards and bundled images render. This is owner-observed mobile Web, **not a new Android APK**, production release or independent G7 security witness.

The same screenshots show explicit failures:

| UI area | Observed mobile behaviour | Grounded code/backend dependency | Current classification |
| --- | --- | --- | --- |
| Home popular categories | “Could not load services from the backend” in screenshot | `CatalogRepository.loadActiveServices` GET `service_categories` with exact active-only fields/ordering | **Public read**; matching tightly validated GET now configured by independent tailnet work, retest on HONOR pending |
| Services catalogue | Bundled category imagery/cards visible | Static assets plus `service_categories`, provider/service lookup when drilling down | **Static UI pass**; public service data depth not validated |
| Explore | Editorial imagery visible | Bundled art; `search_client_providers_international`, `list_client_provider_locations`, `list_top_client_providers`, provider-specific records | **Public candidate, fields/approval must be reviewed**, no broad enablement |
| Track | “Could not load your activity” | `service_bookings`, `rides`, `commerce_orders`, `event_registrations` restricted by account identity | **Account-private read**: E6/G7/G8 identity, RLS/REST and stage witnesses required |
| Inbox | “Could not load service conversations” | `list_my_booking_conversations` plus `conversation_messages` feed, `send_conversation_message` and read receipts | **Account-private read / realtime / write**; not safe for anonymous passthrough |
| Saved | Not shown in latest HONOR screenshots | `list_my_saved_items` RPC | **Account-private read**, no new witness |
| Wallet | Tab visible but not exercised in supplied screenshots | Personal balance and gated payments/commerce | **Not tested.** Do not imply payments active |
| Account | Profile icon visible | `get_my_account_profile_v2`, account changes and identity operations | **Account-private**; no new witness |

**Critical:** The application already reports errors for unavailable private data. Those errors are not equivalent to zero bookings or zero messages. Do not replace them with fake empty lists, public data, broad service-role responses, or fabricated demo accounts.

## Exact private Tailscale Serve route state during CX1K check

The read-only `tailscale serve status --json` inspection on EAGLT02 confirms HTTPS `443` and diagnostic `8443` and the following **five exact handler paths**, all backed by loopback-only services:

| Port / path | Routed service | Usage | Risk boundary |
| --- | --- | --- | --- |
| 443 `/` | `127.0.0.1:3000` | Original Flutter mobile web UI | Public website presentation via existing owner-tailnet only |
| 443 `/auth/v1` | `127.0.0.1:54321/auth/v1` | GoTrue login | Authentication, not general database REST |
| 443 `/rest/v1/rpc/get_published_wantok_branding` | `127.0.0.1:3303` | Public published appearance, JSON `theme`/`media` only | Dedicated allowlisted adapter; prior exact-parameter/CORS validation |
| 443 `/rest/v1/service_categories` | `127.0.0.1:3304` | Active service category list | Separate existing allowlisted read adapter; preserve owner/parallel changes |
| 8443 `/` | `127.0.0.1:3302` | Versioned isolated mobile diagnostic site | Temporary test origin; **not production** |

**NO** broad `/rest/v1`, account-table, message-write, service-role or general RPC route is configured in Tailscale Serve; Funnel is not enabled in the examined Serve configuration. The web root fallback is a separate static file server, not proof of end-to-end REST denial against every future or direct network path. **A prior owner HONOR browser test directly reached `http://100.127.124.75:54321/auth/v1/health` over Tailscale.** Thus the Serve allowlist alone does **not** prevent peers from contacting the developer Supabase listener by its host port. The current review has not validated a host-firewall restriction for `54321`, direct PostgREST/SQL roles, session revocation, or independent bearer/JWT negative cases. An independently approved EAGLT02 inbound-firewall scope and actual external denial witness are prerequisites before claiming backend isolation. The user-directed all-device Tailscale connectivity can remain intact while sensitive service ports are individually restricted. **No firewall modification was applied in CX1K.**

The owner expressly wants all their Tailscale devices to communicate. **Do not change tailnet-wide allow-all grants** to achieve application security. Keep application identity, host firewalls, REST allowlists and Supabase row-level policies independently enforced.

## Source-derived exposure contract

`scripts/qa/cx1k-tailnet-api-boundary.mjs` inventories three permitted classes (GoTrue login, published-branding read, active-category read), and **11** separately source-marked blocked/unreviewed categories (including private bookings, rides, commerce, event registrations, conversations/realtime/messages, saved items, account profile, and provider discovery/service fields).

`node scripts/qa/cx1k-tailnet-api-boundary.mjs --local`:

- Calls only `tailscale serve status --json` and reads checked-in repository files; performs no SQL, browser login, HTTP mutation, token inspection, account data access or Tailscale change.
- Fails closed when extra/missing handler paths appear, a target bypasses the loopback-only public adapters, a broad REST prefix/private route/write RPC is published, Funnel appears in checked Serve config, or relevant source callsites unexpectedly change.
- Passing gives `CX1K_SERVE_ROUTE_SCOPE_MATCH`, **not** app function acceptance, privacy approval, G8 stage attestation or proof of HTTP permission enforcement.

The paired synthetic test suite **19/19 PASS** includes explicit negative cases for widened `/rest/v1`, existing writer exposure, conversation writes, account-private bookings, unexpected hosts, disabled HTTPS, extra handler metadata, disabled active-only category filters and missing source references.

## Next safe work, in order

1. **Public categories:** Confirm the active-only allowlisted category request and exact response projection on the HONOR device with a new screenshot; do not infer a successful Home load from HTTP 200 alone. Public fields must remain subject to E6K privacy/public data decisions.
2. **Provider discovery:** Independently assess public output field minimisation, approval/status filters and true owner/RLS definer trust before exposing `search_client_providers_international`, `list_top_client_providers` or raw provider tables. Do not enable provider activation in testing.
3. **Private signed-in reads:** Securely design limited actor-scoped API routes *only after* owner-approved isolated parity staging, direct negative tests with real GoTrue principals, proper RLS/SECURITY DEFINER audits and G7/G8 witnesses. The frontend's `user_id` filter alone is **not authorisation**. Keep writes denied.
4. **Track, Inbox, Saved and account:** Run user-visible read-only tests with proper permitted API access once signed off; separately witness navigation/Refresh and pending CX1 official gate cases. For each, distinguish **zero real records** from **backend unavailable**.
5. **Presentation:** The diagnostic green banner was observed obscuring mobile app header. The isolated 8443 HTML later no longer contains the banner (observed on read-only inspection); don't overwrite concurrent preview changes. Ask for new HONOR screenshots to verify actual removal.
6. **Native APK:** Separately build and owner-install a native Android build with an HTTPS/Tailscale backend rather than `127.0.0.1`, only after the relevant backend access and privacy gates are satisfied. Do not conflate the successful mobile Web login with a fixed installed Android APK.

## Boundary and programme state

- EAGLT02 only; other GVE/VPS devices not changed.
- User-owned staged `docs/BUSINESS_PLAN_V1_20261013.md`, `docs/COMMISSION_POLICY_V1_20261013.md` and untracked `supabase/snippets/` must not be staged, reverted or modified by CX1K.
- Source-only checkpoint in independent worktree; **no SQL migrations, no ACL changes, no real account actions**, no technical/T2.4 changes, no restricted RPC/public-profile enablement and no private data copied to GitHub.
- **E6O-01 existing untrusted writer grants OPEN**, D1–D5 unsupplied, G7 **31/31 NOT EXECUTED**, G1–G10 **0/10 ACCEPTED**. CX1 partial mobile web appearance accepted by owner, full CX1 data-path acceptance OPEN, T2.4 PAUSED, E7+/production NOT APPROVED.
