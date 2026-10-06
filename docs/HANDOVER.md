# Wantok Services — Living Handover

**Updated:** 2026-10-06
**Repository:** `D:\Project-M.2\wantok-service-recovery`
**Branch:** `feature/flutter-platform-v1`

## Resume here

The current safe checkpoint is **T2.3 Module Health and Dependency Reporting**. This file is committed with that checkpoint; run:

`git log -1 --oneline`

to resolve its exact commit hash.

Before any new task, read root `AGENTS.md`, this file, and `docs/ROADMAP.md`.

## Product identity

- Product: Wantok Services
- Domain: **wantokservices.com**
- Stack: Flutter + Supabase
- Public app: `apps/wantok_app`
- Operations administration: `apps/wantok_admin` / `admin.wantokservices.com`
- Technical administration: `apps/wantok_tech` / `tech.wantokservices.com`

Operations and Technical authority are separate server-side. One does not imply the other.

## Verified implemented state

Checkpointed platform includes:

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
- T2.1 Technical Staff & Module Access Management
- T2.2 versioned typed module configuration and Technical Control editor
- T2.2 PNG-rich client experience polish across Home, Food/Groceries, Track, Inbox and Wantok Pay preview
- T2.3 module health/dependency reporting, scoped probe execution and impact previews

### Technical Control T1

- 19-module registry
- module/platform permission catalogue
- Technical Platform Administrator authority
- Technical Administrator / Module Administrator / Support / Auditor levels
- per-user/per-module assignments
- effective permission RPCs
- permission-driven module navigation
- secure module enable/disable/maintenance
- audited module state/access changes
- separate Flutter Web Technical Control Panel

### T2.1 staff/access management

- Technical Access workspace appears only where the actor has `module.permissions`
- controlled staff list per module
- controlled account search by name/email
- minimum 2-character search
- assign/change/revoke module access
- assignable levels limited below the actor's authority
- peer/higher assignments shown as protected
- peer downgrade/revoke blocked server-side
- Module Administrator/Support/Auditor cannot delegate access
- Operations Admin cannot use Technical staff search
- Technical Platform Administrators remain global and are not ordinary module assignments

### T2.2 typed configuration

- versioned per-module configuration schemas
- typed fields with server-side validation
- schema defaults plus controlled overrides
- `module.view` read-only inspection and `module.configure` editing
- batched schema-versioned updates with audit history
- secret references only (`env://`, `vault://`, `external-secret://`, `supabase://`), never secret values
- secret references redacted from audit metadata
- initial schemas for Taxi, Water Transport, Messaging, Food, Groceries, Delivery and Notifications
- typed Technical Control editor with reset/discard/save workflows
- refreshed public service grid with category-specific colours and stronger lightweight icons

### T2.2 PNG-rich client experience polish

- product-facing name standardised as **Wantok Services** while native package IDs remain unchanged
- PNG scenic visual language implemented with lightweight custom Flutter painters: mountain forms, tropical accents and abstract bird-of-paradise treatment
- bilum-inspired custom bottom navigation replaces Material/Grab-like navigation
- original four-tab layout was superseded by **Home · Services · Track · Wallet · Inbox**
- richer Home hierarchy with scenic hero, service discovery, Wantok Pay preview strip, service spotlights and PNG purpose banner
- Food/Groceries now use scenic commerce heroes, search/filter surfaces and richer local-vendor discovery cards
- Track and Inbox have dedicated scenic headers and polished empty states
- Wantok Pay remains a visual preview only with **Kina (K)** display; no payment movement is enabled
- visible PGK-facing customer amounts use Kina-style `K` formatting where appropriate
- live Android emulator QA completed for Home, Food, Track and Inbox without visible overflow
- client primary navigation finalised as **Home · Services · Track · Wallet · Inbox**
- dedicated searchable Services hub added instead of duplicating the Home surface
- Wantok Pay preview embedded directly as the Wallet tab without a nested app bar
- Account/Profile moved out of primary navigation and remains accessible from the Home hero profile button
- live Android emulator QA completed for Home, Services, Wallet and Account/Profile with no visible bottom-navigation overflow

