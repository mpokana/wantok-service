# CX1J — HONOR Tailnet public catalogue gate and mobile API dependency register

**Date:** 14 October 2026 PNG | **Device:** EAGLT02 only | **Source branch:** `feature/flutter-platform-v1` at `b330ba9` | **Disposition:** Private development preview, not production or E6 acceptance.

## Owner-confirmed evidence

The HONOR phone on Digicel/bmobile mobile data with Tailscale connected displayed the Wantok Services signed-in Client Home, Services, Explore, Track and Inbox pages at `https://eaglt02.tailfb0609.ts.net:8443/`. The screenshots confirm **browser navigation and mobile web authentication**, not successful reading of all backend data or native Android APK parity.

The former error `127.0.0.1:54321` was an incorrect mobile/backend origin in the older build. The corrected Flutter JavaScript SHA-256 `3BC70DDEF8FF87B0B8FE37386E81B6E5F43919987771A4C53BD6995EEA5B8026` uses `https://eaglt02.tailfb0609.ts.net`. A fresh Flutter render test reproduced the earlier white screen due to a missing published-branding RPC. Existing isolated `.wantok/cx1-branding-only-rpc-3303.py` now permits **only** `POST /rest/v1/rpc/get_published_wantok_branding` for public theme/media; browser preflight and zero-argument `null` body supported. An independent clean Chrome test displayed the full login form after the correction. Full RPC and database REST are *not* available on Tailnet.

The owner-provided signed-in screenshots then showed a working Home and Services shell, but Home's *Popular categories* initially displayed **“Could not load services from the backend”**, while Track and Inbox had missing private data. The green 8443 acceptance banner was interfering with header layout. This banner is removed from the isolated `D:\Wantok_CX1_Tailnet_8443_VersionProof_20261014\web\index.html`, backed up before editing; Flutter JS digest unchanged. The normal :443 client and main repository's generated web build are unchanged.

## API dependency map: public versus identity-bound

| Client view / feature | Actual repository / endpoint | Data classification | 8443 gateway status |
| --- | --- | --- | --- |
| Launch/Appearance | `BrandingRepository.getPublished` → `POST /rest/v1/rpc/get_published_wantok_branding` | Public published theme/media; explicitly anon EXECUTE | **OPEN, read-only allowlist** |
| Sign-in/auth session | `WantokAuthService.signIn` → `/auth/v1/token` | Credentials and bearer session; TLS required | **OPEN** via pre-existing HTTPS `/auth/v1` tunnel; owner verified mobile login |
| Home/Services active category list | `CatalogRepository.loadActiveServices` → `GET /rest/v1/service_categories`, `select` exact 12 public fields, `is_active=eq.true`, sorted | Approved/active catalogue only; installed RLS true, anon SELECT true, public-read policy observed | **OPEN, anonymous read-only exact-filter gateway**, owner retest pending |
| Home/Services recommended providers | `ProviderDiscoveryRepository.loadTopProviders` → `list_top_client_providers` | Public discovery candidate but E6K public profile/field privacy still independently gated | **BLOCKED** until validated exact public fields/limits and independent decision |
| Services/Explore provider search and places | `search_client_providers_international`, `list_client_provider_locations`, `provider_services` etc. | Public discovery with provider approval and geography requirements | **BLOCKED** until separate approved read-only contract |
| Account / roles | `WantokAuthService.loadRoles` → `GET /rest/v1/user_roles` | Private role metadata, E6R/D1–D5 privacy gate | **BLOCKED**; account-specific actor checks required |
| Saved items / service recommendations | `list_my_saved_items` and account-scoped recommendations | Private user preferences/activity; some writes exist in client repo | **BLOCKED** for private data |
| Track activity | `ReservationRepository.loadMyReservations` → `GET /rest/v1/service_bookings` with `customer_id`, joined quotes, reviews and contact details | **Highly sensitive** booking/contact information and financial amounts | **BLOCKED** pending authorised real session/RLS witness |
| Inbox service conversations | `MessagingRepository.loadThreads` → `list_my_booking_conversations`; `conversation_messages` stream; send/mark read RPCs | **Highly sensitive** private messages and booking-linked conversations; some actions mutate | **BLOCKED**; no anonymous bypass or service_role forwarding |
| Inbox help/support | `WantokAiAgentRepository.loadMyHandoffs` → `ai_agent_handoff_requests` `user_id` read | Private user support requests and status | **BLOCKED** pending independent identity/role witnesses |
| Wallet | Client Wantok Pay preview | Planned-only, no payment activation | **Remain preview**, no integrations or charges |

**Important:** These paths reflect checked-in source, not a complete live HTTP trace of every signed-in flow. The user screenshots support that mobile navigation worked, but service/Track/Inbox data loading did not. There are more endpoints in taxi, commerce, events, vendor onboarding and Technical/Operations; **none** are approved by this work.

## CX1J safe public route

