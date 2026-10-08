# Controlled staged provider onboarding — 8 October 2026

## Scope and status

This phase is a **preliminary provider application intake with administrative triage**, not provider activation. It never calls legacy review_provider_application. Auditing that legacy path confirmed that approval would set a provider profile to verified/active, so the new categories MUST remain isolated until appropriate review, evidence handling and category-specific rules are agreed.

### Category readiness

- **Preliminary application intake open:** Shopping & Retail, Home Services, Beauty & Wellness.
- **Intake restricted:** Health & Medical (professional and facility credentials, privacy controls), Financial Services (regulator authorisation and AML/CTF obligations), Travel & Flights (supplier agency arrangements and refund rules), Education & Training (identity and safeguarding arrangements). The named checks are *design placeholders for later authorised compliance work*, not a definitive statement of Papua New Guinea legal requirements. Do not enable these categories without verified policy.

The prior, separate **provider interest** registry remains available for all seven catalogue-only categories. The existing 12 established provider application categories and their workflows remain untouched.

## Client flow

The existing CategoryInformationPage continues to use the approved category photograph, real category-filtered verified-provider search and opt-in interest button. An additive metadata query loads provider_onboarding_policies. A **Start preliminary application** button appears only when that category policy is `staged`. Restricted categories instead show their explanatory guidance, and missing/mismatched backend migrations fail closed (no button).

StagedProviderApplicationPage displays a future document-verification checklist but does **not** accept file uploads. It asks only for a name/business name, individual/business classification, coverage province/town and a brief service description. The account identity is bound by the backend authenticated principal; no arbitrary user ID is submitted from Flutter. The screen avoids collecting passports, patient data, financial details, licence documents or other sensitive attachments. An existing preliminary submission is displayed with its status and cannot be submitted again.

## Local-only backend

Migration: `supabase/migrations/20261008231500_staged_provider_onboarding.sql`.

- `provider_onboarding_policies`: seven explicit records with per-category readiness status and checklist guidance. Only three are staged.
- `staged_provider_applications`: one application per account/category, minimally necessary text fields, status limited to `submitted`, `in_review` or `declined`, timestamps and reviewer ID.
- RLS on both tables. Authenticated applicants can **read only their own applications**; administrators may read across accounts. Neither anonymous users nor ordinary authenticated users have direct table insert, update or delete permissions.
- `submit_staged_provider_application`: authenticated, category-policy-gated, validated and duplicate-safe RPC. Cannot run on a booking/transaction category or regulated/restricted category.
- `triage_staged_provider_application`: admin-only RPC, accepts only `in_review` or `declined` from previously submitted applications. Explicitly rejects `approved`, including when invoked by an administrator. It cannot publish listings or grant roles.
- No writes to `provider_applications`, `provider_profiles`, `provider_services`, payment, service booking, user role or notification tables.

Operations Admin → Providers → **Preliminary onboarding applications** provides a separate queue and explicit confirmation before changing status. This new queue offers **no Approve button**. The older provider applications and interest queues remain separate.

## Verification and acceptance

Run `npm run db:test` (test 030 exercises staged/restricted category gates, duplicate block, row-level privacy, ordinary-user triage denial and admin attempts to approve), `scripts/flutter/check.ps1` and `git diff --check`. Verify Android emulator has the Home Services preliminary application CTA and does not offer it for Health & Medical; never submit real account details just for a screenshot. The smoke/sample identity remains independently controlled by `WANTOK_SMOKE_DATA`, and no smoke records are inserted into Supabase.

## Still required before real provider approval

Design and approve the appropriate category-specific eligibility requirements, protected documentation and retention policies, verification workflows and separation of duties, audit evidence, independent provider-activation approval, listing moderation, ongoing suspension/revocation, and lawful service transaction arrangements. Compliance research and legal review are required for restricted categories. These activities must be separately tested and expressly authorised before changes to production policies or acceptance of real regulated service providers.

**Production remains untouched.** All new migrations are applied **locally on EAGLT02 only**; release requires local database backup, test migration, approved operational controls and coordinated Flutter/Admin build.
