# Wantok Services — Living Roadmap

**Updated:** 2026-10-06

## Completed platform phases

- [x] Flutter + Supabase target architecture
- [x] Client/Vendor account model
- [x] shared marketplace/service catalogue
- [x] RBAC authority baseline
- [x] provider onboarding
- [x] availability/resource reservations
- [x] open request + quote workflow
- [x] taxi dispatch lifecycle
- [x] Food/Groceries commerce
- [x] Events
- [x] scheduled water passenger transport
- [x] booking-scoped Realtime messaging
- [x] Account/Profile management
- [x] Operations Admin vs Technical Control separation

## T1 — Technical Control Plane foundation — COMPLETE

- [x] 19-module registry
- [x] technical permission catalogue
- [x] technical access levels/templates
- [x] per-user/per-module access
- [x] effective permission RPCs
- [x] separate Technical Platform Administrator authority
- [x] Operations/Technical role-grant separation
- [x] secure module enable/disable/maintenance
- [x] technical audit events
- [x] `apps/wantok_tech`
- [x] permission-driven module navigation
- [x] production `tech.wantokservices.com` deployment route
- [x] living handover/roadmap + root `AGENTS.md`

## T2.1 — Technical Staff & Access Management — COMPLETE

- [x] Technical Access workspace
- [x] manageable-module filtering
- [x] controlled module staff listing
- [x] controlled account search by name/email
- [x] minimum search-length protection
- [x] assignable access-level filtering
- [x] assign/change/revoke module access
- [x] lower-level delegation
- [x] peer/higher access protection
- [x] Operations/Technical directory separation
- [x] Platform Administrator global-role protection
- [x] pgTAP security coverage
- [x] served Technical Control UI verification

## T2.2 — Module Configuration Schema Registry — COMPLETE

- [x] versioned module configuration-schema registry
- [x] supported field types and server-side validation rules
- [x] safe non-secret configuration override storage
- [x] secret-reference fields without secret-value disclosure
- [x] configuration read/update RPCs
- [x] `module.view` read-only inspection
- [x] `module.configure` write enforcement
- [x] audit before/after configuration changes
- [x] secret-reference audit redaction
- [x] typed configuration editor in Technical Control
- [x] module-specific configuration grouping/help text
- [x] seven initial active module schemas
- [x] pgTAP validation and permission tests
- [x] richer category-specific public service visuals

### T2.2 client experience polish — COMPLETE

- [x] standardise customer-facing product name as Wantok Services
- [x] PNG scenic custom-painter visual language
- [x] bilum-inspired custom bottom navigation
- [x] distinct client navigation: Home / Track / Inbox / Me
- [x] richer Home hierarchy and service spotlights
- [x] richer Food/Groceries discovery, search and local-vendor cards
- [x] richer Track and Inbox headers/empty states
- [x] Wantok Pay visual preview using Kina (K), without payment movement
- [x] Android emulator visual QA with no visible overflow
- [x] final client five-tab navigation: Home / Services / Track / Wallet / Inbox
- [x] dedicated searchable Services hub
- [x] embedded Wallet tab using Wantok Pay preview
- [x] move Account/Profile access to Home hero profile button
- [x] emulator QA for five-tab layout, Services, Wallet and Account/Profile

## T2.3 — Module health and dependency reporting — COMPLETE

- [x] acyclic module dependency registry and transitive health evaluation
- [x] registered health reporters/probes and secured control-state probe execution
- [x] reported/effective health state and transition history
- [x] dependency-impact views before disable/maintenance actions
- [x] maintenance/degraded-state presentation in Technical Control
- [x] separate `module.health_run` permission; auditors remain read-only
- [x] restricted dependency identity/description privacy and pgTAP coverage

## CX1 — Client Experience Completion Gate — IN PROGRESS

Required sequence: **T2.3 checkpoint → CX1 → T2.4**. T2.4 must wait until the client gate is completed with recorded evidence.

- [x] automated five-tab navigation, Home search and profile entry/back checks
- [x] working service search/family filters and entry/back coverage for 11 service categories
- [x] replace inactive Home search/QR and family controls; clarify planned Wallet actions
- [x] distinguish load failures from empty records; retry safely after repeated failures
- [x] responsive scenic headers/grids, narrow mode menu and accessible selected-tab actions
- [x] automated 320/390/800-pixel layouts at 1.5x text across discovery and five client tabs
- [x] preserve Kina (K) amounts and Wantok Pay preview-only boundary
- [x] customer Client/Vendor switch does not grant provider/technical administration
- [x] add 31 focused offline client regressions and record their limitations
- [x] CX1 implementation checkpoint: full Flutter checks, 364 pgTAP tests and diff check PASS
- [ ] fresh signed-in Android/Web visual QA using existing development sessions/accounts
- [ ] live read-only journey checks, especially Taxi map/location/history and populated Track/Inbox/account records
- [ ] complete gate evidence review before T2.4

Acceptance evidence and initial findings: `docs/CX1_CLIENT_EXPERIENCE_GATE.md`.

Use existing local development accounts/data. No Supabase reset, reseed, account replacement or payment movement is part of CX1.

## T2.4 — Diagnostics, logs and jobs — AFTER CX1

- [ ] diagnostics adapters
- [ ] central/module log adapters
- [ ] background job/queue visibility
- [ ] approved job actions
- [ ] richer technical audit views

## T2.5 — Integrations and high-risk controls

- [ ] integration status/configuration
- [ ] secret-reference model integration
- [ ] high-risk action confirmation/approval
- [ ] critical-action dual control where appropriate

## T3 — Operational hardening

- [ ] production observability
- [ ] alerting/escalation
- [ ] maintenance windows
- [ ] incident/status history
- [ ] backup/restore controls where safely appropriate
- [ ] technical runbooks

## Wantok Pay design gate

Do **not** implement payment movement until decisions are made for:

- PNG payment rails/providers
- cards/mobile money/bank integration
- cash boundary
- wallet scope
- provider settlement
- commissions/fees
- refunds/disputes
- reconciliation
- custody/regulatory boundary
- secrets/key management

After those decisions, implement payment adapters behind a common interface and technical permissions.

## Checkpoint discipline

Every meaningful phase ends with:

1. full validation;
2. update `docs/HANDOVER.md`;
3. update this roadmap;
4. Git checkpoint;
5. leave the working tree clean.