`scripts/dev/cx1_public_category_gateway.py` is the **source-only reproducible counterpart** of the current ignored local server `.wantok/cx1-public-category-only-3304.py`. It binds **127.0.0.1:3304** (not an internet interface). Runtime local `config/local.json` contains only the existing publishable Supabase key; the key is not committed and the gateway ignores all caller-provided Authorisation tokens, passing *only* the anonymous key to its upstream. The sole Tailnet route:

`https://eaglt02.tailfb0609.ts.net/rest/v1/service_categories` → `http://127.0.0.1:3304/rest/v1/service_categories`.

Exact schema contract: `select=id,slug,name,description,vertical,booking_mode,icon_key,is_active,sort_order,show_on_home,show_in_services,image_path`, **`is_active=eq.true` required**, approved sort only, `limit<=100`, `offset<=10000`. CORS allowed only for HTTPS main and 8443 origins. **GET/OPTIONS only**; any POST/PUT/PATCH/DELETE, unknown REST path, wildcard/extra column, inactive filter, OR bypass or excessive range fails closed. The adapter rechecks that every returned row is active and strips unapproved fields. No SQL writes or migrations, no service_role exposure, no real account rows or application-side user data.

The local PostgreSQL `public.service_categories` catalogue confirmed `relrowsecurity=true`, `anon SELECT=true`, `PUBLIC SELECT=false` and an installed public-read RLS policy. An upstream call with only anonymous credentials returned HTTP 200, **20 active public categories**, no private columns shown. Gateway checks:
- **13/13** synthetic policy/unit tests — `python scripts/qa/cx1_public_category_gateway_unit_test.py`.
- **15/15** exact live allow/deny probes including real local read and write denial — `python scripts/qa/cx1_public_category_gateway_integration_test.py` on EAGLT02 with the loopback gateway running.
- HTTPS `GET` returned HTTP **200**, 20 public categories with exactly the selected fields and `Access-Control-Allow-Origin` for the 8443 test origin; HTTPS `OPTIONS` **204**; `POST /rest/v1/rpc/list_my_booking_conversations` still denied (HTTP 501 by the generic Tailscale fallback, **not an identity authorisation witness**).
- Existing `/auth/v1` and sole published branding RPC were preserved, not expanded. No full `/rest/v1` wildcard forwarding.

**Limitations:** The gateway alone does not prove the signed-in HONOR Home category UI has refreshed; owner must reopen/reload and report. The category data is not a provider approval, booking guarantee or activated payment. Do not automatically accept other read paths simply because they use GET or SQL RLS.

## Isolated regression acceptance — automated engineering only

- Exact worktree source `b330ba9` prior to CX1J source/docs commit: new Python public policy **13/13 PASS**, integration to existing EAGLT02-only loopback source proxy **15/15 PASS**, HTTPS CORS GET200/20 active public rows and OPTIONS204; private RPC denied.
- Existing E6W non-mutating gateway/security regression **exit 0**: disconnected seven-proposed-migration SQL **301/301 assertions over 16 suites**, fixture transactions rolled back and isolated container removed, synthetic signed-JWT auth, E6 independence, privacy source/local and evidence checks PASS. No persistent SQL writes or E6 acceptance.
- Complete detached Flutter static source **7 analyses clean and Client 135 + Operations 43 + Technical 38 = 216/216 widget tests PASS** (exit 0). No Flutter production build/source modifications from CX1J.
- Owner's **real HONOR Home category refresh and banner-free screenshot remain pending** despite endpoint-level success. This release is `productionApproved:false`.

## User acceptance outstanding / next safe work

1. Owner opens `https://eaglt02.tailfb0609.ts.net:8443/` again with Tailscale connected and fresh reload. Confirm **green test banner no longer covers header**, Home Popular categories list, and Services reference cards.
2. Track and Inbox errors are **expected** while private routes remain excluded. Do not weaken RLS, forge JWTs, or proxy with a service-role token.
3. Inventory minimum read-only role/booking/help endpoints for a dedicated **owner-authorised staging** matrix: actor identity, real GoTrue session, RLS, deny-other-user, sensitive columns, route pattern, read vs writes, rollback. E6 G7 31/31 remains NOT EXECUTED; G1–G10 remain 0/10 accepted; E6O-01 existing audit/notification SQL EXECUTE grants still OPEN; E6S D1–D5 private role disclosure unresolved.
4. Remove visual acceptance marker in any eventual *approved* non-test release, preserve SHA-backed rollback. **Native Android APK still has separate backend configuration and was not rebuilt.**
5. This loopback Python gateway is **not a Windows service or auto-start task**; after EAGLT02 reboot, recheck Supabase, Serve and adapter service explicitly before claiming accessibility. Future deployment must have independent ops/security review and service monitoring.

EAGLT02 main Git worktree contains user-owned staged `docs/BUSINESS_PLAN_V1_20261013.md`, `docs/COMMISSION_POLICY_V1_20261013.md` and untracked `supabase/snippets/`; do **not** stage, overwrite or commit them. CX1J source/docs were prepared in a separate clean worktree to preserve these files and all unrelated worktrees. T2.4 remains PAUSED, E7+ and production remain blocked; `productionApproved:false`.
