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
| G7-19 | Ordinary authenticated user calls `grant_user_role` / `revoke_user_role` directly via PostgREST | Denied; no role grant, revocation, partial audit or actor spoofing | **NOT EXECUTED** |
| G7-20 | Distinct authorised Operations admin and Technical platform admin perform separately delegated role changes | Only granted role families succeed; target/current-admin safeguards and real attributable audit evidence observed | **NOT EXECUTED** |
| G7-21 | Ordinary user attempts direct `grant_technical_module_access`, `revoke_technical_module_access` and module enable/maintenance RPCs | Denied, without technical grant, state or queued side effects | **NOT EXECUTED** |
| G7-22 | Non-admin user attempts direct branding publish/restore and `manage_service_category` RPCs; different authorised editor performs a permitted, reversible stage operation | Non-admin denied; separately granted editor positive path and audit succeed only under approved test plan, reverted under witness | **NOT EXECUTED** |
| G7-23 | Ordinary signed-in user and anonymous client call `write_audit_event` and `enqueue_notification` direct REST after separately approved E6O correction | Permission denied with no audit/outbox forging; approved server-only path retains function under least privilege | **BLOCKED** (E6O source fix not applied) |
| G7-24 | Ordinary authorised GoTrue user calls `has_role`, `is_admin`, `is_technical_platform_admin` with another test account's UUID | Independently approved public role-disclosure contract: reject or minimise unrelated-user metadata; no authority inheritance | **NOT EXECUTED** (privacy contract open) |
| G7-25 | Logged-in Operations admin and a separate Technical platform admin execute each other's role-grant/revoke actions | Deny cross-role mutations while permitting separately delegated role-family changes; no stale audit or privilege elevation | **NOT EXECUTED** |
| G7-26 | Actor with expired, revoked, or legacy profile-flag-only privilege calls role helpers and directly mutating RPC | Old role flags cannot reactivate privileges; current RBAC grant/expiry and real session checks fail closed | **NOT EXECUTED** |
| G7-27 | Anonymous client calls explicitly subject-targeted `has_role`, `is_admin`, `is_technical_platform_admin` and `can_access_technical_console` over direct PostgREST RPC for independently authorised synthetic staged UUIDs | **G8-approved privacy contract** is enforced: no unapproved staff-role/Technical entitlement disclosure; approved legitimate public discovery remains functional | **BLOCKED** (privacy classification and dedicated stage not authorised) |
| G7-28 | Separate real signed-in ordinary user and delegated administrator compare default self-role helper calls vs another synthetic user's UUID in browser and direct PostgREST, before and after independently reviewed mitigation | Self-scoped Client/Technical status behaves correctly; unrelated-user metadata denied or minimised; approved delegated staff access still works and cleanup is witnessed | **NOT EXECUTED** |

Capture for each **only when actually witnessed**: case ID, test environment ID, commit and migration versions, separate principal roles, expected result, observed HTTP/browser result, pass/fail, timestamp, authorised witness IDs, redacted secure evidence pointer and cleanup attestation. Keep real tokens and private case data **outside GitHub**.

## E6N G8 engineering evidence update (NOT G8 sign-off)

- **Prospective code:** E6N `20261012140000_e6_operations_definer_search_path.sql`, unapplied to persistent local/production DB, explicitly appends `pg_temp` last for 19 selected privileged functions.
- **Disposable verification:** six migrations, ten pgTAP files **206/206 PASS** including new E6N 25/25, with 19-function SQL-body/owner/ACL fingerprint unchanged within the isolated test fixture; shared DB intact. Test-stage original ACLs are **NOT** owner/role parity because schema-only `--no-acl` restoration reconstructs select grants.
- **Reviewer requirement:** independently verify all relevant function overloads/nested calls, exact real stage privilege/owner/RLS parity and G7 positive/negative GoTrue/PostgREST sessions. Until then G8 remains **BLOCKED**; no reviewer signature or evidence reference supplied.
- **Source report:** `docs/E6N_SEARCH_PATH_HARDENING_AND_GATE_READINESS_20261012.md`.

## E6O G8 finding register (12 October; no independent sign-off)

| Finding | Source-engineering evidence | Remaining independent acceptance requirement | Status |
| --- | --- | --- | --- |
| **E6O-01 shared RPC grants** | Current local catalog: two owner-privileged audit and notification helpers have untrusted EXECUTE grants despite original intended service-role-only grants; proposed source-only corrective migration `20261012152000`; disconnected negative SQL checks PASS | Independently verify PostgREST attack surface, legitimate caller compatibility, exact owner/ACL parity, stage backup, rollback, and G7 witnessed login/direct RPC denial **before** applying to any persistent DB | **OPEN / G8 BLOCKED** |
| **E6O-02 Technical health report** | Current local `record_technical_module_health_report_internal` untrusted EXECUTE with definer owner; no Technical changes made | Independent Technical and security owners to verify caller trust, role permissions and stage tests when T2.4 unpaused | **OPEN / G8 BLOCKED** |
| **E6O-03 broad catalogue** | Read-only complete `public` definer inventory: **152**, **95 anonymous-callable**, **133 signed-in-callable**, no explicit trailing `pg_temp` in live local metadata | Independent review beyond selected 19 E6 functions: trigger functions vs public APIs, role guards, nested calls, SQL/operator/name resolution and public column privacy | **OPEN / G8 BLOCKED** |

