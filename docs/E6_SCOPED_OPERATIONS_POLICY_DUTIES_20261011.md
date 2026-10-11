# E6A — Scoped Operations Policy Duties (11 October 2026)

**Status:** locally implemented and tested; **E6 as a programme remains OPEN**. Not production-approved; no VM access, vendor activation, KYC approval or identity uploads.

## Preserved project state
Existing Phase 2E immutable policy drafts, revisions, preview, submission, independent review and audit remain intact. Existing Client/Vendor app, Technical Control, API contracts and current user data were not rewritten. No duty grants are automatically created or inferred from `profiles.is_admin` or `user_roles`. Technical administrators do not inherit Operations access.

## Scope schema and authority
- `20261011203000_operations_scoped_policy_rbac.sql`: private staff-duty grants with `staff_user_id`, duty, two-letter country, optional full subdivision, approved service-family scope, expiry, recorded reason, revocation and separate append-only grant/revocation events.
- `20261011203500_operations_scope_clock_alignment.sql`: fixes same-transaction issuance checks (statement time versus transaction start).
- Exactly five duties declared: `policy_author`, `policy_reviewer`, `evidence_officer`, `final_approver`, `safety_investigator`. Only policy author and reviewer are currently authorised for policy-draft actions; other duties are intentionally **non-operative** until their own E6 workflows and contracts are complete.
- `has_operations_scope(duty,country,region,category)` tests the current JWT subject only. A country-wide assignment has a NULL subdivision; a province-bound assignment is **never** treated as all-country. Category `all` in the assignment covers the seven existing Phase 2E policy categories in that country/subdivision, not permissions to publish or activate anything.
- Direct client grants/revocations and recusal records are denied. Provisioning, revocation and recorded conflict-of-interest recusals are `service_role`-only, with reasons and event records. A dedicated independent staff-provisioning/second-approval workflow and control of service credentials is still required.
- Policy drafts and event history use jurisdictional RLS. Phase 2E create, submit, review and revise RPCs enforce the current user's active duty/scope and independent author/reviewer separation. The record-policy-recusal register adds explicit COI denial to review. Proposed notice `internal_review_complete` is not legal or production approval.
- `apps/wantok_admin` offers a **restricted compliance-policy workspace** to non-admin staff with a currently active author/reviewer duty. It does not grant them the full administrator shell. The policy screen obtains the caller's own active grants under RLS, hides unauthorised controls, and retains PostgreSQL as the sole permission authority.

## Compatibility and real-world implications
- Existing admins are **not silently grandfathered into international policy actions**. Until scoped duties are explicitly provisioned to actual accounts by an authorised trusted operator, existing admins will have read-only/no-access policy workflow even while other historical Operations pages remain functional. This intentional fail-closed behaviour requires staffed permission cutover and browser acceptance before rollout.
- Existing legacy `is_admin` reads and mutations in vendor intake, verification, evidence requests, clearance revocation, provider/service review and other Operations modules are **NOT** yet country-scoped; therefore E6 must remain OPEN. The enrolment interface, ISO country/subdivision catalogue and jurisdiction-to-intake-case mapping need explicit design, not a fabricated `region` code from the current free-form field.
- Privileged `service_role` and database superuser can bypass RLS by design; isolate credentials, prohibit browser exposure and audit privileged provisioning. No actual KYC files or identity values should be used for acceptance.
- No live rollout, VM deployment, emulator installation, customer data mutation, identity upload, approval or payment activation was carried out as part of E6A.

## Verification
- Baseline: 49 pgTAP files / 937 assertions PASS.
- E6A: 50 pgTAP files / **973 assertions PASS**, including the new 33-check negative-access suite.
- Operations: static analysis clean, 34 Flutter widget tests PASS including scoped read-only control at 390px and existing 390/900/1440px policy tests.
- Evidence scanner/custody Node regression **101/101 PASS**. Full Flutter check performed 7 analyses and Client/Operations test stages; Technical Control testing hit an existing Windows lock on `apps/wantok_tech/build/unit_test_assets` (no forced delete). The original `ProgramFiles(x86)` variable was absent in the remote process and was corrected **process-locally** for the retry. Run an isolated QA checkout to close the Technical regression without disturbing the active files. Do not infer runtime or security certification from source tests.
- No external signing, restore drill, independent penetration test or signed-in multi-staff browser acceptance yet.

## Dependency-safe next steps
1. Independent approval/provisioning of country duties and revoke/offboarding access.
2. Normalise vendor case jurisdiction and service-family mapping **without altering existing case records**; implement RLS and RPC scopes across procedural review, evidence metadata, safety incident and clearance-status/revocation paths with compatibility tests and redaction.
3. Add strong COI ties to applicant/business, assignment conflicts and named investigator case access; independently review privileged event integrity and service key custody.
4. Signed-in multi-role browser acceptance of policy drafting, reviewing, inaccessible other-country proposals and revocation.
5. After E6, proceed to E7 signed/versioned legally approved privacy notices and purpose consent; keep uploads and clearance issuance disabled until later independent gates.
