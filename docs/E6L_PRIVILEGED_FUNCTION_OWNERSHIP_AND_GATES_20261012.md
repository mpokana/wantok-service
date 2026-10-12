# E6L — Privileged Function Trust Review and G1–G10 Parallel Readiness

**Checkpoint:** 12 October 2026 (PNG) | **EAGLT02 local database only** | **Outcome:** catalog baseline **PASS with review items**, formal E6-G1–G10 **all BLOCKED**. No access elevation, schema/role/key changes, authentication provisioning, real records read, shared migrations or production activity.

## 1. E6L read-only, reproducible PostgreSQL results

Run from the project repo with Docker Desktop connected to its existing local Supabase:

`npm.cmd run test:e6:function-trust-local`

The command uses a fixed local Docker container, read-only PostgreSQL transaction, catalog queries and JSON metadata only. It **does not fetch function bodies, customer/provider rows or credentials**. Selection covers 19 *named/prefix-filtered* E6/Operations SECURITY DEFINER functions, **not the full database attack surface**. Source revision must be recorded separately.

| Scope checked | Observed baseline | Interpretation / follow-up |
| --- | --- | --- |
| 19 selected functions and owner | 19/19 SECURITY DEFINER; all owned by `postgres` | In this local DB `postgres` has `BYPASSRLS`. Internal scoped auth checks are critical; no proof of exploitable bypass |
| Public API roles | `anon` EXECUTE denied on all 19 | Expected under restricted E6 interface, technical baseline passes |
| Trusted-only privileged functions | 7 named trusted-only routines have no `authenticated` EXECUTE grant | Ensure service-role callers are server-only, not embedded in browser/mobile assets |
| Other `authenticated` routines | Mixed EXECUTE grants are intentionally present | They require independent **inside-function** tenant/duty/recusal checks; EXECUTE is not approval |
| Search paths | 19/19 explicit `search_path=public, auth`; 19/19 lack explicit trailing `pg_temp` | Review temporary relation/type name resolution against actual checked-in function bodies and dynamic SQL. Propose `public, auth, pg_temp` where safe; test in owner/ACL-equivalent disposable stage before any migration |
| Schema CREATE rights | Neither `anon` nor `authenticated` can CREATE in inspected `public`, `auth`, `extensions` schemas | Limits normal-schema shadowing. Doesn't remove temporary-schema resolution or unknown schema/extension concerns |
| Database TEMP rights | `anon`, `authenticated`, `service_role` have TEMP | A code-level shadowing review is required. TEMP right alone does **not** prove an exploitable function |
| Role RLS bypass | `postgres` and `service_role` show BYPASSRLS; `anon` and `authenticated` do not | Do not use service-role keys in untrusted clients; review definer internals and least-privilege ownership, audit exception register |
| Effective grants | 0 selected functions anonymously callable; 0 of seven trusted-only authenticated-callable; all selected service-role executable | **Metadata guard baseline PASS** only. This is **not** GoTrue session validation, nested RPC/data leakage review or production privilege parity |

**Source spot-check (pending migration, not currently applied):** The checked-in E6H `20261011233000_operations_independent_case_review.sql` replaces `has_operations_case_scope` and `has_operations_clearance_scope`. Those two definitions call `auth.uid()` and use schema-qualified `public.` table/function references in the inspected SQL, including applicant exclusion and reviewer independence checks. Both still declare `search_path=public,auth`; the other selected privileged functions and temporary-type resolution require more source analysis. The shared local DB is still at earlier pre-E6H definitions. A two-function spot-check is **not** a full SECURITY DEFINER review.

**Engineering stop/go:** Continue to inspect checked-in SQL function bodies (including schema-qualified references, temporary-table/type lookups, dynamic EXECUTE, session/JWT identity trust, privilege chain and referenced table RLS), and compare **real exact owner and grant metadata** in an independently authorised, backed-up stage. Do not assert that the missing `pg_temp` suffix is a confirmed exploit. Treat an accidental unsafe function as a targeted source fix **only after reproducing it in isolation**, with regression and rollback plan.

