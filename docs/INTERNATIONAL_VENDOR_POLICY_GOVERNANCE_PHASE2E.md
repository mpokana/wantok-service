# Wantok Services: International Vendor Compliance Governance (Phase 2E)

Date: October 2026. **Development-only**, tested with local Supabase on EAGLT02.

## Delivered
Operations → Verification & KYC → **International compliance policy proposals**.

Administrators can prepare internal policy proposals scoped by ISO-style
two-letter country code, optional province/state subdivision code, and
service category. The form records a proposed privacy notice, declared
purpose of collection, unverified legal-basis research, draft retention
period, and named types of evidence. A **full readable preview is required
before a draft is saved**. These are administrative proposals; the data is
never surfaced to applicants as an approved notice.

Policy states:
1. **draft**: editable only by creating a new proposal (original is immutable).
2. **submitted**: author submits to internal review.
3. **revision_requested**: a different Operations administrator returns
   the proposal with an explanatory rationale.
4. **internal_review_complete**: different administrator has completed an
   internal content review, NOT an approval of legal basis or evidence intake.

The state machine is enforced by PostgreSQL SECURITY DEFINER RPCs, not only
Flutter buttons. The draft author cannot self-review. Direct client INSERT,
UPDATE, DELETE to policy and event tables are blocked. Only authorised
Operations admins can inspect the proposals or their append-only audit
events. A returned proposal is revised into a **new, linked, incremented
version**, preserving its predecessor and previous decisions.

## What Phase 2E explicitly does NOT do
- No policies are legally approved, made effective or published to users.
- No automatically inferred country-specific legal requirements, regulator
  licences, mandatory document types or retention periods.
- No privacy notice consent or identity document upload.
- No file retention/delete schedule enabled by draft retention days.
- No KYC certification, clearance issuance, vendor payment or service activation.
- The repository's earlier evidence preflight remains upload_allowed=false.

## Additional gates before production
- Country code validation against a maintained ISO 3166 dataset, subdivision
  catalogues, locale/language translations and currency/rule effective dates.
- Dedicated policy author/reviewer roles and scoped country assignments,
  in addition to two distinct authenticated staff members.
- External legal/country-specialist attestation of specific legal sources and
  their dates, jurisdiction, appeal/retention exceptions, privacy rights,
  cross-border transfers, minors and high-risk category restrictions.
- Separately approved consent notices with exact content hashes, purpose
  limits, proof of display, explicit applicant action and withdrawal auditing.
- Independent enforcement engines for data minimisation, collection,
  access logging, retention/deletion and legal holds.
- Production KMS/HSM, segregated scanner/parser, authenticated ingestion
  service and append-only off-host custody ledger with recovery drills.
- Jurisdiction-scoped KYC verification, legal approvals, independent
  clearance issuance and re-verification/expiry monitoring.
- Helpdesk, SLA, incident escalation, anti-fraud controls, operations
  reporting and disaster recovery acceptance.
- Explicit staging-VM first-install, upgrade and restore rehearsals, then
  a signed, checksum-verified deployable release.

## Deployment and architecture
This is an additive PostgreSQL migration + Flutter Operations module:
- migrations `20261011200500_vendor_policy_governance.sql`,
  `20261011201000_vendor_policy_revision_chain.sql`
- regression SQL tests 048/049
- Operations `vendor_policy_governance_page.dart` and its widget tests
- entry point in `verification_kyc_page.dart`

No GVE/Wantok platform crossover, no changes to Technical Control, no
Android installation, no production environment or VPS access.

The existing `deploy/vps` Docker Compose installer, versioned migration
history, backup/upgrade scripts and checked-in source release packager remain
the deployment boundary. Once the enterprise controls are completed, the
feature can travel with the versioned source release rather than requiring
manual VM filesystem editing.
