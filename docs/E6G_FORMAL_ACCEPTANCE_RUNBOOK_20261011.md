# E6G — Formal Operations Trust Acceptance Runbook

**Status: BLOCKED / NOT SIGNED OFF** · Prepared 11 October 2026 · `feature/flutter-platform-v1` · EAGLT02 only
**Scope:** E6 operational identity, permission/tenancy/jurisdiction, legal source and security acceptance before any E7 start. This document is not a staff authorisation, legal sign-off or production approval.

## Source-of-truth and separation

- Application source: `docs/E6D_E6F_DUAL_STAFF_STAGED_CASE_RECUSAL_20261011.md`, `docs/E6DEF_INTEGRATED_SECURITY_ACCEPTANCE_20261011.md`, release readiness matrix and the actual migrations/tests. Local synthetic pgTAP records do not constitute real delegation or verified provinces.
- Country code and current subdivision codes: ISO **Online Browsing Platform (OBP)**, https://www.iso.org/obp/ ; ISO guidance: https://www.iso.org/iso-3166-country-codes.html ; ISO 3166-2:2020 edition page https://www.iso.org/standard/72483.html . ISO's own material says the online browsing data is maintained; a code's shape or historical code list is **not** proof of a current approved subdivision. Have a designated regional officer record the edition, access date, country, subdivision, code and snapshot reference; do not copy unverified pages into the database.
- Administrative cross-check for Papua New Guinea: PNG Department of Finance, https://www.finance.gov.pg/about-us-2/provincial-and-district-finance-office/ identifies **22 province-level divisions** (20 provinces, Autonomous Region of Bougainville, National Capital District). PNG National Statistical Office https://www.nso.gov.pg/statistics/population/ separately enumerates province names. These sources are **cross-checks for geography and names**, not blanket ISO code attestation, sector regulation or authority to enable provider services.
- No documents, national ID numbers, private investigations, secrets or passwords are to be placed into this Markdown file, GitHub issues or source control. Store restricted evidence under a separately authorised secure evidence register only. Reference ticket ID, reviewer, date and cryptographic digest where allowed.
- Need at least two **different** named, properly authorised human officers for country-scoped delegate assignment. An `is_admin` flag is insufficient. No person may approve their own access or adjudicate cases involving themselves or an associated business.

## Gate acceptance worksheet (all must be PASS, otherwise BLOCKED)

| Gate | Independent accountable role | Evidence required (safe reference only) | Current |
| --- | --- | --- | --- |
| E6-G1 staff identity | HR/employer or contracting authority | Internal verification record, real staff authority, start/end dates and delegation ID | BLOCKED |
| E6-G2 dual provisioning | Authorised requester + different country approver | Distinct approver/requester identities, signed decision, bounded expiry, country/category/region, test and revocation receipts | BLOCKED |
| E6-G3 authority bootstrapping | Security lead + compliance owner | Offline dual sign-off for first provisioners and exceptional trusted service-role provisioning; privilege break-glass access log | BLOCKED |
| E6-G4 jurisdiction | Country legal/regulatory reviewer + geography steward | Current ISO OBP entry, country/subdivision identifiers, date/source digest and alternate country-authoritative corroboration | BLOCKED |
| E6-G5 service taxonomy | Operations classification reviewer + sector legal owner | Mapping each real `service_categories.id` to finite family, restricted/regulated types, dated approval and rollback/expiry evidence | BLOCKED |
| E6-G6 recusal and adverse ties | Conflict/ethics investigator independent of case | Self-declaration and independent beneficial ownership/related-party screening reference; positive denial after recusal | BLOCKED |
| E6-G7 authenticated role/tenant separation | Security QA witness + Operations QA witness | Actual separate fresh session proofs for anonymous, applicant, old global admin, reviewer, evidence officer, investigator, unrelated country/province/category and revoked staff, including direct REST bypass | BLOCKED |
| E6-G8 permissions/legacy route | Independent application security reviewer | Inherited RPC/RLS/column-grant inventory, service-role privilege treatment, malicious JWT/forced path test and approved exception register | BLOCKED |
| E6-G9 recovery and incident response | Security/operations lead + DR owner | Staff offboarding timing, revocation/refresh test, audit export, key custody, emergency pause and restore rehearsal references | BLOCKED |
| E6-G10 release determination | Product owner + independent security/compliance approver | Consolidated signed evidence references, formal exception decisions and no unresolved critical findings | BLOCKED |

**Automated evidence is not a replacement:** `npm.cmd run db:test` exercises transactional pgTAP synthetic JWT claims; `npm.cmd run test:e6:auth-local` sends short-lived *synthetically signed* JWTs to the loopback PostgREST API, validates 23 **negative-only** isolation/authority requests without DB fixtures or accounts. Neither is a GoTrue login, a browser witness, a valid named officer, source attestation, production migration, penetration test or positive granted-role sign-in.

