# E6Q — Role-Helper Cross-Principal Boundaries and G1–G10 Preparation

**Checkpoint:** 12 October 2026, PNG | Authorised EAGLT02 / `feature/flutter-platform-v1` | **Disposition: local synthetic SQL QA PASS, G7 real-session acceptance and G8 independent security BLOCKED.** No shared database, deployment, real user, key, provider record or Technical module change.

## Source and metadata inspection

Previous E6O local PostgreSQL catalog: **152** `public` SECURITY DEFINER functions; **95** EXECUTE-granted to `anon`, **133** to `authenticated`. This count is the **currently applied local database**, not a production inventory, and EXECUTE rights alone do not confer privileged mutations. E6O's privileged `write_audit_event` / `enqueue_notification` grant discrepancy remains OPEN in persistent local Supabase, with a separately staged source-only correction in `20261012152000`. No change is made to this pending migration.

Reviewed latest checked-in helper definitions:

| Helper | Source logic / boundary | Review note |
| --- | --- | --- |
| `public.has_role(role,user_id)` | Consults `public.user_roles` for matching active role/expiry, owner-privileged | Caller can supply *another* user ID; returns **subject's** RBAC fact, not proof that caller has role |
| `public.is_admin(user_id)` | Delegates to `has_role('admin',user_id)` in RBAC authority migration | Legacy `profiles.is_admin` alone is no longer authoritative |
| `public.is_technical_platform_admin(user_id)` | Delegates to `has_role('tech_platform_admin',user_id)` | Technical platform authority remains distinct from Operations admin |
| `public.has_platform_permission` / `has_technical_permission` | Evaluate platform/module grants for a **supplied** subject ID | Must not substitute for caller checks without binding `auth.uid()` in consuming RPC |
| `public.effective_technical_access_level` / `can_access_technical_console` / `can_manage_technical_module_access` | Calculate supplied subject's Technical access | Caller-supplied ID can reveal others' access state; G8 privacy contract required |
| `public.grant_user_role` / `revoke_user_role` | Explicit `auth.uid()` caller guard followed by distinct Technical-vs-Operations authority checks | Synthetic distinct principal and cross-role tests now included |

**E6Q G8-04 candidate disclosure:** These read-only helpers accept `p_user_id`; the disposable SQL run shows an ordinary role can retrieve another synthetic person's Operations role, Technical platform role and technical-console entitlement by passing that person's UUID. This is **role metadata visibility**, not impersonation or privilege elevation. Whether visibility is acceptable, and which helpers are reachable via PostgREST, require an explicit privacy/security contract and independent G8 review. Some internal function calls legitimately check other users; **do not blindly remove parameters or revoke grants** without call-graph/compatibility analysis.

## Synthetic authorisation in disconnected PostgreSQL

New `supabase/tests/063_role_helper_cross_principal_boundary.test.sql` has **25/25** pgTAP assertions. Four fake `auth.users` rows inside a `BEGIN ... ROLLBACK` transaction represent Operations admin, Technical platform admin, ordinary user and target. All use reserved, non-real `example.test` addresses. `SET LOCAL ROLE authenticated` and JWT GUC values supply synthetic caller IDs, **not GoTrue-verified tokens**.

- Operations admin and Technical platform admin are distinct roles; neither alone makes its bearer the other type of administrator.
- Ordinary synthetic actor receives false for *its own* admin/Technical access but can query another test person's role/helper metadata through explicit target ID.
- Ordinary actor cannot grant/revoke admin/Technical roles. Operations-only actor can grant a permitted support role but cannot grant/revoke Technical platform-admin authority. Technical-only actor can grant permitted Technical support but cannot grant/revoke Operations admin authority.
- The target never gains global Operations or Technical platform-admin role. Test-only positive support grants are rolled back.
- **No E6Q schema migration:** live grants, SQL function bodies, Technical code and public RLS remain unchanged.

Full isolated `scripts/qa/e6-crossstream-isolated-staging.ps1`: seven pending source migrations, **13 SQL test files / 268/268 pgTAP assertions**, with new 063 **25/25**. All synthetic fixtures rolled back, network-disconnected container removed and shared Supabase unchanged. Four T2.4 source migrations remain compatibility fixtures only; T2.4 paused. Stage uses `--no-owner --no-acl` plus recreated limited grants: **not** production ACL/owner parity. Unapplied E6N/E6O hardening sources were applied **only** in disposable testing.

## Checkpoint regression scorecard

- Fresh E6Q synthetic cross-principal test `063`: **25/25 PASS**, with four disposable fake identities and role grants inside rollback transaction.
- Seven-migration disconnected PostgreSQL compatibility: **13 test files / 268/268 pgTAP PASS**; fixture writes reverted, no persistent Supabase migration/row change, disconnected container removed.
- Unchanged main local synthetic-JWT HTTP negative tests **23/23 PASS**; E6 independent-case tests **106/106 PASS**; evidence scanner **101/101 PASS**; read-only entire public definer catalog still records **152 functions / 95 anon-callable**. These are **not** real signed-in GoTrue witness sessions.
- Fresh E6Q detached `scripts/flutter/check.ps1` exit **0**, seven separate Flutter packages/apps analyzed with no issues, **Client 132/132**, **Operations 43/43**, **Technical 38/38** widget tests PASS. No Flutter source changed.
- The combined SQL suite on the persistent shared database is intentionally **not declared passed** while seven pending source migrations remain unapplied. **G1–G10 remain blocked; production not approved**.

## G1–G10 acceptance preparation in parallel

The controlling human acceptance requirements remain `docs/E6G_FORMAL_ACCEPTANCE_RUNBOOK_20261011.md`; the workboard is `docs/E6G_PARALLEL_ACCEPTANCE_REGISTER_20261012.md`.

- **G1–G3:** staff delegation, independent two-person duty approval, trusted bootstrap/provenance and custody all **NOT SUPPLIED/BLOCKED**.
- **G4–G6:** dated geographic/legal categories and independent related-party/COI witness **NOT SUPPLIED/BLOCKED**.
- **G7:** expanded from **23 to 26** planned cases. New G7-24: real signed-in cross-subject role-helper privacy; G7-25: separate delegated actor cross-role boundaries; G7-26: expired/revoked and legacy role flags with real GoTrue sessions. **0/26 independently witnessed or executed**.
- **G8:** independent reviewer to determine cross-person role-metadata privacy contract; audit relevant 152-function surfaces, direct RPC accessibility and exact role/ACL parity. Prior E6O audit/notification and Technical health helper findings remain OPEN.
- **G9–G10:** witnessed backup/restore/offboarding and signed go/no-go remain BLOCKED.
- All formal gates **0/10 PASS**. No human witness, credential, approval or attestation was fabricated.

## Next safe actions

Continue a scoped **read-only SQL reference/call-graph map** for helpers accepting arbitrary `p_user_id`, plus a role-metadata API exposure/privacy contract for independent G8 decision. Real JWT-verified positive and negative tests require **separately approved, backed-up, role-parity stage** and actual independent witnesses. No persistent migration, real user provisioning, provider activation, payments or production deployment until appropriately authorised.

**Programme:** P0 E-series ACTIVE / G1–G10 preparation PARALLEL; P1 CX1 queued; P2 T2.4 paused; E7+/production sealed.
