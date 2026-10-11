# Wantok Services – Phase 2B local security controls

Date: 11 October 2026. Applies to **EAGLT02 local development only**.

## New working capability
- Operations → Verification & KYC → vendor applications & two-person review
  → select case → Verification review tasks → Evidence request register.
- Staff can create a **metadata-only evidence requirement** against an
  existing verification check with a recorded rationale. A request lasts
  14 days; duplicate open requests are rejected. Cancellation requires a
  recorded reason. Expired/withdrawn requests cannot be acknowledged.
- Client → Become a Wantok vendor → shield icon → My evidence requirements.
  The applicant can view only their own requests, acknowledge receipt or
  withdraw. These actions are audited with actor and timestamp. They do
  **not** mean consent to submit/upload private documents.
- Operations → Verification & KYC → Clearance monitoring & emergency
  revocation. Authorised Operations administrators can see limited status
  information about pre-existing clearances, and may revoke an existing
  clearance. Revocation pauses all active listings of the affected provider
  in the same database transaction and writes an audit event.
- Service reactivation requires an unexpired, non-revoked clearance.
  An expiry-maintenance function can pause listings after expiry, but is
  **service-role-only and not yet scheduled**.
- All three Operations entry points have phone/tablet/desktop layouts.
- Production tables, applications and existing active services were not
  bulk migrated or reclassified.

## Deliberate security boundaries
- **No applicant document upload, signed URLs, file read, public Storage
  policy, third-party document verification or identity certification.**
- The evidence notice version is explicitly a **DRAFT** technical marker,
  not a legally approved privacy notice or informed consent.
- Neither acknowledging a request nor completing two preliminary staff
  reviews permits activation. New clearance issuance is disabled.
- Full NID, passport, tax ID, licence and financial data must not be
  sent via chat, email or these free-text metadata fields.
- Ordinary accounts cannot read activation-clearance tables. The list
  endpoint is admin-guarded and only returns provider identifier, display
  name, expiry and revocation timestamps.
- Existing local scanner/quarantine prototypes are NOT an approved upload
  gateway. Their own security documents note missing KMS, durable
  transaction handling, protected storage permissions, parser sandboxing,
  authenticated external ingress and key recovery.

## Before real uploads and formal KYC (blocked tasks)
1. Approve per-country policies and privacy notices, informed consent,
   purpose limitations, retention limits, legal holds and deletion workflow.
2. Deploy a separately authenticated ingestion gateway with verified
   GoTrue JWT, one-time intent, real scanner health and current signatures.
3. Isolate/sandbox document parsing and malware inspection. Enforce size,
   MIME, rate limits, replay limits and strict no-bypass fail-close rules.
4. Bind source bytes and sealed objects to a durable custody ledger,
   verified keys/KMS, encrypted quarantine, backup/recovery and tamper
   detection; test crash and recovery.
5. Add least-privilege, independently audited reviewer document release,
   per-jurisdiction ID/licence/business verification and exception escalation.
6. Add independent final-clearance issuance, re-verification, revocation
   notice and expiry-processing schedule with operation monitoring.
7. Add dedicated Helpdesk ticketing/SLA/escalation workflows after the
   onboarding safety gates have been validated.
8. Conduct signed-in browser acceptance tests, restore drills,
   penetration/security assessment and obtain explicit production approval.

## Files and tests
- SQL migrations: 20261011190000, 20261011190500, 20261011191000.
- Database pgtap: 043, 044, 045. All local tests are rolled back.
- Flutter UI: Operations evidence-register and clearance-status pages;
  applicant evidence inbox with widget tests. Technical Control unchanged.
- Local preview addresses: Client http://127.0.0.1:3000,
  Operations http://127.0.0.1:3200.
- This is a **Phase 2B foundation**, NOT a finished production
  identity-document verification service.
