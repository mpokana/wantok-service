# E6D–E6F: Staff Provisioning, Legacy Staged Intake & Conflict Separation

**Date:** 11 October 2026
**Development target:** EAGLT02 only, `feature/flutter-platform-v1`
**Current status:** Source implementation and local security regression PASS. **E6 formal acceptance remains OPEN** until authorised staff, location-source and signed-in client/browser gates are evidenced. No production VM, live evidence, real staff provisioning, final KYC or provider activation.

## E6D — Two-person country-scoped staff duty changes

Migration `20261011230000_operations_dual_control_provisioning.sql` introduces `operations_provisioning_authorities`, `operations_duty_change_requests`, `operations_duty_change_events`. Trusted `service_role` exclusively bootstraps individually verified authority with country, approver/operator ID and provenance. Requester and approver authorisations do not inherit from `is_admin` and must remain current.

Authenticated `request_operations_duty_change` verifies the proposer (not target) is country-authorised, exact duty, category, checked subdivision, explicit reason, and grant expiry within 366 days. Grants are *not* effective while pending. `decide_operations_duty_change` locks the pending request, verifies a *different* currently authorised approver who is not the subject, and atomically inserts/revokes the duty plus immutable audit. Rejected requests grant nothing; expired, revoked or duplicate privileges are refused. Existing service-role-only `provision_operations_duty` remains the privileged trusted maintenance path; independent human approval of that backend use and credential custody must be documented before operating live.

Operations `Staff Duty Authorisation` page is reachable through a restricted duty-provisioning tab for authorised nonadmins and via the existing administrator header. It reads only RLS-permitted countries, shows pending requests and allows independent approval with mandatory explanation. An administrator without separately provisioned authority cannot approve. No server key is sent to Flutter.

## E6E — Separate legacy staged case jurisdiction

Migration `20261011231000_operations_staged_case_scope.sql` adds `operations_staged_jurisdictions`, correction events, trusted-service-only `classify_operations_staged_application` and caller-specific `has_operations_staged_scope`. Never automatically convert free-text `coverage_province` to ISO. Classification must correspond to explicit `coverage_country_code`, approved and enabled region, canonical category map and operator review. There is **no automatic production backfill**.

Replace old staged-app, checklist, checklist-audit, evidence-planning/audit and non-uploading intent RLS broad-admin visibility with applicant-owned read or active independently scoped case/evidence duty. Staged triage/progress require `case_reviewer`; evidence planning and cancellation require `evidence_officer`. Applicants cannot review themselves even with a test duty. A restricted Operations **Staged cases** tab is now visible to scoped reviewers/evidence officers, with case review buttons and evidence planning controls separately hidden unless the corresponding duty is present. Metadata-only intent ownership and withdrawal persist; Storage object access remains sealed. Legacy resource-status moderation RPC is denied pending an independently accepted activation path.

## E6F — Immutable case-specific conflict exclusions

Migration `20261011232000_operations_case_recusals.sql` adds `operations_case_recusals` for enterprise and staged applications, with immutable reason, identity and recorder. Staff may disclose their own conflicts only if currently scoped; independently verified service-role operators may register an identified third-party conflict without allowing browser impersonation. Both `has_operations_case_scope` and `has_operations_staged_scope` deny *all* staff duties for the recorded case immediately, overriding active geographical grants, without affecting the applicant's own read or unrelated case assignments. No unsafe free-text inference of familial/commercial relationships.

## Direct activation and legacy route audit

The original `20261005002000_marketplace_core.sql` already uses column-level `INSERT/UPDATE` grants, denying browser updates to `provider_profiles.verification_status/is_active` and `provider_services/provider_resources.status` despite broad owner RLS. `profiles` restricts browser updates of `is_admin/is_provider/is_driver/is_driver_approved`. New SQL regression 055 explicitly tests these ACLs and actual denial. The E6C legacy service-status, resource-status and provider decision RPCs are sealed; unrestricted browser activation is not granted by these paths.

Review of original water transport and booking paths identified existing authenticated owner permissions for already-approved providers. The current E6 security programme deliberately preserves working owner scheduling/status transitions; comprehensive country legal and production service eligibility assessment remain release gates, not assumptions that every legacy route is suitable for international activation.

## Local validation and evidence

- `npm.cmd run db:migrate`: 20261011230000, 20261011231000, 20261011232000 applied to local Supabase without reset.
- `npm.cmd run db:test`: **56 SQL files, 1,139 pgTAP assertions PASS**, including new 053 (30), 054 (29), 055 (19), 056 (18). Existing 030–035/047 synthetic fixtures adjusted to explicit rollback-only jurisdiction and duties; no production records seeded.
- `npm.cmd run test:evidence`: **101/101 PASS**; evidence uploads remain disabled.
- New scoped Operations UI has five focused widget tests including unauthorised, country-scoped requester and separate approver states. The first run found and corrected dialog overflow/controller lifecycle issues; rerun **5/5 PASS**.
- Integrated Flutter analyses, complete widget regression, exact commit, GitHub fast-forward and checksum-verified source package are recorded separately once verified.

## E6 formal closure conditions still requiring human/real-world acceptance

1. **Identity and authority:** separately approved, official staff delegation evidence and service-key custody, independent source review and dual human sign-off for initial bootstrapping and emergency actions. No real authorisers provisioned by this coding checkpoint.
2. **Jurisdiction evidence:** official ISO 3166-1/3166-2 and category mapping source/provenance verified by regional compliance officers; no unreviewed country-wide grants. Test fixtures are synthetic, *not* legal attestation.
3. **Conflicts:** actual staff attestations and independent investigation of related-party/beneficial ownership and corporate links. The implemented manual recusal register enforces declared conflicts, it cannot discover undeclared conflicts.
4. **Acceptance:** signed-in, separate real/test accounts for country, province, category, applicant, case officer, evidence officer, investigator, requester and independent approver in controlled browser/device sessions, UI permissions and revocation after navigation; security test review, approved recovery and audit runbooks.
5. **Boundary:** final KYC, evidence intake/consent, regulated approvals, activation, payments, Helpdesk and live VM release are separately gated in E7–E12. Do not enable them to mark E6 complete.

Reference `docs/HANDOVER.md`, `docs/ROADMAP.md`, `docs/ENTERPRISE_RELEASE_READINESS_GATES.md`. Distinguish **E6 source work completed** from **E6 acceptance signed off**.