The E6K public-disclosure privacy review is a **separate open security task**: eligible marketplace rows still expose all 18 provider-profile and 23 service columns to `anon`, including address/coordinates/metadata. No blanket RLS/grant revocation now, because existing Client and nested REST discovery queries depend on the current contract. See `docs/E6K_PUBLIC_MARKETPLACE_RLS_AND_PRIVACY_BOUNDARY_20261012.md`.

## 2. G1–G10 work runs alongside E6L, but approvals are independent

The **authoritative human-gate definition remains** `docs/E6G_FORMAL_ACCEPTANCE_RUNBOOK_20261011.md`. The table below is a **work/evidence preparation queue**, not an alternative signed runbook, delegation, approval, consent or bypass.

| Gate | Can prepare during E6L | Independent evidence/actor needed before PASS | Status |
| --- | --- | --- | --- |
| **G1 HR identity** | Staff-role/expiry and delegation reference template | Employer/HR verifies *actual* staff authority and dates | **BLOCKED** |
| **G2 two-person provisioning** | Request/approve/deny/revoke case matrix; synthetic tests | Different authorised requester and approver witness signed delegated scope | **BLOCKED** |
| **G3 trusted bootstrap** | Custody/break-glass inventory and owner-grant findings | Security lead + compliance owner sign initial bootstrap, key custody/exception log | **BLOCKED** |
| **G4 maintained geography** | Country/province source-reference worksheet, expiry/check protocol | Geography steward + country legal officer attest dated current ISO OBP codes with authorised corroboration | **BLOCKED** |
| **G5 regulated categories** | Service-ID/family mapping and risk checklist | Operations and sector legal owner approve specific, current restricted-service categories | **BLOCKED** |
| **G6 related parties** | Recusal matrix with false-accept/false-deny cases | Independent ethics/COI and beneficial-owner screening reference; no self-approval | **BLOCKED** |
| **G7 actual GoTrue + REST** | Detailed role and direct-bypass acceptance matrix, browser/HTTP check plan | Separate real authorised stage test identities and independent Security/Operations QA witnesses | **BLOCKED** |
| **G8 independent RLS/RPC review** | This catalog inventory, E6J/E6K RLS exposure records, negative tests and exceptions register | Independent application-security owner validates effective owner/grant, untrusted REST, temp lookup, forced JWT, source/function and privacy boundaries | **BLOCKED** |
| **G9 recovery/offboarding** | Backup/rollback/restore/runbook and key-rotation proof checklist | Security/DR owners witness isolated restore, revoke/refresh and audit integrity | **BLOCKED** |
| **G10 independent release** | Consolidated links, defects, risk and no-go register | Owner + independent security/compliance signatures **after** all other gates | **BLOCKED** |

Never record government IDs, real applicant records, private security investigations, screenshots with tokens, keys or sensitive legal material in Git. Put only safe, opaque attestation reference IDs and digests in the eventual approval register; protected source evidence stays separately governed.

## 3. Authenticated positive and negative acceptance matrix (PLANNED, not run)

Future dedicated test stage must establish separate human-authorised synthetic test users by a reversible written process and backup; **no accounts may be created yet**.

| Principal/session | Must be allowed | Must be denied; test direct PostgREST/RPC AND the app |
| --- | --- | --- |
| `anon` | Approved verified/active public catalogue projections only | Cases, duties, identity data, service status updates, trusted RPCs, non-public provider metadata |
| Applicant A vs Applicant B | Own staged intake state and permitted metadata | B's case/evidence/clearance, privileged duty grant, final approval |
| Provider A vs Provider B | Own authorised draft listings | B's edits; own activation/verification override |
| Legacy global admin (no E6 grant) | Only explicitly documented legacy authorised actions | Country-scoped duty/case clearance purely through `is_admin` |
| PG/Morobe/trades reviewer | Independently approved matching case duties | AU or wrong province/family, pending/revoked duty, own case, conflict, evidence officer powers |
| Evidence officer | Appropriate scoped evidence *planning metadata* | Case adjudication, unapproved file ingestion and cross-case contents |
| Safety investigator | Lawful scoped pause/read after approved linkage | Self-issued clearance, own conflicted case, issuance, unrelated vendor |
| Separate duty requester / approver | Propose pending grant / independent approve or reject | Self approval, grant before approval, unrelated country approval |
| Revoked/expired officer | No E6 privileges after duty removal | Cached UI and direct API must fail closed immediately according to approved revocation rules |
| Forged/malformed service-role JWT | Nothing beyond standard anonymous failure | Service-role RPC, direct table writes or enumeration |

