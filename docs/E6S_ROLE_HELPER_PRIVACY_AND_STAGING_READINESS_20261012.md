# E6S — Role-helper API Privacy Contract and Dedicated-Staging Readiness

**Date:** 12 October 2026, PNG | **Project:** Wantok Services (PrjM) | **Authorised device:** EAGLT02 | **Status:** SOURCE-ONLY DRAFT; **NOT G8 APPROVED**; **G1–G10 BLOCKED**; no user or database changes.

## 1. Proposed contract (independent approval required)

Machine-checkable draft: `docs/E6S_ROLE_PRIVACY_CONTRACT_PROPOSAL_20261012.json`.
Validate with `npm.cmd run test:e6s:privacy-contract` (offline) or `npm.cmd run test:e6s:privacy-contract-local` (READ ONLY local PostgreSQL metadata).

**Proposed, not yet approved:** anonymous clients cannot enumerate another person's staff role, duty, access rank, or Technical entitlement. Ordinary authenticated clients receive only the minimum *self-scoped* eligibility/status appropriate for the service. Any cross-person query requires an independently approved purpose, delegated authority, data minimisation and auditable handling. Trusted RLS and internal `SECURITY DEFINER` routines must still be able to evaluate a subject user when legitimately required. No grant revocation, schema move or wrapper rewrite is authorised yet.

The **eight** functions in `public` are `has_role(text,uuid)`, `is_admin(uuid)`, `is_technical_platform_admin(uuid)`, `has_platform_permission(text,uuid)`, `has_technical_permission(text,text,uuid)`, `effective_technical_access_level(text,uuid)`, `can_access_technical_console(uuid)`, and `can_manage_technical_module_access(text,uuid)`. Read-only local pg_catalog confirms that all eight are `SECURITY DEFINER`, currently `postgres`-owned, with effective `anon`, `authenticated` and `service_role` SQL EXECUTE and explicit `search_path=public,auth` **without trailing `pg_temp`**. This is the **local SQL catalogue**, not a verified production or HTTP route.

E6R's synthetic network-disconnected pgTAP test showed that supplying another *fake* user's UUID can reveal staff/Technical entitlement even to SQL `anon`, while privilege-changing RPCs denied access. This is an **OPEN privacy/information-disclosure review finding**. It does not prove a real GoTrue token, published PostgREST endpoint, caller escalation or production breach. The proposed contract is not a signed security policy.

## 2. Migration-impact assessment and stop conditions

| Dependent system | What could break under naïve `REVOKE EXECUTE` or schema/argument changes | Required independent verification |
| --- | --- | --- |
| Operations RLS, case/evidence policies | `is_admin(auth.uid())`, `has_role(...,auth.uid())` could deny legitimate callers or cause policy recursion | Enumerate *currently effective* policy, owner, ACL and exact positive/negative grants in backed-up stage |
| Technical modules and permissions | Nested `has_technical_permission`, module access levels and access guards can stop or leak when caller vs subject changes | Technical owner verifies grants and scope; **T2.4 remains PAUSED** |
| Client/Technical Flutter | Dart `TechnicalControlRepository.canAccessConsole()` invokes `rpc('can_access_technical_console')` with default subject | Real signed-in *self* check works; unrelated UUID query does not reveal metadata |
| Taxi and booking | `get_taxi_ride_details` calls `is_admin(v_user_id)`, where `v_user_id := auth.uid()` | Passenger/driver/admin positive and wrong-user negative stage cases |
| Operations provisioning, role/COI/expiry | Trusted RPCs may need other-person role checks while authenticating the caller | Distinct human authority, role expiry/revocation, recusal/country/category limits remain enforced |
| PostgREST API schema/publication | SQL EXECUTE alone is insufficient to prove real REST reachability; default args/overloads matter | Authenticated, anonymous and delegated REST routes and exact returned fields/errors independently witnessed |
| E6O audit/notification, E6K public marketplace | Shared internal writer untrusted EXECUTE and provider column disclosures remain open | Independent fix contract, RLS compatibility, protected public-field projection |

**STOP** before any persistent change if approved legal classification, independent owner, exact role/RLS/ACL stage parity, backup/restore or test identities are missing; if a real test leaks a role, bypasses a privilege, interrupts legitimate module/client booking, or invalidates rollback. No blanket `REVOKE`, live migration or Technical implementation has been performed.

## 3. G8 D1–D5 independent decisions (all NOT SUPPLIED)

| ID | Decision | Owner/evidence required |
| --- | --- | --- |
| **D1** | Classify staff duties, role/rank and cross-person access as restricted by default vs a lawful public directory exception | Independent privacy, legal, Operations and security review, purpose and field-minimisation |
| **D2** | Choose self-only public wrappers, private trusted helper boundary, or explicitly authorised directory | Current SQL function/RLS call graph, real grants and schema publication, compatibility sign-off |
| **D3** | Define exact REST response/error for anonymous, self, unrelated authenticated and lawful delegated roles | Witnessed G7 GoTrue/PostgREST cases G7-24/27/28 |
| **D4** | Decide a narrowly scoped migration, `pg_temp` hardening and rollback | DBA and application security signed diff, stage owner/RLS parity and isolation |
| **D5** | Approve promotion and release only after relevant independent gates | G1–G9 evidence plus distinct G10 product/security/compliance go/no-go |

