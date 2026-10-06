# Wantok Service — Living Handover

**Updated:** 2026-10-06
**Repository:** `D:\Project-M.2\wantok-service-recovery`
**Branch:** `feature/flutter-platform-v1`

## Resume here

The current safe checkpoint is **Technical Control Plane T1 foundation**. This file is committed with that checkpoint; run:

`git log -1 --oneline`

to resolve its exact commit hash.

Before any new task, read root `AGENTS.md`, this file, and `docs/ROADMAP.md`.

## Product identity

- Product: Wantok Service
- Domain: **wantokservices.com**
- Stack: Flutter + Supabase
- Public app: `apps/wantok_app`
- Operations administration: `apps/wantok_admin` / `admin.wantokservices.com`
- Technical administration: `apps/wantok_tech` / `tech.wantokservices.com`

Operations and Technical authority are separate server-side. One does not imply the other.

## Verified implemented state

Checkpointed platform now includes:

- Client/Vendor account model and service catalogue
- provider onboarding/verification boundaries
- resource availability/reservations
- open requests and quotes
- taxi dispatch lifecycle
- Food/Groceries commerce
- Events
- scheduled water passenger transport
- booking-scoped Realtime messaging/read receipts
- Account/Profile management and preferences
- Technical Control Plane T1

T1 Technical Control includes:

- 19-module registry
- module/platform permission catalogue
- Technical Platform Administrator authority
- Technical Administrator / Module Administrator / Support / Auditor module levels
- per-user/per-module assignments
- effective permission RPCs
- permission-driven technical module navigation
- secure module enable/disable/maintenance
- audited module state/access changes
- lower-level delegated access with anti-escalation rules
- separate Flutter Web Technical Control Panel
- production deployment route at `tech.wantokservices.com`

## Validation baseline

At this checkpoint:

- all shared Flutter packages: analysis PASS
- Wantok app: analysis + smoke test PASS
- Wantok Operations Admin: analysis + smoke test PASS
- Wantok Technical Control: analysis + smoke test PASS
- database: **13 files / 247 pgTAP tests PASS**
- Docker Compose production configuration parse: PASS
- `git diff --check`: PASS

## Development environment

Primary workstation: **EAGLT02**

Project:
`D:\Project-M.2\wantok-service-recovery`

Local Supabase: Docker.

Android emulator uses ignored:
`.wantok/local-android.json`

and reaches the host through `10.0.2.2:54321`. Do not replace browser/web configuration with the emulator bridge address.

Local development owner account is explicitly granted `tech_platform_admin` in the local database only. This is not seeded by migration and must not be assumed in production.

## Security/architecture rules

- Use migrations for schema/security changes.
- UI hiding is never authorisation; enforce permissions server-side.
- Operations Admin cannot grant `tech_*` authority.
- Technical Platform Admin does not inherit Operations approval authority.
- Providers cannot self-verify/self-activate.
- Technical module changes are audited.
- Do not expose production secrets, arbitrary SQL or shell execution in ordinary control-panel UI.
- Keep services modular so one service can be repaired/disabled independently.
- Wantok Service and Wantok Neurons remain separate systems.

## Next phase

**T2 — Technical operations depth**

Next useful work:

1. technical staff/access-management UI;
2. module configuration schemas;
3. module health/dependency reporters;
4. logs/diagnostics adapters;
5. background jobs/queue controls;
6. integration status/configuration;
7. high-risk action confirmation/approval.

Do not begin Wantok Pay transaction movement until payment-rail and settlement decisions are made.

## Recovery rule

If a future chat loses context:

1. open this repository;
2. read `AGENTS.md`, `docs/HANDOVER.md`, `docs/ROADMAP.md`;
3. run `git status --short --branch` and `git log -5 --oneline`;
4. preserve a dirty tree until its purpose is understood;
5. continue the roadmap rather than reconstructing architecture from memory.
