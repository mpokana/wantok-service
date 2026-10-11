# Wantok Services — Enterprise Vendor Intake Phase 1

## Scope
This is a secure *pre-approval intake* for people and registered businesses, not full identity verification or active marketplace enrolment. Existing Operations, Technical Control and customer modules are preserved.

## Customer workflow
Wantok Services → profile vendor action (or Vendor Home → Apply) → **Become a Wantok vendor**. Four screens:

1. Applicant: individual or registered business; category; legal name; for businesses, company registration number and TIN **last four** only; service summary.
2. Contact: operating country (editable), state/province, town/city, physical address, email and phone; identity document type and **last four** only (optional).
3. Category requirements: transport/ride-hail lists vehicle type, make, model, manufacture year, rego/plate, expiry, driver licence class/expiry and insurance expiry; food records premises/permit expiry; trades such as plumbing/IT list speciality and licence/registration expiry; equipment hire records equipment type, make/model, asset serial, inspection/qualification expiry.
4. Review/declaration → submit. Server returns an immutable case UUID. Applicant may review history, see staff requests and respond in-app with limited non-document text.

**No full ID, NID, passport, driver's licence or TIN is collected; no document upload.** The planned encrypted document evidence vault and regulator-specific verification rules require separate security acceptance.

## Operations workflow
Wantok Operations (`http://127.0.0.1:3200`) → **Providers** → **Applications & Review**. Every case has a status, timestamp, contact/operating location, category metadata, staff audit history and a review queue. Staff may:
- Begin review
- Request additional non-document information (reason mandatory)
- Decline with recorded reason
- Inspect the append-only case events

An applicant response returns the case to the queue. **No approval/activation button** is available in the preliminary intake.

## Critical backend safety gate
Legacy `review_provider_application()` no longer sets verified status, is_provider, is_driver or driver approval on application acceptance. Service listing `admin_set_provider_service_status()` blocks **new** activation unless a separate independent, unexpired clearance exists and provider profile is verified/active. The clearance data model requires two distinct reviewers, but the issue/evidence-checking workflow for granting it is not yet built. This is intentional fail-closed behaviour. Historical active records are not migrated or modified automatically; review their provenance before any broad production rollout.

## Access controls
- `vendor_intake_cases` stores applicant contact information with owner/admin RLS. No direct authenticated INSERT/UPDATE/DELETE.
- `vendor_intake_events` is append-only through audited SECURITY DEFINER RPCs with actor, reason, previous/next status and timestamp. Owner/admin read only.
- Input and metadata keys validated on server; public/government/financial/medical categories are excluded.
- No application auto-publishes a service, enables bookings or pays out funds.

## Phase 2 required before international production
- Secure non-public evidence storage, scanning, encrypted handling, expiry, access logging and retention/deletion policy; applicant consent/privacy notices per country.
- Verification of full ID against authorised sources and proof of address; company registry/TIN/business ownership; professional permits, vehicle licence and insurance; equipment safety certifications; sanctions and financial compliance where legally required.
- Separation of case officer, checker and final approver, with country-scoped staff RBAC and conflict-of-interest checks.
- Explicit clearance grant/revoke workflow, renewal and monitoring; existing provider verification-history audit.
- Category-specific mandatory evidence rules, user-facing document-request tasks, helpdesk ticket/SLA and communication workflow.
- End-to-end signed-in browser acceptance tests using non-sensitive test identities. Never deploy to production without the applicable legal and operational review.

## Development deployment
EAGLT02 Flutter Web client `127.0.0.1:3000`, Operations `127.0.0.1:3200`, Technical Control `127.0.0.1:3100`. Only local Supabase was migrated during Phase 1; Git backup is a feature branch, not a production deployment.
