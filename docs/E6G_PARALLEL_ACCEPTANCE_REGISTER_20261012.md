# E6 G1–G10 — Parallel Independent Acceptance Preparation Register

**Prepared:** 12 October 2026 PNG | **Programme:** Wantok Services PrjM | **Status:** **0/10 formal gates approved — ALL BLOCKED**. This document is **not an approval, credential, authority assignment or gate sign-off**.

**Authority:** `docs/E6G_FORMAL_ACCEPTANCE_RUNBOOK_20261011.md` remains the controlling G1–G10 requirements. This new document organises evidence preparation **alongside** E-series source engineering, without silently assigning approvers or manufacturing evidence. No private witness/customer details, tokens, credentials or personal records belong in GitHub.

## Independent gate preparation workboard

| Gate | What can be prepared safely now | Independent role(s) and required witness | Evidence reference | Decision | Next dependency |
| --- | --- | --- | --- | --- | --- |
| G1 Staff identity | HR identity/delegation scope form with effective and expiry fields | HR/employer or contracting authority | **NOT SUPPLIED** | **BLOCKED** | Verify actual staff authority and employment dates |
| G2 Two-person provisioning | Request/approve/revoke test case IDs, role/duty/country/category/expiry acceptance sheet | Different named authorised requester and country approver | **NOT SUPPLIED** | **BLOCKED** | G1; independently signed decisions and revocation evidence |
| G3 Trusted bootstrap | Service-role custody, original provisioner bootstrap checklist, emergency exception ledger | Security lead **and** compliance owner | **NOT SUPPLIED** | **BLOCKED** | Written key custody and bootstrap provenance; no client-side service secrets |
| G4 Jurisdiction | Current source/edition/date/code verification form; source digest field | Geography steward **and** country legal/regulatory reviewer | **NOT SUPPLIED** | **BLOCKED** | Date-stamped ISO OBP and country authoritative corroboration |
| G5 Service legal mapping | Per `service_categories.id` family/risk/restriction worksheet | Operations classifier **and** legal owner | **NOT SUPPLIED** | **BLOCKED** | Regulated category restrictions and legal approval references |
| G6 Conflict/recusal | Beneficial owner COI declarations/recusal positive and negative case matrix | Independent ethics/COI reviewer and case investigator | **NOT SUPPLIED** | **BLOCKED** | Declarations, related-party checks and recusal-denial witness |
| G7 Real auth and tenancy | Exact GoTrue/PostgREST positive/negative matrix below; screenshot/redaction/evidence naming | Independent Security QA **and** Operations QA witnesses | **NOT SUPPLIED** | **BLOCKED** | Dedicated authorised stage + separate real synthetic test accounts |
| G8 Independent application security | E6J/E6K/E6L/E6M catalog/source inventory, exceptions and privilege-chain checklist | Independent application security reviewer | **NOT SUPPLIED** | **BLOCKED** | Exact stage role/ACL parity, definer pg_temp review, direct REST/RPC tests |
| G9 Recovery/revocation | Backup restore receipt, staff offboarding and key-rotation timing worksheet | DR owner **and** security/operations lead | **NOT SUPPLIED** | **BLOCKED** | Isolated restore, actual revoke/refresh, incident log and key custody |
| G10 Release go/no-go | Consolidated checklist, unresolved issue and exception register | Product owner **and** independent security/compliance approver | **NOT SUPPLIED** | **BLOCKED** | G1–G9 independently PASS + no critical unresolved findings |

**Never auto-convert** a code-test PASS into a gate PASS. The controlling source runbook requires **real independent accountable people**. A single ChatGPT conversation can prepare evidence, test code and organise blockers, but cannot act as two human witnesses or create their signatures.

## G7 — Witnessed authenticated test case identifiers (all NOT EXECUTED)

Do not run until dedicated staging, role-parity and test identity approvals are documented.

| Case | Principal / action | Expected result | Status |
| --- | --- | --- | --- |
| G7-01 | Anonymous public provider discovery | Only explicitly approved public verified/active fields; no private metadata after agreed policy migration | **BLOCKED** (E6K field decision open) |
| G7-02 | Anonymous duty/clearance list or trusted RPC | No access or data leak | **NOT EXECUTED** |
| G7-03 | Applicant A own staged intake case | Own permitted metadata only | **NOT EXECUTED** |
| G7-04 | Applicant B direct REST read of applicant A case/evidence | Denied, no enumerable protected records | **NOT EXECUTED** |
| G7-05 | Existing global admin but no independent country duty | No E6 trusted case, identity or clearance access through legacy admin flag | **NOT EXECUTED** |
| G7-06 | Country-matched current Morobe/trades reviewer | Only allowed independently classified cases and actions | **NOT EXECUTED** |
| G7-07 | Wrong country, region or category reviewer | Denied UI and direct RPC/REST | **NOT EXECUTED** |
| G7-08 | Reviewer in self-owned case or declared recusal | Denied case operations immediately | **NOT EXECUTED** |
| G7-09 | Evidence officer without review duty | Only authorised metadata planning, no case decision or identity upload | **NOT EXECUTED** |
| G7-10 | Safety investigator with unrelated clearance/prior reviewer conflict | Scope and reviewer separation enforced; no issuance | **NOT EXECUTED** |
| G7-11 | Duty requester creates unapproved bounded change | Pending only; duty ineffective until separate approval | **NOT EXECUTED** |
| G7-12 | Self/requester/subject or wrong-country approval | Denied, immutable decision audit remains correct | **NOT EXECUTED** |
| G7-13 | Distinct delegated approver on valid pending request | Allowed only with current matching independent authority | **NOT EXECUTED** |
| G7-14 | Expired/revoked duty and stale browser session | No surviving privileged Web and direct API access | **NOT EXECUTED** |
| G7-15 | Provider editing someone else's listing/verification/status | Denied; no activation or KYC enabled | **NOT EXECUTED** |
| G7-16 | Legacy `review_provider_application` and service activation API | Denied under sealed E6/E7 release rules | **NOT EXECUTED** |
| G7-17 | Fake service-role JWT, malformed auth header, token replay | Fail closed without secret or protected data | **NOT EXECUTED** |
| G7-18 | Stage cleanup and post-run role/identity ledger | Test-only accounts removed/revoked under approved retention and witnessed checksum; audit preserved | **NOT EXECUTED** |

