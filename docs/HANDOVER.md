# Wantok Services — Living Handover

**Updated:** 2026-10-06
**Repository:** `D:\Project-M.2\wantok-service-recovery`
**Branch:** `feature/flutter-platform-v1`

## Resume here

The current working phase is **CX1A consumer account, saved, reviews and delegated-service foundation**; the **CX1 gate remains open before T2.4**. T2.3 is checkpointed at **`46d6208`** and the prior CX1 reliability/discovery checkpoint is **`0c33a37`**. The current CX1A changes must be validated and checkpointed before moving on. Run:

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
- CX1 reliability/discovery baseline plus CX1A richer client account/privacy, linked identities, saved service categories, trusted people, booking-linked reviews and richer Wallet preview (gate open)

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

### CX1 implementation and evidence

- **Client navigation is locked as Home · Services · Track · Wallet · Inbox.** Do not rename it to Grab-style Discover/Activity/Payment/Messages.
- Home search selects Services; profile route has an app bar/back button.
- Services owns rich discovery: family filters/search/clear, safe loading/error/empty states, Saved shortcut and per-category bookmark controls.
- Account/Profile now includes bio/avatar URL foundation, privacy/share controls, linked-account management, Saved, Trusted people, My reviews and separate Business/Vendor profile presentation under one login.
- Supabase identity linking is used for Google/Facebook; no parallel customer account is created by UI design.
- owner-scoped `client_saved_items` and secured bookmark RPC validate that only discoverable entities can be saved.
- owner-scoped `trusted_people` provides the data foundation for booking services for relatives/family/staff; beneficiary selection is not yet wired into each service flow.
- existing `service_reviews` is extended with title/photo URL/visibility fields; review writes use a secured RPC limited to completed customer bookings; provider rating aggregation remains the existing trigger.
- Track offers Review/Edit review for eligible completed generic service bookings and retains specialised ride/order/event/water shortcuts.
- Wallet remains preview-only but now frames Top up/Scan/Send/Receive, verification, PNG-oriented planned services and future transaction history. No money movement exists.
- retry failures stay in the view rather than escaping callbacks; Events/departures/order/registration/water-trip failures do not masquerade as empty records.
- 31 focused client regressions plus the configuration smoke total 32 app tests; they use in-memory/unconfigured backends and do not replace local account data.
- entry/back navigation coverage includes 11 categories; Taxi map/location/runtime behaviour and the new CX1A surfaces still require live QA.
- do not call CX1 complete from widget/database tests alone; see its evidence document.

## Validation baseline

At this checkpoint:

- all shared Flutter packages: analysis PASS
- Wantok app: analysis + **32 tests PASS** (31 client regressions + configuration smoke)
- required `scripts/flutter/check.ps1`: PASS after clearing read-only attributes on generated test assets only
- Wantok Operations Admin: analysis + smoke test PASS
- Wantok Technical Control: analysis + smoke test PASS
- database: **17 files / 394 pgTAP tests PASS** (all fixtures roll back)
- Android visual QA was last recorded for the earlier client shell; CX1A Account/Services bookmarks/Track reviews/Wallet changes require fresh signed-in client evidence
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

**Finish CX1 — Client Experience Completion Gate**, before **T2.4**.

T2.3 checkpoint: **`46d6208`**; prior CX1 reliability/discovery checkpoint: **`0c33a37`**. Required sequence: **finish CX1A/CX1 evidence → T2.4 diagnostics/logs/jobs**.

CX1 now covers both reliability and the broader consumer layer approved for Wantok Services. The navigation remains **Home · Services · Track · Wallet · Inbox**. Immediate remaining work is beneficiary selection using Trusted people, Save controls on providers/resources/events, managed image upload, recommendation/destination work, and live QA of the new Account/Services/Track/Wallet surfaces. Achievements and social follows remain later within CX1 after the core workflows are stable. See `docs/ROADMAP.md` and `docs/CX1_CLIENT_EXPERIENCE_GATE.md`.

Preserve the local development accounts, roles and data. Do not reset/reseed Supabase or replace working modules/configuration. At resume there are two local auth users/profiles and one local `tech_platform_admin` grant.

T2.4 remains deferred until CX1 passes. CX1 migration `20261006130000_cx1_client_experience_foundations.sql` is already applied locally; do not reset/reseed Supabase to replay it. Integrations and high-risk approvals follow later.

Do not begin Wantok Pay transaction movement until payment-rail and settlement decisions are made.

## Recovery rule

If a future chat loses context:

1. open this repository;
2. read `AGENTS.md`, `docs/HANDOVER.md`, `docs/ROADMAP.md`;
3. run `git status --short --branch` and `git log -5 --oneline`;
4. preserve a dirty tree until its purpose is understood;
5. continue the roadmap rather than reconstructing architecture from memory.
