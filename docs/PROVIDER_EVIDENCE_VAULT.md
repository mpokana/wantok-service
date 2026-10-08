# Protected evidence vault — closed intake foundation
Date: 9 October 2026 · Environment: EAGLT02 local only

## Purpose

The project needs a controlled chain of custody before collecting applicants' business credentials, identity papers, licences, patient information or financial documents. The existing `provider-documents` bucket is **not** a suitable evidentiary store because authenticated owners have update/delete permissions.

This milestone provides a distinct **sealed private storage boundary** and an administrator-controlled **future evidence planning register**. It does **not** offer working uploads, downloads, preview, malware scanning, credential validation, document acceptance, automated notifications or final provider approval. Avoid calling this phase "secure document uploads complete".

## New database/storage objects

Migration: `supabase/migrations/20261009011500_evidence_vault_boundary.sql`.

- Supabase Storage bucket `staged-provider-evidence`, `public=false`, 5 MiB maximum object size and allowed MIME declarations `application/pdf`, `image/jpeg`, `image/png`. No customer Storage object SELECT/INSERT/UPDATE/DELETE policies are created. The **Storage object service role still bypasses RLS**: it must not be used for document ingestion until a separate, audited malware-scanning service is commissioned. MIME labels and bucket size ceilings are not content validation.
- `public.staged_evidence_requirements`: one planning marker per pre-existing checklist item, with application/check IDs, admin account and timestamp, and `planned` or `cancelled` state. There are no file contents, paths, attachments, credentials, file links or personal documents in this table.
- `public.staged_evidence_requirement_audit`: append-only **through the authorised API** with admin actor, item and action timestamp. Direct authenticated INSERT/UPDATE/DELETE is revoked; a future retention design must protect and govern privileged service-role access as well.
- Row-level security restricts a user's planning visibility to their own application; administrators can read all. The audit is **administrator-only**. Neither client role can directly write either table.
- `plan_staged_evidence_requirement(uuid)`: admin-only, existing checklist + `in_review` application + `staged` policy required; idempotent, logs first creation only.
- `cancel_staged_evidence_requirement(uuid)`: admin-only, permits cancellation of a currently planned marker and appends an audit event. The cancelled marker stays cancelled (replanning requires a separately reviewed workflow). No payment, account/provider activation, notification or listing changes.
- The original `provider-documents` bucket, customer media buckets and existing provider approvals are untouched.

## Admin and applicant user experience

**Wantok Operations Admin → Provider Applications → Preliminary onboarding → Verification checklist → Evidence planning** shows each checklist item, its future evidence status, and confirmed `Plan future evidence` / `Cancel planning` actions. Both actions are planning signals only. The screen warns against collecting documents over email/messaging.

Applicants can view a warning on their own preliminary application when a future requirement is planned: **secure upload unavailable; do not send documents**. They cannot modify plans or see planning audit history. No upload or approval button is presented, including to admins.

These screens retain the established Wantok palette and do not alter the approved category-image grid or opt-in `SMOKE_20261008_*` fixtures.

## Acceptance and limitations

Local database test `supabase/tests/032_evidence_vault_boundary.test.sql` covers bucket privacy and declared limits, storage policy absence, a real RLS-denied authenticated object INSERT, planning and audit RLS, admin-only functions, denied ordinary-user planning, triage enforcement, idempotent plans, cancellation and zero uploaded files. Flutter tests exercise both applicant read-only notice and admin planning/cancellation confirmation.

Before enabling **any** real intake:
1. Approve category-specific legal/regulatory and data-minimisation rules, lawful basis/consent, privacy notice, retention periods and deletion/hold policy.
2. Implement isolated server-side upload issuance and **content/size validation based on file signatures**, malware scanning (with a real scanner), encrypted private quarantine, a positive clean scan before any reviewer reads, separate privileges, audit and verified object digest.
3. Design immutable/versioned evidence records, controlled replacement/correction, deletion schedules, backup retention and an actual test-restore; test object-level Storage RLS and abuse cases end-to-end.
4. Introduce independent reviewer roles and anti-self-approval rules. Only a separate, approved activation workflow may grant a provider profile or publish services.
5. Obtain explicit production-release authorisation, a tested migration/rollback plan and monitoring.

**Production is unchanged.** No real identity/licence/medical/financial documents or fake Supabase data were uploaded. All changes are local migrations and source code. The new closed bucket is NOT a ready-to-use evidence vault for sensitive uploads.