## Witnessed live/local-staging role matrix (do not execute without approved test identities)

Use a **designated EAGLT02-only local staging database** with separately authorised synthetic test accounts created using an approved reversible plan and audit, *not* display/demo seed data. These steps remain **pending**; no test identity or database demo row has been created here.

1. Document witness IDs and safe case IDs in restricted QA system. Prohibit entry of live identity documents, licences, personal records or financial material. Confirm all test participants use different browser profiles and fresh sign-in/out, no elevated session reuse.
2. Sign in as applicant A; see own staged and enterprise application only. Applicant B and legacy `is_admin` with **no matching duties** must see no applicant A case, checklist or evidence records. Direct REST queries against the same case must also be denied.
3. Sign in as PG / verified Morobe / `trades` `case_reviewer`; see only matching, independently classified case, triage/progress only. Wrong province, wrong country, wrong family, suspended region and revoked/expired staff must return no records **and** denied mutating RPCs.
4. Sign in as distinct `evidence_officer`; access metadata planning only, without case triage or approval; ordinary applicants cannot plan or upload evidence. Storage access remains sealed.
5. Sign in as `safety_investigator` with verified case/provider linkage, confirm read and independent emergency pause permissions only; reject issuance, self-approval, expired conflicts and nonmatching case.
6. Sign in as a country-scoped provisioning **requester**; submit bounded grant for a different person. Confirm grant has no effect while pending. A different independently provisioned approver must approve with reason; request originator and subject must fail approval. Test reject, duplicate decision, cross-country and offboarding in fresh sessions.
7. Declare a staff conflict on each of two controlled case types; verify immediate denial of **all** staff duties for that case while applicant rights and unrelated cases remain visible. Compliance witness checks manual related-party audit separately.
8. Directly attempt `provider_profiles.verification_status`, `provider_services.status`, `provider_resources.status` changes as provider account, and legacy approval/activation RPCs as unassigned staff. All must deny; no listing, booking, payment or identity upload should turn on.
9. Revoke the duty, disable geography, alter category mapping and sign out. Witness both cached UI navigation refresh and direct API after revocation. Retain anonymised evidence **outside GitHub**, with case/account references masked.
10. Restore the clean controlled state and verify an empty test-account ledger, no active rights, no evidence object, no provider listing activation and retained audit according to approved retention rules. Require independent final witness signatures.

## Preflight and stop conditions

- Stop if staff/legal officer names or signatures are absent, if any approving officer is the subject/requester or declared interested party, if jurisdiction code cannot be validated with a dated official source, or if service is regulated but the country legal position is not independently confirmed.
- Stop on any cross-user/province/country/sector case leak, any successful browser privilege change outside a two-person workflow, any evidence ingress opening, any service activation, unsigned security exception or production routing.
- Do **not** use `db:reset`, test identity seeding, destructive cleanups or any service-role call on the running shared DB solely to satisfy this checklist; first approve an isolated reversible staging plan and export/backup. A passing isolated negative API check does not justify changing this prohibition.
- No work on online VM, GVE devices or VPS is authorised by this E6 runbook. Continue on EAGLT02 only. E7–E12 **remain gated**.

## Current automated evidence and integrated-database limitation

- Local E6 SQL regression: **56 files / 1,139 assertions PASS**, selecting the unmodified test files numbered 001–056 through the existing Supabase test runner.
- Evidence security: **101/101 PASS**.
- Loopback PostgREST read-only synthetic-JWT boundary check: **23/23 PASS** using `npm run test:e6:auth-local`.
- **Combined shared SQL runner remains BLOCKED:** newly committed T2.4 test `090_technical_scoped_health_log_adapter.test.sql` requires migration `20261011240000_technical_scoped_health_log_adapter.sql`, which the T2.4 owner intentionally has not applied to the shared local DB. The combined run therefore fails for absent RPC `list_technical_module_log_events`, not for an E6 assertion. Do **not** apply that separately owned migration without coordination or claim 57/57 PASS.
- A synthetic JWT is not a GoTrue authenticated real human. This checkpoint gives negative transport/authorisation evidence only. No positive role-activation, witnessed browser or identity/security-attestation evidence has been collected.

## Sign-off (blank until independently witnessed)

| Role | Attestation reference (not personal data) | Signed date | Decision |
| --- | --- | --- | --- |
| Operations / country compliance owner | — | — | PENDING |
| Human-resources delegated authority | — | — | PENDING |
| Legal/regional reviewer | — | — | PENDING |
| Independent QA/security witness | — | — | PENDING |
| Platform/security key custodian | — | — | PENDING |
| Product owner | — | — | PENDING |

**E6 disposition:** `BLOCKED — FORMAL ACCEPTANCE NOT COMPLETE`. The application stays source-only/local until the checks are independently completed and accepted. No automated script may write a PASS decision for human evidence.
