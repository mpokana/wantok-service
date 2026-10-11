# E6C — Clearance and Safety Boundary Review

**Date:** 11 October 2026
**Target:** EAGLT02 local source only, `feature/flutter-platform-v1`
**State:** Source review completed. **No E6C migration or runtime change applied.** E6 remains OPEN.

## Verified source-level gaps

The current clearance interfaces predate E6A/B scoped duty grants:

1. `supabase/migrations/20261011191000_vendor_clearance_operations_read.sql` defines `list_vendor_clearance_status()` with `is_admin(auth.uid())`; once that gate passes, it selects up to 200 clearance records without a case-country/province/category restriction.
2. `supabase/migrations/20261011190500_vendor_clearance_revocation.sql` defines `revoke_vendor_activation_clearance(provider_id, reason)` with a broad admin flag, then revokes the provider's clearance, pauses active services and appends an audit event. The atomic pause is desirable but the actor is not checked against a verified case scope.
3. `vendor_clearance_revocation_events` has a legacy global-admin read policy.
4. The same migration defines `admin_set_provider_service_status` with broad admin access. A new `active` transition checks for existing unexpired/unrevoked independent clearance, but it does **not** establish country-scoped staff authority, case-to-provider identity match or current E7–E9 release approval.
5. `supabase/migrations/20261011150000_vendor_enterprise_intake.sql` defines `review_provider_application` as a broad-admin `approved/rejected` decision. Although the function deliberately does not grant driver/provider roles, its decision is not E6 scoped.
6. `vendor_activation_clearances` contains `provider_id` and `evidence_case_id`, but their existing columns/constraints do **not** require the evidence case's applicant to equal the provider being cleared. A future read/revocation scope must validate this relationship, not trust a case ID alone.
7. `pause_expired_vendor_clearances()` is already service-role-only and should remain functional for safety even if no scoped staff duty has been provisioned.
8. The Operations `VendorClearanceStatusPage` currently calls the broad admin-status and revocation RPCs. Merely hiding its emergency button does not establish authorisation.

These are **source findings**, not verified production exploit claims or evidence that the online VM has the same uninstalled migrations.

## Design required before migration

- Reuse existing verified case country, region and service-family mapping, enabled subdivision registry, and caller-specific active `operations_duty_grants`. Add `safety_investigator` to the case-scope decision for this explicitly defined purpose only.
- Bind the clearance's `evidence_case_id` to its actual `provider_id` through the `vendor_intake_cases.applicant_id` relationship. For a status query, return **only** that user's scoped, validated clearance rows; never return all and filter in Flutter.
- Require an independent safety investigator for staff-driven emergency revocation. Enforce explicit recusal from one's own clearance/review and record reason, identity, event and paused-service count atomically.
- Make a distinct **trusted server-only emergency stop** available for urgent unclassified historical clearances. It must not be callable through an authenticated browser or inherit global-admin privilege. It needs controlled operator identity, verified incident reason and audit; preserve existing service-role expiry maintenance.
- Seal new service activation and legacy provider accept/reject paths until the independent E9 approval gate; do not enable payments, onboarding clearance issuance, Storage/ID evidence or live services.
- Separate staff workspace visibility by the safety duty, but enforce all access at the database function and RLS layer. No staff role receives Technical Control access.
- Do not backfill `region` text into country subdivision codes, auto-grant worldwide scopes or modify existing production clearances for convenience.

## Regression acceptance before a commit or release

- Keep 044/045 pgTAP fixtures synthetic and transaction-rolled-back. Modify them for explicit classified cases and safety investigator grants.
- Negative checks: administrator without safety duty; wrong country/province/category; inactive/expired/revoked duty; case without trusted mapping; foreign evidence case/provider; reviewer or clearance approver attempting a self-conflicted stop; applicant/anonymous caller; unavailable or revoked clearance.
- Positive checks: in-scope independent investigator lists only their rows; revocation pauses all applicable active services with one audit event; repeated action does not double-count; service-only expired-clearance maintenance remains callable and browser-denied; service-only emergency path is auditable and not browser callable.
- Check `admin_set_provider_service_status` cannot newly activate services before signed E9 release. Test that legacy `review_provider_application` cannot confer provider or driver access.
- Run local additive `db:migrate`, full `db:test`, `test:evidence`, seven Flutter analyses and full Client/Operations/Technical widget suites from a clean detached checkout; then create Git commit, fast-forward push and checksum-verified source archive. Do not access or deploy to any online VM.

## This session's execution boundary

EAGLT02 was online; its source at the start of the session had only unrelated untracked `supabase/snippets/`, and E6B/CX1 were already committed. Attempts to create the proposed E6C security migration were rejected by the remote tool's safety checks before file creation. No migration was applied or tests represented as rerun. This document records the blocker and precise safe next implementation path; it **does not** complete E6C or authorize production rollout.
