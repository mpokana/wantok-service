# Wantok Service — Living Roadmap

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

- [x] platform module registry
- [x] 19 initial module keys
- [x] technical permission catalogue
- [x] technical access levels/templates
- [x] per-user/per-module access
- [x] effective permission RPCs
- [x] separate Technical Platform Administrator authority
- [x] Operations/Technical role-grant separation
- [x] delegated lower module access with anti-escalation
- [x] secure module enable/disable/maintenance RPC
- [x] technical audit events
- [x] pgTAP authority tests
- [x] `apps/wantok_tech`
- [x] permission-driven module navigation
- [x] module overview/status workspace
- [x] production `tech.wantokservices.com` deployment route
- [x] Flutter validation updated for all three apps
- [x] living handover/roadmap + root `AGENTS.md`

## T2 — Technical operations depth — NEXT

Recommended order:

- [ ] technical staff/access-management UI
- [ ] module configuration-schema registry
- [ ] safe typed configuration editor
- [ ] module health/dependency reporting
- [ ] diagnostics adapters
- [ ] central/module log adapters
- [ ] background job/queue visibility and approved actions
- [ ] integration status/configuration
- [ ] secret-reference model (never reveal secret values)
- [ ] high-risk action confirmation/approval
- [ ] richer technical audit views

## T3 — Operational hardening

- [ ] production observability
- [ ] alerting/escalation
- [ ] module dependency impact checks
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

## Later shared work

- profile/media/document storage
- push notifications
- safety/SOS/incidents
- disputes/refunds
- KYC document workflows
- promotions/rewards
- production deployment hardening
- defined Wantok Neurons API intelligence integrations

## Checkpoint discipline

Every meaningful phase ends with:

1. full validation;
2. update `docs/HANDOVER.md`;
3. update this roadmap;
4. Git checkpoint;
5. leave the working tree clean.
