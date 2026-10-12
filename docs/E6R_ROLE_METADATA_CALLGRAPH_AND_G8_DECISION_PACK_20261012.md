# E6R — Role Metadata Callsite Map and Independent G8 Decision Pack

**Checkpoint:** 12 October 2026 (Papua New Guinea) | Device: **EAGLT02** | Branch: `feature/flutter-platform-v1` | **Scope:** source-only lexical map, local **READ ONLY** pg_catalog verification, disconnected synthetic SQL. **No shared database changes; no approval or production release.**

## 1. Why this review is necessary

Earlier E6O and E6Q checked the privileged role surface and cross-user helper semantics. The currently applied EAGLT02 PostgreSQL database has **152** `public` SECURITY DEFINER routines and `95` callable by `anon` (the larger count is local, not a production claim). A fresh targeted catalog check confirmed the following **eight** helpers are all `postgres`-owned locally, have explicit `search_path=public, auth` but not trailing `pg_temp`, and have effective EXECUTE for **anon, authenticated, and service_role**:

| Role-related helper | Caller/subject implication |
| --- | --- |
| `has_role(text,uuid)` | Checks the role status of **provided subject UUID** |
| `is_admin(uuid)` | Delegates to `has_role('admin', subject)` |
| `is_technical_platform_admin(uuid)` | Delegates to Technical platform role lookup for provided subject |
| `has_platform_permission(text,uuid)` | Computes the specified subject's platform permission |
| `has_technical_permission(text,text,uuid)` | Computes the specified subject's module permission |
| `effective_technical_access_level(text,uuid)` | Returns the specified subject's active module rank |
| `can_access_technical_console(uuid)` | Computes the specified subject's Technical-console access |
| `can_manage_technical_module_access(text,uuid)` | Computes the specified subject's module-management entitlement |

All accept an optional or explicit **subject** argument. These functions can legitimately be used inside other trusted SQL/RLS checks to evaluate a named person; this does not mean an untrusted request should automatically be able to query another person's staff entitlements. **An effective SQL EXECUTE grant is not proof of an actual exposed PostgREST endpoint or data exfiltration over HTTP; those require G7/G8 stage verification.**

## 2. Reproducible source callsite map — cautious interpretation

Run `node scripts/qa/e6-role-helper-callsite-map.mjs` at the repo root. The scanner reads **77 ordered checked-in migrations** without a database connection, and surveys `apps/` and `packages/` source for direct named uses. At this checkpoint it counted **242 lexical migration callsite references** to the eight helpers (after excluding declarations and straightforward privilege DDL); **19** locally matched subject-variable patterns and **one** named Dart client call. The counts include **superseded migration/function versions**, RLS clauses, policy and helper calls, and unresolved/multiline arguments: **they are not 242 unique live functions, not a parsed SQL call graph, and not a vulnerability count**.

Concrete traced examples:

- `packages/wantok_api/lib/src/technical_control_repository.dart` calls `rpc('can_access_technical_console')` **without** a supplied subject UUID; its function defaults to `auth.uid()`. This is the intended caller-relative frontend check. A direct untrusted caller passing a UUID remains a separate question.
- `supabase/migrations/20261006141000_taxi_delegated_booking.sql` `get_taxi_ride_details` checks `public.is_admin(v_user_id)` for ride access; **this specific variable is declared `v_user_id uuid := auth.uid()`**. Do not label it a cross-user role escalation merely because it isn't a literal `auth.uid()` in the call line.
- Helpers inside `supabase/migrations/20261006090000_technical_control_plane.sql` pass `p_user_id` through nested permission calculations by design. If an RPC passes an untrusted supplied target as its own caller identity, that is the danger to audit **per actual consuming function**.
- Source policy expressions using `public.is_admin(auth.uid())` are bound to the real caller in the SQL text; their legal and RLS semantics still need independent parity review. **Do not blanket change the function definitions or revoke them** without checking RLS and legitimate dependent RPCs.

Scanner limitations: lexical regex; section labels are approximate; historical changes are counted; snippets can miss distant caller binding, dynamic SQL, overloaded signatures, policies and function privilege semantics. The output carries source locations for each matched call to allow an independent reviewer to trace the **latest** definition manually.

## 3. New negative/evidence regression — G8-04 is reproduced, NOT closed

`supabase/tests/064_role_helper_anon_disclosure_reproduction.test.sql` **18/18 assertions PASS** in a network-disabled disposable PostgreSQL instance. Synthetic Operations and Technical admin records are inserted inside a `BEGIN ... ROLLBACK` fixture. The test verifies:

1. The eight helpers currently have effective `anon` SQL EXECUTE under restored tested privilege baseline.
2. With `SET LOCAL ROLE anon` and **NULL `auth.uid()`**, direct SQL calls passing another synthetic user's UUID return positive Operations role, Technical platform role and Technical-console entitlement. This is **role-metadata visibility**.
3. Anonymous helper calls without a subject do not confer administrator status. An attempted anonymous `grant_user_role` raises `Authentication required` and the synthetic ordinary target gains **no admin or technical-platform role**.
4. **Fixtures rollback**. The initial regression failed an over-strict test expecting zero roles on a new profile; the test was corrected to account for the automatic `customer` base role and then **18/18 PASS**. This was a test expectation defect, not a shared privilege change.

The full disconnected compatibility suite applies the seven **unapplied** E6H/T2.4B–E/E6N/E6O source migrations to its own network-disabled database, runs **14 files / 286/286 pgTAP assertions**, and removes the container. Four T2.4 migrations are used solely as compatibility fixtures; **T2.4 remains paused**. No production stage, database, schema, role or identity was modified. `--no-owner --no-acl` restoration and selected reconstructed grants mean this is not authoritative production owner/ACL parity.