**G7 positive/negative cases require genuine GoTrue sign-ins**, browser session proof, independently witnessed distinct personas and current scoped test records. Existing **23/23 synthetic signed-JWT HTTP negatives** do not pass G7. E6H 106/106 synthetic pgTAP tests and E6K 181/181 isolated SQL likewise do not certify real roles.

## 4. Dedicated staging authorisation prerequisites (NO EXECUTION)

1. Independent owner approves a **new, private, isolated and backed-up staging environment**, clear scope and role/persona retention. Do not repurpose the shared `supabase_db_wantok-service`.
2. Record role/owner/ACL parity proof; include definer ownership, default PUBLIC EXECUTE, CREATE/TEMP rights, role memberships, RLS policies and `pg_temp` behaviour. This E6L catalogue is a reference, **not parity proof**.
3. Security custodian approves short-lived test account creation and revocation protocol and isolated API secrets; nobody pastes tokens or real personal ID evidence into this repo/chat log.
4. Witnesses approve an empty initial/terminal test-identity ledger, migration order, transaction rollback, backup integrity/checksum, dedicated port and no outbound access to production. No signing-in as real customers.
5. Execute positive/negative Web, PostgREST, role-expiry/recusal and admin legacy cases; record only minimal redacted evidence in secure location.
6. Prepare an independent exception register; security/HR/legal/DR owners sign their own outcomes; **G10 cannot pass while any mandatory gate is missing**.

## 5. Local regression results (12 October 2026)

- E6L catalog `npm.cmd run test:e6:function-trust-local`: **catalog_controls_pass=true**, 19 selected functions, 0 anon EXECUTE, 0 authenticated EXECUTE on seven trusted-only routines; search-path/owner findings **REVIEW OPEN**. Script `node --check` PASS.
- Existing E6J/E6K catalog inventories: baseline reads PASS, remaining public-column exposure and temp-schema findings clearly labelled **REVIEW REQUIRED**.
- E6H + four T2.4 pending migrations in disconnected disposable staging: **181/181** pgTAP tests PASS (nine suites 051/052/056/057/058/090–093), test fixture rollback, source DB unchanged and container removed. *Technical tests are compatibility regressions only; T2.4 stays paused.*
- Unchanged main-repository local synthetic-JWT HTTP negative boundaries **23/23 PASS**; E6 independence **106/106 PASS**; evidence scanner **101/101 PASS**.
- Detached E6L Flutter `scripts/flutter/check.ps1` exit **0**: **7/7 static analyses clean**, **132/132 Client, 43/43 Operations, 38/38 Technical** widget tests PASS. No Flutter app code changed.
- Shared local SQL runner deliberately not declared PASS: five source migrations remain absent from persistent local migration ledger. No shared or production migration performed.
- This is **source/isolated QA PASS** only, not genuine GoTrue positive sessions, independent witnessed G7/G8 or formal release approval.

## 6. Workstream states / explicit boundaries

- **P0 E-series remains ACTIVE**, E6L read-only catalogue and acceptance prep progress is independent of G1–G10 sign-offs.
- **G1–G10 remain BLOCKED**. They can be prepared concurrently, **not automatically passed concurrently**. E7+/activation/identity evidence/payments remain restricted.
- **P1 CX1 remains queued** under current owner programme sequence; safe non-mutating CX1 acceptance may follow the E-series engineering checkpoint while formal human E6 gates remain blocked.
- **P2 T2.4 remains PAUSED**. Existing technical source/QA remains preserved, no workers, collector or destructive Technical command started.