The independent security reviewer has not supplied any signed evidence; these are source/isolated engineering findings, **not** external approvals. G1–G10 acceptance remains **0/10 BLOCKED**, and all 18 planned real GoTrue G7 cases remain unexecuted.

## E6P G7 role and platform-control witness update (not executed)

The real-session acceptance matrix above now includes **G7-19 through G7-23** (23 planned cases total). The new E6P rollback-only `062` pgTAP **23/23** checks verify nine anonymously denied privileged mutations plus NULL session-identity denial and empty disposable test tables. The full disconnected integration run is **243/243 assertions PASS**. **These synthetic technical findings are not evidence from any actual GoTrue-authorised users, distinct witnesses or positive authorised control paths.** G7 remains **BLOCKED**, as do G1–G10; no human decision status was changed.

Independent reviewers must confirm in a separately authorised backed-up stage that role-family restrictions distinguish Operations from Technical administrators, that unrelated authenticated users cannot grant themselves duties/roles, that separately delegated human actors can execute positive cases only within legal scope, and that the E6O writer function policy is closed before release. Detailed checkpoint: `docs/E6P_ROLE_ADMIN_CONTROL_NEGATIVES_AND_G7_WITNESS_PLAN_20261012.md`.

## E6Q cross-principal helper information boundary (NOT G7 or G8 acceptance)

- **E6Q G8-04 (OPEN):** selected definer helpers `has_role`, `is_admin`, `is_technical_platform_admin`, `can_access_technical_console` accept an explicit subject UUID. A synthetic ordinary actor can query other fake users' Operations/Technical role state without inheriting those permissions. Review possible signed-in role-directory information exposure via actual PostgREST; decide an approved role-metadata privacy policy before changing internal helper signatures or EXECUTE rights.
- **Synthetic regression:** `063` tests **25/25 PASS**, four fake identities and rollback-only role assignments; Operations vs Technical grant/revoke separation confirmed under synthetic JWT context. Combined disposable SQL **268/268 PASS**, no source DB changes or real account creation.
- **G7 parallel readiness:** 26 planned witness case IDs, **zero real signed-in GoTrue sessions tested**. G7-24/25/26 add cross-user helper privacy, independently delegated cross-role test and expired/legacy-role fail-closed checks. **All G1–G10 human approvals remain BLOCKED.** Evidence `docs/E6Q_ROLE_HELPER_CROSS_PRINCIPAL_BOUNDARY_20261012.md`.

## E6R G8-04 metadata-disclosure decision intake (NOT independent sign-off)

- **Local observed ACL:** eight selected `public` SECURITY DEFINER role helpers have effective `anon`, `authenticated`, `service_role` SQL EXECUTE in the current EAGLT02 local DB. This is not confirmed public production HTTP API access.
- **Disposable evidence:** new `064` **18/18 pgTAP** reproduces anonymous SQL role inquiry about other synthetic users' Operations/Technical role and console entitlement, no ability to grant privileges; disconnected cross-stream SQL **286/286 PASS** with rollback and no shared DB changes. Passing repro is **open privacy evidence, NOT an acceptable released state**.
- **Independent G8 decisions D1–D5:** classify staff role/rank metadata, decide caller-only vs delegated API disclosure, prove nested SQL/RLS compatibility, stage authentic GoTrue positive/negative observations, and formally sign rollback/owner/ACL parity. No blanket `REVOKE` before independent review. Pack `docs/E6R_ROLE_METADATA_CALLGRAPH_AND_G8_DECISION_PACK_20261012.md`.
- **G7 parallel:** **28** cases planned; G7-27/28 require anonymous REST role disclosure and real signed-in caller/other-subject checks after approved privacy contract. **0 executed/witnessed**. All formal G1–G10 **BLOCKED**.

## E6S D1–D5 privacy/ACL and S-01..S-09 staging-preflight intake (NOT G8 sign-off)

- Source contract `docs/E6S_ROLE_PRIVACY_CONTRACT_PROPOSAL_20261012.json` proposes no anonymous other-person staff role/Technical rank enumeration, ordinary signed-in caller-self status only unless real delegated authority is independently approved, and continued safe trusted internal subject checks. **Not an approved legal/security contract or executable migration.**
- `scripts/qa/e6s-role-privacy-contract.mjs` has both source-only and READ ONLY local pg_catalog validation of eight exact function signatures/returns and current SQL privileges. Local SQL grants are not evidence that a PostgREST route is publicly exposed.
- G8 independent **D1** classify role metadata, **D2** select compatibility-safe external vs internal helper boundary, **D3** witness genuine GoTrue/PostgREST anonymous/self/other/delegated outcomes, **D4** approve a narrow reversible migration and role/owner/RLS parity, **D5** final release only after independent gates. **All NOT SUPPLIED.**
- Dedicated stage **S-01..S-09** still requires owner scope authorisation, proven backup/restore, exact grants and schema exposure, private real test identity custody, independent witnessed G7 cases (all **28 NOT EXECUTED**), cleanup and final signatures. No fake witness or evidence IDs.
- **All G1–G10 formal decisions BLOCKED (0/10 approved)**. E6K/E6O/E6R privacy and writer risks remain OPEN. Detailed doc `docs/E6S_ROLE_HELPER_PRIVACY_AND_STAGING_READINESS_20261012.md`.

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