**Critical:** A successful 064 test is an observation of an OPEN privacy concern, **not a security acceptance PASS**. Real HTTP/direct REST reachability of these helpers, JWT verification, rate limits, exact headers, and whether role metadata disclosure is permissible remain **unwitnessed**.

### E6R complete regression results

- Source-only `npm.cmd run test:e6:role-call-map`: PASS (77 historical migrations / 242 lexical matched references / 19 variable-subject matches / one Dart named use), no database access or modifications.
- New `064` anonymous role-metadata reproduction: **18/18 pgTAP PASS** after correcting expected `customer` base role; the finding remains **G8 OPEN**.
- Disconnected `npm.cmd run test:e6:crossstream-local`: **286/286 pgTAP PASS** across **14** SQL suites and seven prospective source migrations. Fixtures rolled back, `--network none` temporary PostgreSQL removed, shared DB unchanged. This is not full original owner/ACL parity.
- Unchanged main's local signed synthetic JWT HTTP negatives: **23/23 PASS**; E6 case independence **106/106 PASS**; evidence scanner **101/101 PASS**; local full public definer catalogue read-only baseline **152/95 EXECUTE-grant observation**.
- Fresh E6R detached `scripts/flutter/check.ps1` exit **0**: **seven static analyses clean, 132/132 Client, 43/43 Operations and 38/38 Technical widget tests PASS**. No Flutter app source modified.
- **Persistent shared combined SQL test is deliberately not represented as PASS:** seven source migrations are not applied to that database. No real GoTrue human login, external G7 witness, G8 approval or production deployment.

## 4. G8 independent decision request — privacy and compatibility

**Proposed intended policy (requires actual authorised decision):** Ordinary unauthenticated clients should not be able to enumerate other people's staff/Operations/Technical roles. Ordinary signed-in users should receive only caller-appropriate, **self-scoped** access booleans unless there is a documented legal/business necessity and explicit delegated administrator authority. Internal SQL/RLS helpers that evaluate subject IDs may need to remain callable within trusted paths; do not conflate safe internal use with a public API projection.

| Decision question | Options requiring independent review | Evidence before approval |
| --- | --- | --- |
| **D1 — Staff-role sensitivity** | Treat cross-person role/rank as protected internal metadata (preferred proposal), or approve a specific public directory field with lawful basis | Security/privacy+operations owner, legal basis, minimised permitted fields, retention, abuse risk |
| **D2 — API isolation design** | Approved self-only wrappers or trusted/private helper schema; restricted direct grants and service role; stage-proven compatibility | List every direct REST caller, RLS policy invocation, function owner, nested call and default/overloaded signature; rule out policy recursion or broken bookings |
| **D3 — Authentication behaviour** | Reject unrelated-user subject query or return non-revealing response; allow only documented delegated reviewer query | Independently witnessed GoTrue accounts, browser and raw PostgREST positive/negative cases |
| **D4 — Security hardening** | Require `pg_temp` last where safe, least privilege owners and explicit grant policy | Owner/ACL/RLS parity in backed-up stage, replay 286 isolated checks, service-role custody |
| **D5 — Deployment/rollback** | Approve a narrow source migration **only after** D1–D4, or defer with written accepted risk and mitigation schedule | Migration plan, signed diff, backups+restore, role test ledger, independent rollback witness |

**Do not automatically implement a blanket `REVOKE EXECUTE` now.** Function helpers are used by policies and nested routines and may break application paths if moved or narrowed without staged parity and separate owner approval. This G8 pack is an **engineering recommendation awaiting external decision**; there is no signed privacy classification or independent penetration finding.

The earlier **E6O-01** anonymous audit-writer/notification EXECUTE issue is still locally OPEN, with a proposed source-only fix never applied to shared Supabase. **E6O-02** Technical health helper remains for an independent reviewer/Technical owner, and **E6K** public provider-column privacy remains undecided.

## 5. Parallel G1–G10 evidence queue

Controlling source: `docs/E6G_FORMAL_ACCEPTANCE_RUNBOOK_20261011.md`. Updated workboard: `docs/E6G_PARALLEL_ACCEPTANCE_REGISTER_20261012.md`. **All formal G1–G10 BLOCKED, 0/10 approved.**

- **G1–G3** HR authority, distinct provisioner/approver and trusted bootstrap key custody **NOT SUPPLIED**.
- **G4–G6** authoritative maintained ISO jurisdiction/legal service-family map and independent COI/beneficial-owner verification **NOT SUPPLIED**.
- **G7** real-session plan extended to **28 cases**. New G7-27 checks anonymous direct PostgREST role-metadata query and independently approved response contract; G7-28 checks signed-in self-scoped helpers, another user's ID, browser repo and role leakage after mitigation. **All 28 UNEXECUTED/BLOCKED** until separately authorised backed-up staging and independent witnesses.
- **G8** independent application-security/privacy reviewer to decide D1–D5, validate role helper callsite graph, the two shared privileged helper grants and the full 152-function public catalog. Current E6R metadata repro is *not* a signed report.
- **G9–G10** recovery/offboarding and final go/no-go remain **BLOCKED**.

No real accounts, witness signatures, approval dates, credentials or private evidence are stored in Git. Keep attestation references separately approved and opaque.

**Programme status:** E-series ACTIVE; G-series acceptance PREPARATION PARALLEL; CX1 QUEUED; T2.4 PAUSED; E7+/production NOT AUTHORISED.
