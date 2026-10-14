# CX1P — Installed Track permissions metadata and identity-stage gap analysis

**Date:** 14 October 2026 · **Repository baseline:** CX1O `bdecf5f` · **Host:** EAGLT02 only · **Status:** INSTALLED LOCAL CATALOG READ-ONLY PASS; **NO ROLE-EQUIVALENT RESTORE OR G7/G8 APPROVAL**

## Scope

User requested continuation from CX1O. CX1P inspects **seven targeted installed PostgreSQL table definitions/policies/ACL decisions, selected function metadata and selected role flags**, without accessing application data rows or any account identifier/token/secret. The new `scripts/qa/cx1p-track-local-privilege-audit.mjs` executes exactly one `BEGIN TRANSACTION READ ONLY;` / `COMMIT;` PostgreSQL catalogue-only query against the existing authorised local EAGLT02 Supabase Docker instance (`supabase_db_wantok-service`). It produces a **sanitised summary**, not an exported full schema, SQL-function body, account data or privilege backup.

CX1P does not claim owner/ACL parity in an isolated stage. The previous CX1O disconnected synthetic PostgreSQL trial was a useful candidate SQL test but did **not** reproduce installed object owners, grants, actual GoTrue JWTs or PostgREST.

## Actual installed metadata — directly observed

| Control | Installed EAGLT02 finding | Consequence |
| --- | --- | --- |
| PostgreSQL version number | 170011 (17.11) | Installed PostgreSQL matches nominal CX1O major/minor engine |
| Tables | All 7 targeted tables found | `service_bookings`, `service_quotes`, `service_reviews`, `service_categories`, `provider_profiles`, `provider_services`, `provider_resources` |
| Booking table owner | `postgres` | Owner has bypass-RLS flag; this is **not** a claim that clients have that privilege |
| Booking RLS | Enabled, not FORCE | RLS exists but its policy authorisation requires independent review |
| Anonymous booking SELECT | Denied | Anonymous direct table read prevented by table grants in the installed catalog |
| Authenticated booking SELECT | Allowed | Existing account-role row policies must do the remaining filtering |
| Authenticated booking INSERT/UPDATE/DELETE | Table-level queries report false in this audit | Do **not** infer column-specific INSERT capability is absent; earlier migration declares column-level INSERT grants |
| Booking SELECT policies | `service_bookings_read_participants`, `service_bookings_read_open_for_qualified_providers` | Existing source-described customer/provider/admin and qualified-open-request branches are installed |
| Selected booking table columns | 32 | CX1O toy function does not cover full installed projection |
| Selected sensitive authenticated SELECT columns | `beneficiary_email`, `beneficiary_phone`, `destination_address`, `metadata`, `notes`, `origin_address`, `service_address` | Must obtain privacy/field approvals before returning them to a Client |
| `is_admin` helper | Owned by `postgres`; `SECURITY DEFINER`; owner has BYPASSRLS; both `anon` and `authenticated` can call | **Requires independent helper source/ownership/callability review.** Callable helper metadata is NOT proof of an exploitable flaw without body/behaviour testing |
| Candidate CX1O Track function | Not installed | CX1O did not leak its test function into the shared Supabase database |
| Role flags | `anon` and `authenticated`: no BYPASSRLS; `service_role` and `postgres`: BYPASSRLS; `supabase_admin`: superuser+BYPASSRLS | Never use service-role or database administrator credentials in a frontend/generic proxy |
| Total selected policies | 22 across seven audited tables | Not an independently restored policy/privilege equivalence measurement |

**Precision:** `has_table_privilege(..., 'INSERT')` alone may be false while **column-specific** INSERT privileges exist. This inventory is intentionally restricted; do not interpret it as a comprehensive write-capability test.

**Additional read-only network observation:** EAGLT02 TCP port 54321 has listening sockets on `::1` and `::`, indicating an all-interface listener. Actual Tailnet peer reachability and firewall enforcement were **not** independently tested. The existing Tailscale Serve configuration remains limited to the Web roots, GoTrue Auth, exact active categories GET and published-branding read; there is **no private service-bookings route**. Local Auth health returned 200; not a signed actor entitlement test.

## CX1O-versus-installed delta and gating

CX1O modelled a 108-row synthetic fixture and a four-field invoker candidate with locally simulated actor GUC. The installed environment has 32 booking columns, broader real linked relations, original role and function ACLs, actual Supabase JWT issuance configuration, and host-side direct port exposure. **These differences remain unclosed.** The candidate cannot be directly bound to the existing Flutter Track query, which requests nested category/provider/resource/quote/review relations and other fields.

A true role-equivalent stage needs (1) separate authority from owner/Security/DBA/Privacy; (2) schema + owner/ACL + extensions/default privileges + function ownership and search paths represented from an approved backup; (3) verifiable isolated restoration that does not include live personal records without lawful approval; (4) provisioned *separate* GoTrue test users and real JWT lifecycle negatives; (5) real PostgREST own/cross-user/provider/admin/anonymous and embedded-join HTTP cases; (6) reviewed column minimisation, data retention and error/log disclosure; (7) firewall/direct-Tailscale-IP negative testing; and (8) independent G7/G8 acceptance. A user saying **Proceed** authorises this bounded inspection and test preparation, not the above separate delegated sign-offs.

## Reproducibility

```powershell
node scripts/qa/cx1p-track-local-privilege-audit.mjs --local-read-only
node --test scripts/qa/cx1p-track-local-privilege-audit.test.mjs
node scripts/qa/cx1k-tailnet-api-boundary.mjs --local
git diff --check
```

The script requires `--local-read-only` and connects only to the fixed local Docker database container. The synthetic `node --test` suite detects unexpected DML, schema reads/exports, missing READ ONLY transaction, omitted tables, broadened privilege claims and fabricated approvals. The audit only prints metadata and Boolean findings, no actual record values.

## 15 October 2026 resumed verification

EAGLT02 Desktop Commander reconnected after an overnight interruption. The detached CX1P worktree was unchanged; the main checkout still contains unrelated pre-existing business/commission drafts and was left untouched. Docker Desktop was stopped following the reboot and was relaunched using its existing installation and volumes. Supabase Auth health returned HTTP 200. The installed `pg_catalog` read-only inspection repeated successfully, matching the seven-table baseline above without touching application records or roles. Combined CX1K/CX1N/CX1O/CX1P source guards **70/70 PASS**, the five-route CX1K Tailnet Serve scope **PASS**, and the complete isolated Flutter check returned exit code 0: **7/7 analyses clean, Client 135/135, Operations 43/43, Technical 38/38 widget tests passed**. This establishes regression completion but **not** live Track/JWT/role-parity acceptance. No new private route was enabled.

## Programme limits and next decision

**CX1P acceptance is metadata discovery only.** No account creation, database export/restore, SQL migration, role grant, password reset, schema modification, private gateway route, port firewall change, Docker persistent volume change, deployed UI build or production modification was performed. The CX1N ten external gates remain **NOT WITNESSED**, E6 G1–G10 0/10 accepted, G7 31/31 unexecuted, E6O-01 and D1–D5 unresolved, T2.4 paused and production NOT APPROVED.

**Next practical step requires distinct approval:** designate staging authority/Security/DBA/Privacy signatories, an isolated target, written permitted backup handling, and two separately authorised test identities. Until these are approved, work may safely continue with source-only mock PostgREST/JWT contract fixtures and offline negative-test design, but **no real private Track access can be enabled**.
