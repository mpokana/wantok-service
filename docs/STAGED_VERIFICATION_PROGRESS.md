# CX1 — Staged verification progress and reviewer audit
8 October 2026 · Local development only

## Purpose and boundaries

This milestone adds **category-specific preliminary verification progress**, without accepting or validating uploaded credentials. It deliberately does not invoke the legacy `review_provider_application` function, which can immediately verify and activate providers. Preliminary application states remain `submitted`, `in_review` and `declined`. Review-item statuses are limited to `pending`, `under_review` and `needs_followup`. None of these constitute proof of compliance, final approval, document verification, provider activation or permission to sell/book services.

This also leaves the existing `provider-documents` storage bucket unchanged. Its original owner update/delete policies are inappropriate for evidentiary files: **do not store new staged-verification identity, medical or financial documents there**. A dedicated protected, immutable/revisioned evidence pipeline must be designed, threat-modelled and verified before accepting files.

## Schema and access

Migration: `supabase/migrations/20261008234500_staged_verification_progress.sql`.

- `staged_verification_checks` snapshots up to 20 category policy requirements per new preliminary application, with numbered immutable labels, status, last reviewer and timestamp. A secure insert trigger creates these items automatically. Existing staged applications are backfilled idempotently.
- `staged_verification_audit` records actor, application/check ID, prior status, next status and date for each actual change. No free-text identity, licence number, file contents or sensitive reviewer notes are collected.
- Row-level policies allow an applicant to read **only their own checks** and administrators to read all; audit events are visible only to administrators. Ordinary clients have no direct insert/update/delete privileges on either table.
- The `update_staged_verification_check(uuid,text)` RPC requires an authenticated administrator and a staged-category application already marked `in_review`. It allows only `pending`, `under_review` or `needs_followup`; any `approved` value is rejected. Repeating the existing status is idempotent and creates no extra event. It writes only review/check/audit tables.
- No modifications to `provider_profiles`, `provider_services`, `provider_applications`, roles, payments, messaging, bookings or user credentials. Existing provider application and approval workflows remain unchanged.

## UI

Wantok Operations Admin → Providers → Preliminary onboarding applications → **Open verification checklist** (shown only when the staged application is `in_review`). Each checklist item has confirmed, audited progress actions. An Admin-only **Review activity** list shows the chronological status transitions. There is **no Approve control**.

On the applicant's existing preliminary application page, users can read the requirement names and statuses only; they cannot change any decision or see the administrator-only audit history. Both user and admin UI states are tested with dependency-injected fake data; no actual user account or PII fixtures are inserted.

## Acceptance and further work

`supabase/tests/031_staged_verification_progress.test.sql` verifies RLS and direct-write denials, automatic checklist creation, applicant and cross-account visibility, non-admin RPC rejection, inability to change checks while an application is merely submitted, admin triage and review, audit recording, approval rejection and idempotency, plus unchanged provider activation. Flutter widget tests verify the applicant read-only view and Admin confirmation/audit list.

Before storing real evidence or enabling an approval route: design a dedicated private bucket with append-only object semantics, server-side content/MIME checking and malware scanning, category-specific document validation and expiry, reviewer access controls and separation of duties, consent and retention/deletion rules, audit integrity, legally verified PNG regulatory requirements for restricted categories, and independent provider/listing activation gates. Schedule deployment only after explicit approval and a tested database rollback.

**Production remains unchanged.** Only EAGLT02's local Supabase migrations and development app/Admin code are altered. Do not upload personally identifiable/licence/medical/financial documents for testing.