### T2.3 health and dependencies

- explicit acyclic dependency graph with required/optional failure effects
- reported health from registered probes; effective health includes module state and transitive dependencies
- current report/state stores and status transition history
- built-in `control.state` probe reports control-plane state only, not end-to-end runtime availability
- external reporter contract exists; runtime/integration adapters remain later work
- `module.view` reads, separate `module.health_run` execution; auditors cannot run probes
- dependency identities/descriptions outside visible scope are redacted
- Technical Control Health & dependencies page and pre-action impact confirmations
- four migrations `20261006120000` through `20261006123000` already applied locally; do not replay/reset

## Validation baseline

At this checkpoint:

- all shared Flutter packages: analysis PASS
- Wantok app: analysis + smoke test PASS
- Wantok Operations Admin: analysis + smoke test PASS
- Wantok Technical Control: analysis + smoke test PASS
- database: **16 files / 364 pgTAP tests PASS** (all fixtures roll back)
- Android visual QA was last recorded at T2.2; CX1 requires fresh client evidence
- production Docker Compose parse PASS was recorded at T2.2; deployment files unchanged
- `git diff --check`: PASS

## Development environment

Primary workstation: **EAGLT02**

Project:
`D:\Project-M.2\wantok-service-recovery`

Local Supabase: Docker.

Android emulator uses ignored:
`.wantok/local-android.json`

and reaches the host through `10.0.2.2:54321`. Do not replace browser/web configuration with the emulator bridge address.

The local Mansfield development account has `tech_platform_admin` only in the local database. This is not seeded by migration and must not be assumed in production.

Technical Control development server may be run on:

`http://127.0.0.1:3100`

## Security/architecture rules

- Use migrations for schema/security changes.
- UI hiding is never authorisation; enforce permissions server-side.
- Operations Admin cannot grant `tech_*` authority.
- Technical Platform Admin does not inherit Operations approval authority.
- Providers cannot self-verify/self-activate.
- Technical module/access changes are audited.
- Lower/equal module administrators cannot modify peer/higher assignments.
- Configuration writes must be schema-versioned and validated server-side.
- Secret-bearing configuration stores references only; never expose secret values in ordinary UI or audit metadata.
- Do not expose production secrets, arbitrary SQL or shell execution in ordinary control-panel UI.
- Keep services modular so one service can be repaired/disabled independently.
- Wantok Services and Wantok Neurons remain separate systems.

## Next phase

**CX1 — Client Experience Completion Gate**, before **T2.4**.

Required sequence: **checkpoint T2.3 → complete CX1 → T2.4 diagnostics/logs/jobs**.

CX1 verifies the five client tabs, Home profile access, service search/entry/back journeys, loading/error/retry/empty states, narrow screens/enlarged text, accessible controls, Kina formatting and the Wallet preview boundary. Resolve misleading or inactive controls and record focused regression/QA evidence before calling the gate complete. See `docs/ROADMAP.md` for the checklist and `docs/CX1_CLIENT_EXPERIENCE_GATE.md` for acceptance evidence and initial findings.

Preserve the local development accounts, roles and data. Do not reset/reseed Supabase or replace working modules/configuration. At resume there are two local auth users/profiles and one local `tech_platform_admin` grant.

T2.4 remains deferred until CX1 passes. Integrations and high-risk approvals follow later.

Do not begin Wantok Pay transaction movement until payment-rail and settlement decisions are made.

## Recovery rule

If a future chat loses context:

1. open this repository;
2. read `AGENTS.md`, `docs/HANDOVER.md`, `docs/ROADMAP.md`;
3. run `git status --short --branch` and `git log -5 --oneline`;
4. preserve a dirty tree until its purpose is understood;
5. continue the roadmap rather than reconstructing architecture from memory.
