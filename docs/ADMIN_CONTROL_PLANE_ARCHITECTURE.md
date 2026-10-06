# Wantok Service — Administration and Technical Control Plane

## Purpose

Wantok Service separates business/marketplace administration from technical platform administration. The two areas may share authentication and audit infrastructure, but they must not be treated as one unrestricted "admin" surface.

## 1. Operations Administration Console

Working name: **Wantok Operations Admin**.

This is the existing web administration application used for operational governance. Typical responsibilities include:

- provider applications and verification;
- listing and resource review;
- booking and marketplace oversight;
- event/vendor governance;
- moderation and safety workflows;
- operational audit review;
- payment/dispute operations when those modules are introduced.

Operations users should only see modules and actions granted to their role.

## 2. Technical Control Panel

Working name: **Wantok Technical Control Panel**.

This is a separate technical administration surface for IT/platform staff. It is not a replacement for the Operations Admin console.

Technical responsibilities include:

- service/module configuration;
- feature and maintenance controls;
- health/status and dependency visibility;
- integration configuration;
- background job and queue visibility;
- logs, diagnostics and technical audit;
- environment/runtime configuration where safe;
- module-specific operational switches;
- technical user and permission administration.

Production secrets must never be exposed as plain text to ordinary technical users.

## 3. Module-first platform model

Every major service is treated as an independently governed module. Initial module keys should include:

- core.identity
- core.account
- core.catalog
- core.messaging
- mobility.taxi
- mobility.water_transport
- hire.vehicle
- hire.boat
- marketplace.specialist
- marketplace.general_labour
- places.venues
- events
- commerce.food
- commerce.grocery
- delivery
- errands
- payments
- notifications
- audit

A module has its own permissions, health state, configuration namespace and technical ownership. A fault or maintenance action in one module should not require granting broad access to unrelated modules.

## 4. Technical access levels

Technical access is permission-based, not a single all-powerful boolean.

Recommended baseline roles:

### Platform Administrator

Highest technical role. Can administer platform-wide technical permissions and cross-module configuration. Reserved for a very small number of trusted staff.

### Technical Administrator

Can administer approved technical modules and perform configuration/diagnostic actions within assigned scope. Does not automatically receive every platform permission.

### Module Administrator

Owns one or more assigned modules. Can configure and diagnose those modules but cannot administer unrelated services.

### Technical Support / Operator

Can view health, diagnostics and perform explicitly allowed support actions. Cannot change high-risk configuration unless separately granted.

### Technical Auditor / Read-only

Read-only access to technical state, configuration summaries and audit history.

## 5. Permission model

Permissions should be explicit capabilities such as:

- module.view
- module.configure
- module.enable
- module.disable
- module.maintenance
- module.diagnostics
- module.logs
- module.jobs
- module.integrations
- module.permissions
- platform.users
- platform.roles
- platform.audit
- platform.settings

A staff member may hold different permissions for different modules.

Example:

    User A:
      mobility.taxi -> view, configure, diagnostics
      core.messaging -> view, diagnostics
      payments -> no access

    User B:
      payments -> view, configure, integrations
      audit -> view
      mobility.taxi -> no access

## 6. UI visibility rule

Backend navigation must be permission-driven. A module is not merely disabled visually; unauthorised routes and backend operations must also be denied server-side.

The Technical Control Panel should build its navigation from the authenticated user's effective permissions. If a user has no permission for a module, that module should not appear.

## 7. Independence and maintainability

Each module should expose a consistent technical contract:

- module identity and version;
- enabled/disabled/maintenance state;
- health summary;
- dependencies;
- configuration schema;
- diagnostics;
- audit events;
- supported technical actions.

This allows modules to be repaired, upgraded or disabled independently while preserving the rest of Wantok Service.

## 8. Separation of authority

Operations approval authority and technical platform authority are separate.

A person may hold both, but access is granted explicitly. Being an Operations Admin must not automatically make someone a Platform Administrator, and being a Technical Administrator must not automatically grant provider/payment approval authority.

## 9. Implementation sequence

1. Keep the existing Operations Admin console functional.
2. Introduce a module registry and module permission schema through migrations.
3. Extend RBAC to support scoped module permissions.
4. Build the Technical Control Panel shell and permission-driven navigation.
5. Add module health/configuration pages incrementally.
6. Add high-risk action approvals and stronger audit where required.
7. Integrate payments only after payment-rail and settlement decisions are finalised.

All changes remain migration-driven, modular and reversible.

## 10. Current implementation — T1 foundation

The first technical-control foundation is implemented as:

- Flutter Web app: `apps/wantok_tech`
- Planned production URL: `https://tech.wantokservices.com`
- Module registry: `public.technical_modules`
- Permission catalogue: `public.technical_permissions`
- Access levels: `public.technical_access_levels`
- Access-level permission templates: `public.technical_access_level_permissions`
- Per-user/per-module assignment: `public.technical_user_module_access`
- Effective permission checks: `has_technical_permission`, `has_platform_permission`
- Permission-driven module listing: `list_my_technical_modules`
- Audited module enable/disable/maintenance: `set_technical_module_state`
- Delegated lower module access: `grant_technical_module_access` / `revoke_technical_module_access`

Operations `admin` authority cannot grant `tech_*` roles. Technical Platform Administrator authority cannot automatically grant Operations roles. This separation is enforced server-side.

T1 intentionally does not expose production secrets, generic shell/SQL access, or arbitrary remote execution. Module-specific configuration schemas, health adapters, logs, queues/jobs and integration adapters belong to T2.

## 11. T2.1 — Technical staff and module-access management

T2.1 adds controlled staff administration on top of the T1 permission model.

Implemented:

- Technical Control navigation entry: **Technical access**
- module selector limited to modules where the actor has `module.permissions`
- controlled account search by name/email through a SECURITY DEFINER RPC
- minimum two-character account search to avoid unrestricted directory dumping
- current module staff listing with grantor and access-note metadata
- assign/change/revoke module access through secured RPCs
- access-level choices automatically limited below the actor's own authority
- Module Administrator/Support/Auditor staff cannot open access management
- Operations Administrators cannot use the Technical staff directory
- global Technical Platform Administrators are marked separately and do not receive redundant module assignments
- peer/higher assignments are protected from modification or revocation by lower/equal module administrators
- all mutations continue through the existing technical audit path

T2.1 intentionally does **not** provide UI for casually granting or revoking Technical Platform Administrator status. That remains a critical platform-level action for later high-risk approval/hardening work.

## 12. T2.2 — Typed module configuration

T2.2 replaces generic configuration editing with versioned, typed module schemas.

Implemented:

- versioned schema registry per technical module;
- typed field definitions for strings, integers, decimals, booleans, enums, URLs, string lists, durations and secret references;
- grouped labels, help text, required/advanced flags, defaults and validation metadata;
- override storage separate from schema defaults;
- server-side validation for every write;
- `module.view` read-only configuration inspection;
- `module.configure` required for changes;
- batched configuration updates with schema-version checks;
- reset-to-default by removing an override;
- audited before/after configuration changes;
- secret-reference fields that accept identifiers such as `env://...` or `vault://...`, never secret values;
- secret-reference identifiers are redacted from audit metadata;
- typed Technical Control editor with permission-aware read-only/edit modes.

Initial active schemas cover Taxi, Water Transport, Messaging, Food, Groceries, Delivery and Notifications. Wantok Pay remains behind its separate payment-rail and settlement design gate.

The public Wantok home screen was also refreshed during T2.2 with richer category-specific service visuals. The icons remain lightweight Flutter-rendered assets rather than downloaded artwork, preserving performance and Wantok's own visual identity.
