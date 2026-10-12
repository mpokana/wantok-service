# E6P — Privileged Role/Platform Control Denials and G7 Witness Plan

**Checkpoint:** 12 October 2026 (PNG) | **Repository:** Wantok Services feature/flutter-platform-v1 | **Device:** authorised EAGLT02 | **Deployment:** NONE; isolated SQL and documentation only. E6 engineering P0 active; **G1–G10 formally BLOCKED**.

## 1. Scope and objective

E6O's read-only local PostgreSQL `pg_catalog` inventory enumerated **152** `public` SECURITY DEFINER functions, **95** anonymously executable and **133** authenticated executable; all are owned locally by a role with `BYPASSRLS`. These are *effective EXECUTE privileges*, not proof of unauthorised changes. The previous E6O internal-helper finding (`write_audit_event`, `enqueue_notification`) remains OPEN and its source-only grant correction **unapplied** in the persistent database. A separate Technical health-report helper was also flagged; T2.4 remains paused.

E6P specifically verifies direct anonymous SQL calls against **nine selected privileged controls** on the latest applied source, without granting privileged roles, publishing anything or touching the existing shared data:

| Control (SQL RPC) | Latest observed source-level guard | Expected denied action |
| --- | --- | --- |
| `grant_user_role` | `auth.uid()` non-null; Technical role branch checks `is_technical_platform_admin`, Operations role branch checks `is_admin` | Cannot self-assign Technical/platform or Operations staff |
| `revoke_user_role` | `auth.uid()` non-null; differentiated role-family administrator check and last-technical-admin protection | Cannot strip others' roles |
| `grant_technical_module_access` | `auth.uid()` non-null, scoped rank/peer protection, module permissions | Cannot issue Technical access grants |
| `revoke_technical_module_access` | `auth.uid()` non-null and scoped permission checks | Cannot revoke Technical access |
| `set_technical_module_state` | `auth.uid()` non-null and Technical module enable/disable/maintenance checks | Cannot change module state |
| `publish_wantok_branding_draft` | `auth.uid()` non-null and `is_technical_platform_admin` | Cannot publish platform branding |
| `restore_wantok_branding_version` | `auth.uid()` non-null and `is_technical_platform_admin` | Cannot restore a branding version |
| `admin_set_public_services_enabled` | `auth.uid()` non-null and `is_admin` | Cannot toggle Public Services visibility |
| `manage_service_category` | `auth.uid()` non-null and `is_technical_platform_admin`; later field/activation restrictions | Cannot create/update/archive service categories |

These observed checks come from checked-in migration SQL and must be assessed for effective role/privilege equivalence and proper escalation prevention. They are **not** independent attestations or proof of every positive-path outcome.

## 2. New reversible technical acceptance tests

Added `supabase/tests/062_privileged_role_control_anon_denials.test.sql` (**23/23 pgTAP**): verifies four selected objects are SECURITY DEFINER, nine actual anonymous direct SQL calls fail with their existing `Authentication required` / administrative errors, five `authenticated` database-role calls with **NULL `auth.uid()`** also fail closed, and five synthetic stage tables remain empty of roles, Technical grants, branding history, audit events and notification outbox.

**Important qualification:** `SET LOCAL ROLE authenticated` in the test is **not** a real signed-in GoTrue human account. The test uses neither user credentials nor positive staff delegation. It cannot prove a logged-in user with a weak or malicious role is correctly denied, or that a duly authorised user succeeds. G7's genuine-role positive/negative and JWT expiry/revocation matrix remains blocked.

Current network-disabled disposable integration harness now applies seven source-only pending SQL migrations to a temporary database; **12 pgTAP files / 243/243 assertions PASS**, including E6H case independence, E6K marketplace metadata, E6N function path and E6O shared internal helper restrictions. All synthetic writes rollback, the disposable container is removed, and checks confirm the shared local Supabase database is unchanged.