Capture for each **only when actually witnessed**: case ID, test environment ID, commit and migration versions, separate principal roles, expected result, observed HTTP/browser result, pass/fail, timestamp, authorised witness IDs, redacted secure evidence pointer and cleanup attestation. Keep real tokens and private case data **outside GitHub**.

## E6N G8 engineering evidence update (NOT G8 sign-off)

- **Prospective code:** E6N `20261012140000_e6_operations_definer_search_path.sql`, unapplied to persistent local/production DB, explicitly appends `pg_temp` last for 19 selected privileged functions.
- **Disposable verification:** six migrations, ten pgTAP files **206/206 PASS** including new E6N 25/25, with 19-function SQL-body/owner/ACL fingerprint unchanged within the isolated test fixture; shared DB intact. Test-stage original ACLs are **NOT** owner/role parity because schema-only `--no-acl` restoration reconstructs select grants.
- **Reviewer requirement:** independently verify all relevant function overloads/nested calls, exact real stage privilege/owner/RLS parity and G7 positive/negative GoTrue/PostgREST sessions. Until then G8 remains **BLOCKED**; no reviewer signature or evidence reference supplied.
- **Source report:** `docs/E6N_SEARCH_PATH_HARDENING_AND_GATE_READINESS_20261012.md`.

## G8 — Independent review worklist

- [ ] Review **all relevant overloads and nested routines**, not only the 19 selected E6 `SECURITY DEFINER` sources (E6M).
- [ ] Compare exact applied function definitions, owner `BYPASSRLS`, effective EXECUTE grants and application role memberships with production-equivalent stage.
- [ ] Assess temp-table/type resolution with `pg_temp` explicitly last, implicit operators/casts and schema-qualified references; don't confuse a flagged absence with a confirmed exploit.
- [ ] Review dynamic SQL and caller-controlled parameters for every privileged call-chain, legacy `is_admin` paths and service-role key custody.
- [ ] Resolve E6K 18/18 profile and 23/23 service anonymously readable columns with approved public fields, nested REST compatibility and negative metadata tests.
- [ ] Witness the G7 positive **and** negative GoTrue/PostgREST/Flutter results and collect independent signed exceptions.

## Evidence intake and status discipline

Only an authorised reviewer may enter a decision after obtaining separately protected evidence. The Git-tracked register can carry opaque reference IDs and hashes **after release of those references is approved**, not raw documents. Do not backfill a date, signature or simulated reviewer name. All blank slots remain **NOT SUPPLIED**, all decisions **BLOCKED**.

**Specific authorised prerequisites before any live G7 test:** a separately approved dedicated staging instance, backup/restore verified, exact role/owner/ACL tests, safe non-production user enrolment and consent process, independent human witnesses, source/destination network isolation, planned rollback and defensible evidence handling. EAGLT02 shared Supabase is not this dedicated acceptance stage.

## Engineering evidence references available to reviewers (not sign-offs)

- `docs/E6J_TRUST_CATALOG_AND_CROSSSTREAM_QA_20261012.md` — read-only E6 function/table metadata and original E6J QA.
- `docs/E6K_PUBLIC_MARKETPLACE_RLS_AND_PRIVACY_BOUNDARY_20261012.md` — public-row and **column** disclosure finding, 17 synthetic pgTAP coverage.
- `docs/E6L_PRIVILEGED_FUNCTION_OWNERSHIP_AND_GATES_20261012.md` — local function owner/privilege/temp-schema inventory and prior G preparation.
- `docs/E6M_FUNCTION_SOURCE_REVIEW_20261012.md` — selected latest-definition source review and combined QA.
- `docs/E6G_FORMAL_ACCEPTANCE_RUNBOOK_20261011.md` — **authoritative** human evidence and sign-off conditions; remains wholly blocked.

## Programme dependency

E6 source engineering continues; G1–G10 preparations continue in parallel without changing their blocked status. **E6 acceptance cannot close and E7+ cannot activate until formal gates pass.** Following safe P0 engineering, only the explicitly permitted CX1 *nonmutating* acceptance work can proceed while external approvals remain blocked. T2.4 stays paused.
