# E6B — Verified Case Jurisdiction, Preliminary Review and Evidence Duties
11 October 2026 | EAGLT02 | Local-development checkpoint | **E6 remains OPEN**

## Implemented
- Add **case_reviewer** as a sixth explicit Operations duty. A signed-in case reviewer may perform audited preliminary triage and two-person procedural verification; an **evidence_officer** may request or cancel **metadata-only** evidence. Neither becomes an administrator, identity certifier or final approver.
- `20261011210000_operations_case_jurisdiction_and_review.sql`: service-role-only mappings of actual `service_categories.id` to the six finite service-family scopes; a separate trusted classification for each `vendor_intake_cases.id` with source country, region code and category mapping, operator ID, reason, timestamp and classification event. Existing free-text `vendor_intake_cases.region` remains unaltered. No automatic backfill, guessed province or implicit country-wide access.
- `20261011211000_operations_approved_subdivision_registry.sql`: independent register of verified ISO-like subdivisions; disabled/unregistered code fails closed. **ISO pattern alone is insufficient**. The `service_role` operator must validate the ISO 3166-2 code against an authorised country source and recorded case evidence before classification. No real countries/regions were enrolled during this checkpoint; synthetic test transaction records roll back.
- `has_operations_case_scope(duty,case_id)` binds to the caller's JWT, tests classification, trusted category mapping and active enabled region before testing the issued country/subdivision/category grant. Category-map changes invalidate existing case classification until independently re-certified. Revoked and expired grants fail closed.
- Replace RLS policy broad-admin reads across enterprise intake cases/events, internal verification checks/events and evidence-request metadata/events. Only applicants read their own case and request information; they cannot inspect internal checklist; appropriately scoped reviewers/officers see only their registered cases. Non-scoped legacy admins see nothing through these specific enterprise views.
- Preserve procedural review state machine and original two-person separation, but enforce case_reviewer scoped duty and prevent reviewers modifying another person's assigned case. Evidence request/cancel RPCs require evidence_officer scope; no file upload, Storage access, final clearance or provider activation.
- Operations app: a scoped non-admin staff member with policy, case or evidence duties can enter the isolated workspace; only authorised tabs are shown. Case-review, checklist and metadata-request action buttons are hidden when the displayed duty is missing; **PostgreSQL remains authoritative**. No full administrator shell privilege is granted. Existing admin uses the original shell and must receive explicit case duties to see newly protected cases.
- Fixed existing Flutter intake queue lifecycle bug: its `setState` callback improperly returned a Future; checked by the new real widget test.

## Verified
- Local migration up: PASS, additive only, no database reset.
- All existing tests preserved and updated with explicit synthetic classification and grants in SQL fixtures 042, 043 and 046.
- SQL regression: **51 files, 1,008 pgTAP assertions PASS**; new 051 includes **35 negative/positive tests**, covering unmapped denial, global admin denial, out-of-province, wrong category, applicant isolation, evidence officer boundary, reclassification, mapping change, region disabling and grant revocation.
- Operations static analysis clean and complete Operations suite **37/37 widget tests PASS**, including three scoped-role visibility tests and the intake lifecycle regression. Full cross-app regression must be recorded at final packaging.
- No online VM, remote server, production data, identity records, customer evidence, services activation or real role-grant provisioning touched.

## Critical remaining E6 dependencies (do not claim E6 complete)
1. `vendor_activation_clearances`, `revoke_vendor_activation_clearance`, `list_vendor_clearance_status`, `admin_set_provider_service_status`, legacy `review_provider_application` and other broad-admin provider pathways need independent case-category and safety investigation scope with emergency break-glass safeguards.
2. Service-role classification is a deliberate trusted-maintenance boundary, **not** an approved business UI. Add independent staff provisioning, second-approver checks, government subdivision source provenance, redacted audits, category mapping revision history and offboarding; prohibit exposing service keys to Flutter.
3. Bind conflicts of interest to applicant/business and named reviewer/investigator, enforce two-person process on all decision paths, perform browser signed-in multi-role and cross-country isolation checks.
4. Separate older staged provider evidence/verification routes still use legacy admin policy. Reconcile carefully without accidentally opening real identity storage or approving providers.
5. The original E7–E12 legal, security, payments, operations, availability and deployment gates remain unchanged. **No live migration or release approved**.

See `docs/E6_SCOPED_OPERATIONS_POLICY_DUTIES_20261011.md` and the living `HANDOVER.md`, `ROADMAP.md`.
