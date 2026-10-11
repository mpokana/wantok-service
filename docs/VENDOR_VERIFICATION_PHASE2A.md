# Wantok Operations — Vendor Verification Phase 2A
Date: 11 October 2026 (PNG)

## Current scope
Phase 2A adds **operational verification task management**, not proof of
document authenticity, approval, KYC certification or service activation.

The new tasks are automatically generated when an individual or registered
business applies. Baseline checks cover identity/contact details, physical
address and category eligibility. Business applications also receive company
registration and tax/ownership checks. Vehicle categories receive registration,
licence-class and insurance checks; food receives hygiene checks; equipment hire
receives inspection/ownership checks; other services receive professional scope
checks. Papua New Guinea gets an additional PNG authority review task; other
countries get an explicit country-policy-needed task. These are preliminary
work items, **not authoritative legal requirements by jurisdiction**.

Existing cases are backfilled without altering approval states.

## Where staff work
- Wantok Operations at http://127.0.0.1:3200
- Providers → Applications & Review → select case → Verification review tasks
- Or Verification & KYC → Vendor applications & two-person review tasks
- Applicants continue using the client application at http://127.0.0.1:3000

## Review process
1. Reviewer starts the case via Applications & Review. Existing audit trail
   assigns the officer to the case.
2. The assigned officer may start, flag follow-up, and record the **first
   procedural review** of individual checklist tasks. Rationale is mandatory.
3. A **different authorised administrator** must record the second procedural
   review. The database enforces separation, even if UI controls are bypassed.
4. The review trail records the actor, timestamps, old/new state and rationale.
   Operations can inspect the trail per case.
5. No task can be changed after independent second review. No process here
   sets identity status to verified, issues activation clearance, publishes
   a listing, creates a driver permission, or authorises payouts.

## Security boundaries
- The existing evidence vault remains sealed. No applicant file upload or
  reviewer document-reading permissions are introduced.
- New task and event tables are read-only to authorised Operations admins.
  Mutation is confined to a permission-checked, audited database function.
- Applicants, anonymous users, and other vendor accounts cannot read the
  internal verification task or event tables.
- The separate vendor_activation_clearances table continues to have no
  authenticated user INSERT/UPDATE grant, no approval RPC, and no public policy.
- All changes were applied to **EAGLT02 local Supabase only**, not production.
- Local snapshots are not external identity checks or independent attestation
  that evidence documents exist. This module must not be advertised as
  completed KYC.

## Outstanding work before real approval/activation
1. Secure collection of full ID/NID, business registration, licences and
   insurance: explicit country-specific notice/consent; encrypted isolated
   upload gateway; malware scanning; private quarantined storage; strict
   key custody and access logging; retention/deletion rules.
2. Country-specific policy authoring, legal review and effective-date controls;
   verify all authoritative licence/registration sources.
3. Formal evidence reconciliation, confidence and exception workflows,
   supervisor/Compliance authorisation and re-verification schedules.
4. Secure backend-only final clearance issuance, revocation and expiry
   enforcement, independent issuer/approver attribution, and external audit.
5. End-to-end real-user signed-in acceptance tests; financial-service
   licensing and payments remain separately disabled.
6. A distinct Helpdesk ticketing and escalation workspace with service-level
   management, after trust controls are stable.

## Verification
- Database migrations: 20261011180000 and 20261011180500.
- PGTap regression: 042_vendor_independent_review.test.sql,
  validates permissions and independent two-person enforcement.
- Flutter widget regression: vendor_verification_review_test.dart at
  390px, 900px and 1440px.