Candidate design **for review only:** expose minimum caller-self status through approved app-facing RPCs and preserve safely isolated, auditable trusted subject lookup for internal RLS and authorised staff. Do **not** implement before D1–D4 and parity validation.

## 4. Dedicated G7/G8 staging preflight (all PENDING)

| ID | Required gate evidence | Status |
| --- | --- | --- |
| **S-01** | Owner/security signed dedicated-stage authorisation, isolation, time and scope | NOT SUPPLIED |
| **S-02** | Isolated stage backup hash, independent restore and revert plan | NOT SUPPLIED |
| **S-03** | Database migration ledger, role/owner/ACL, RLS/default grant, current overload and API-schema *parity*, not disposable `--no-owner --no-acl` fixture | NOT SUPPLIED |
| **S-04** | Separate privacy-safe real GoTrue stage identities (ordinary A/B, Operations, Technical, provisioner requester/approver), managed in approved private custody | NOT SUPPLIED |
| **S-05** | D1–D5 independent privacy/security decisions and secure evidence repository | NOT SUPPLIED |
| **S-06** | G7-24/27/28 observed signed-in/anonymous HTTP and Flutter self-vs-other-user responses | NOT EXECUTED |
| **S-07** | Full 28-case G7 matrix, RLS/Technical/booking/client positive + negative and E6O audit writer protection | NOT EXECUTED |
| **S-08** | Recovery/offboarding, revoke/refresh, audit preservation and complete test account/grant cleanup | NOT EXECUTED |
| **S-09** | Independent G8 security decision and G10 final go/no-go only after G1–G9 PASS | BLOCKED |

Use approved opaque evidence IDs outside Git; **never put tokens, personal records, account secrets or staff evidence in the repository**. The E6R/E6S synthetic SQL tests are not independent GoTrue witnesses and do not authorise the dedicated staging instance.

## 5. Parallel G1–G10 preparation and current status

G1 HR/staff delegation; G2 distinct requester and approver; G3 trusted bootstrap and service-role custody; G4 current geographic codes; G5 country-specific legal service families; G6 actual COI/recusal; G7 **28 planned cases (zero witnessed)**; G8 independent cross-role metadata, E6K public column privacy, E6O audit/notification RPC rights and full definer surface; G9 independent DR/revoke/restore; G10 product/security/compliance release. **All ten formal gates remain BLOCKED**, 0/10 signed. Controlling runbook: `docs/E6G_FORMAL_ACCEPTANCE_RUNBOOK_20261011.md`, working register: `docs/E6G_PARALLEL_ACCEPTANCE_REGISTER_20261012.md`.

## 6. E6S completed validation evidence (source/isolated only)

- Proposed JSON contract `npm.cmd run test:e6s:privacy-contract` **PASS**, explicit `human_gates_approved=0`, production false and no real GoTrue acceptance.
- Read-only PostgreSQL catalog `npm.cmd run test:e6s:privacy-contract-local` **PASS**: eight function identity argument types and return types matched; current `postgres` definer ownership and all anon/auth/service grants observed; none of eight explicitly places `pg_temp` last. Metadata only, no private rows.
- Seven pending migration stage `npm.cmd run test:e6:crossstream-local`: **14 pgTAP suites / 286/286 assertions PASS**, synthetic transaction rollback, disconnected container removed, shared database unchanged. This stage is *not* exact owner/ACL parity.
- Unchanged main local synthetic JWT HTTP negatives **23/23 PASS**; E6 independent-case SQL **106/106 PASS**; evidence scanner **101/101 PASS**; full public definer catalog **152 functions / 95 anon-callable** inspected read-only.
- Detached exact-source Flutter `scripts/flutter/check.ps1` **exit 0**, seven clean analyses, **Client 132/132, Operations 43/43, Technical 38/38** widget tests PASS. No Flutter source change.
- Shared persistent combined SQL run is **not** claimed PASS, because seven migrations remain unapplied. All G1–G10 human approvals and genuine GoTrue G7 positive/negative witnesses **still BLOCKED**.

## 7. Engineering baseline and release discipline

E6R's last verified checkpoint was **14 isolated pgTAP files / 286/286** plus seven clean Flutter analyses, Client 132/132, Operations 43/43, Technical 38/38; E6S must log its **own new validation results**. There are **seven pending source migrations** intentionally unapplied to persistent shared Supabase. The E6N/E6O source-only mitigations remain unapplied. An E6S release archive, if built, must state `productionApproved:false`.

**Programme:** E-series P0 ACTIVE; G1–G10 evidence preparation PARALLEL; CX1 QUEUED; T2.4 PAUSED; E7+ and production SEALED.
