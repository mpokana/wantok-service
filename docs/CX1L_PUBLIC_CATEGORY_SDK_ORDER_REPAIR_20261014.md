# CX1L — Public category Flutter SDK order compatibility (14 October 2026)

**Scope:** EAGLT02 tailnet-only CX1 Client preview, public `service_categories` gateway on loopback `127.0.0.1:3304`. Not production, E6 security acceptance or native APK acceptance.

## User observation and root cause

Owner-supplied HONOR screenshot shows `Could not load services from the backend` in Home Popular categories; owner reports the same on desktop Web. The local Supabase auth endpoint is healthy and the strict public gateway returns 20 active categories when queried with a simplified sort order. Installed Dart `postgrest-2.9.1` `select()` strips unquoted spaces, while `order('sort_order', ascending: true).order('name', ascending: true)` emits `order=sort_order.asc.nullslast,name.asc.nullslast`. The CX1J adapter originally accepted `sort_order.asc,name.asc` but rejected this exact SDK order (HTTPS **400**), despite the same 12-column active-only GET otherwise succeeding (**200**). This is a gateway compatibility bug, not absent catalog data.

## Minimal correction

Add **only** `sort_order.asc.nullslast,name.asc.nullslast` to `ORDER` in `scripts/dev/cx1_public_category_gateway.py` and the locally running ignored `cx1-public-category-only-3304.py`. Preserve the route, existing exact 12-column SELECT, `is_active=eq.true`, order allowlist, paging bounds, anonymous-only upstream credentials, HTTPS origin CORS, denied methods, and all private/RPC restrictions. Source-level unit tests add SDK-positive and reversed-order-negative cases. Integration suite adds the real SDK sort route and checks public fields/active-only response.

The ignored EAGLT02 runtime adapter was checksum-backed up unchanged at `D:\Project-M.2\wantok-service-recovery\.wantok\cx1-public-category-only-3304.py.pre-cx1l-20261014.bak`, compiled and restarted after a strict owner/PID check. The Web JavaScript SHA-256 remains `3BC70DDEF8FF87B0B8FE37386E81B6E5F43919987771A4C53BD6995EEA5B8026`; no Flutter rebuild is necessary for this API order compatibility repair.

## Validation and open witnesses

- Old exact SDK query: **HTTP 400**; same query after scoped adapter restart: HTTPS **HTTP 200**, **20 active categories**, exact 12 public fields. No inactive record returned.
- Source gateway synthetic checks: **15/15 passed**; live local public allow/deny cases: **16/16 passed**. Includes private table/writer, wildcard/sensitive column, unknown filter, inactive, duplicate parameter and writes denied. Existing CX1K five-route read-only source audit remains the security boundary.
- **Still pending:** owner hard refresh on both desktop and HONOR (mobile data + Tailscale) to witness Popular categories rendering and banner removal. A working API endpoint is not the same as signed-in UI acceptance.
- **Not touched:** shared Supabase SQL/roles/accounts, auth keys, Tailscale Serve/Funnel/ACL/firewall, E6O-01 audit writer risk, native APK, Track/Inbox/Saved private APIs, T2.4, production. G7 remains 31/31 unexecuted, G1–G10 0/10, production approval false. Existing open direct host-port `54321` risk still requires independent authorisation and negative testing.

## Recovery

If the new gateway behaves unexpectedly, stop only the verified Python process bound to `127.0.0.1:3304`, restore the locally checksum-preserved `.pre-cx1l-20261014.bak` script to the ignored adapter path, and restart the same loopback-only adapter. Do not modify Tailscale Serve routes, local database, user sessions or the current served Web bundles.