**No new E6P schema migration:** The E6P checks confirmed expected anonymous denial on these **selected nine** functions. We did not blanket-revoke their `anon` EXECUTE grants because some caller contracts may rely on the exposed RPC schema and because broader PostgreSQL/RLS/REST call graph is still under review. E6O's proposed two-helper correction remains its own pending migration. No Technical module code or grants were changed.

### Exact E6P regression evidence

- Fresh E6P `062` negative SQL suite **23/23 PASS** (nine anonymous direct-call denials, five `authenticated` DB-role NULL-session denials, four selected function properties, five no-side-effect checks).
- Disconnected seven-migration compatibility stage **243/243 PASS** across **12 pgTAP files**, all fixtures rolled back, original shared Supabase database unchanged, disposable PostgreSQL container removed. T2.4 migrations included **only** for cross-stream compatibility.
- E6J/E6L/E6O read-only local security snapshot: **152** public definer functions, **95** anonymously EXECUTE-granted; no real data rows accessed or database mutations. E6O internal shared writer grant discrepancy remains **OPEN**.
- Unchanged main's signed synthetic JWT loopback HTTP negatives **23/23 PASS**; E6 independent case review **106/106 PASS**; evidence scanner **101/101 PASS**. None are genuine witnessed GoTrue logins.
- Fresh E6P detached-source `scripts/flutter/check.ps1` exit **0**, **7 Flutter static analyses clean**, **132/132 Client, 43/43 Operations, 38/38 Technical** widget tests PASS. No Flutter app code changed.
- Full persistent combined SQL suite **not claimed as run/passed** because seven source migrations remain unapplied; stage owner/ACL parity and HR/legal/security witness absent.

## 3. G1–G10 acceptance work continues alongside source verification

`docs/E6G_FORMAL_ACCEPTANCE_RUNBOOK_20261011.md` is authoritative. The operational register `docs/E6G_PARALLEL_ACCEPTANCE_REGISTER_20261012.md` now includes **G7-19 through G7-23** alongside the 18 existing cases (**23 total**). This extends independently witnessed stage acceptance to ordinary authenticated role escalation, segregated positive role grants, Technical module guard channels, branding/category controls and E6O trusted helper REST boundaries.

- **G1 HR / G2 separation / G3 custody:** real employment delegation, two distinct decision-makers and service-key custody remain unsupplied.
- **G4 maintained geography / G5 legal service map / G6 COI:** authoritative dated legal/ISO sources, regulated-service classification and independently checked related-party declarations remain unsupplied.
- **G7 real GoTrue/PostgREST:** 23 case IDs are **PLANNED** and none has been executed with independently authorised accounts and witness; positive role-grant and category-editor paths require separate approved staging and reversible cleanup.
- **G8 independent application security:** validate all 152 local public privileged routines (including call graph, triggers versus public RPC, owner/ACL parity, `pg_temp`, service-role/writer channels, current field privacy), verify E6O-01 mitigation under permitted staging, separately decide Technical E6O-02 while T2.4 paused. The selected nine E6P negatives are only a narrow engineering aid.
- **G9 backup and recovery / G10 release:** restore, revocation, break-glass, offboarding and final independent security/product signatures remain pending; cannot be self-attested.

**Acceptance status:** E-series source/isolated QA **PASS** for this limited checkpoint; external G1–G10 **0/10 approved** and production `productionApproved:false`.

## 4. Next recommended safe step

Perform scoped **read-only inventory of callable platform role getters and policy helpers** plus **source-only** cross-role role-grant trace; broaden negative synthetic tests where concrete gaps are found, without creating real users or modifying the shared database. Obtain separately approved, backed-up exact-ACL staging with independent reviewers for real GoTrue positive and negative authorisation. If a function is shown unsafe, document a minimal reviewed migration and rollback and test only in disposable SQL first.

Programme remains **E-series ACTIVE + G-series preparation PARALLEL; CX1 QUEUED; T2.4 PAUSED; E7+/production SEALED**.
