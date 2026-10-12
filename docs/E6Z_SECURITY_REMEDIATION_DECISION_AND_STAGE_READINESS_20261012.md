# E6Z — Security Remediation Decision and Independently Gated Staging Pack

**12 October 2026 PNG | EAGLT02 | `feature/flutter-platform-v1`**
**Disposition:** Source-only G8 decision preparation. NOT a security acceptance, authorisation, new migration or production release. E-series ACTIVE; CX1 QUEUED; T2.4 PAUSED.

## Executive decision

**Do not change the shared local database, PostgREST, worker services or production at this checkpoint.** E6X and E6Y already established a persistent local SQL EXECUTE exposure for both internal writers plus more general future-object default privilege risks. The evidence is strong enough to demand independent priority review, but not to claim a live external exploit or a safe one-step bulk REVOKE. E6Z makes the open decisions, dependencies and owners explicit.

Machine-readable **blocked decision register:** `docs/E6Z_REMEDIATION_DECISION_REGISTER_20261012.json`.
Source-only fail-closed validator: `node scripts/qa/e6z-decision-pack-check.mjs`; tests `node --test scripts/qa/e6z-decision-pack-check.test.mjs`. Validation cannot certify a human signature; it deliberately rejects fabricated staging/production authorisation and missing blockers.

## Priority and safe remediation sequence

| Decision | Evidence at EAGLT02 | Scope and impact | Required human review |
| --- | --- | --- | --- |
| **E6O-01 P0 — existing writers** | `write_audit_event` and `enqueue_notification` both SQL EXECUTE-granted to `anon` and `authenticated`. Prior disconnected test reproduced a synthetic anonymous audit write before the source correction; after correction, service audit survived | **Existing function ACL**. Risk to audit authenticity, notifications and authorised nested caller/worker continuity | Security + Operations + DR; exact owner/ACL-equivalent stage, then G7-23/29/30/31 |
| **E6Z-T01 P0 — future table grants** | New `postgres`-created `public` table defaults include 16 entries to client roles, including 2 `TRUNCATE` entries | **Future objects only**. PostgreSQL `TRUNCATE` is **not governed by RLS**. Determine need for grants and restore paths before any corrective `ALTER DEFAULT PRIVILEGES` | Security + DBA + Operations |
| **E6Z-F01 P1 — future function grants** | 2 explicit `EXECUTE` default entries to client roles for future `postgres`-created public functions | Future created functions; not a retrofit to installed functions. Blanket revoke may break legitimate RPC discovery/authorised routes | Security + Architecture + Operations |
| **E6Z-S01 P1 — future sequence grants** | 6 future-sequence privilege entries to client roles | Evaluate nextval/default id generation, identity columns, USAGE/SELECT/UPDATE paths | Security + DBA + Operations |
| **E6Z-R01 P0 — API/RPC surface** | 13 selected non-trigger functions have untrusted SQL EXECUTE under checked-in exposed `public` schema; one trigger-return function is not an ordinary RPC | These are *review candidates* only, not proven running API routes or unauthorised successful calls | Security + Privacy + Operations, real PostgREST and GoTrue witnesses |
| **E6S-D1-D5 P0 — privacy decisions** | Independent role-helper/metadata disclosure choices unsupplied | Cross-person role disclosure and provider-public fields; keep Technical T2.4 PAUSED | Privacy + Legal + Security |

**PostgreSQL reference:** [ALTER DEFAULT PRIVILEGES](https://www.postgresql.org/docs/current/sql-alterdefaultprivileges.html) confirms that defaults affect future objects, and that per-schema defaults cannot remove a broader global default grant. [Row Security Policies](https://www.postgresql.org/docs/current/ddl-rowsecurity.html) confirms `TRUNCATE` is not subject to RLS. Evaluate both GLOBAL and per-schema default ACLs and the creating role before drafting SQL. E6Y's owner/schema-specific results must not be interpreted as a whole-instance policy.

## Proposed staged decision process — NOT EXECUTED

1. **Authorise target and owners separately.** Product owner supplies exact, isolated dedicated staging identity and scope. Identify security reviewer, DBA, Operations representative, privacy and DR; verify independent duties/credentials. Do not create trust accounts merely to pass QA.
2. **Baseline and restore.** Signed backup and observed restore, migration ledger, exact PostgreSQL engine/extensions, function-definition/owner/ACL/search-path parity, role memberships, effective `PUBLIC`/role privileges and table/column/RLS policies. Use E6X metadata comparator, but **metadata equality never equals authorised staging acceptance**.
3. **Decide change packages separately.** Existing two-writer source-only E6O REVOKE is one candidate. Future object default-privilege policy must be a **different, reviewed reversible migration**, with global-versus-per-schema treatment. No blanket grants/REVOKEs for Technical T2.4 or unrelated roles.
4. **Positive/negative witness.** Real identities from separately approved GoTrue, effective PostgREST exposed schema and route/parameter matching, unauthorised direct audit/notification denial, correct authorised nested operations auditing, worker idempotency/queue delivery, and no unwanted side effects. Use only test-safe accounts/objects and reversible stage fixtures.
5. **Fail closed and record.** Stop on owner or grant drift, missing independent witness, missing backup, audit loss, wrong-row access, unexpected worker behaviour, or legal/privacy uncertainty. Store sensitive evidence privately with immutable hashes, independent signatures, clean-up and rollback confirmation. Do not include private metadata or JWTs in GitHub.
6. **Independent G8/go-no-go.** Security + Operations + relevant Privacy/DR signatories must decide. G1–G10 and E7+/production remain independently sealed.

## Non-mutating verification limits

The current source `20261012152000_e6_shared_internal_rpc_execute_boundary.sql` contains exactly two function-specific `REVOKE ALL ... FROM PUBLIC, anon, authenticated` statements with trusted `service_role` grants. E6Z checks those clauses **as source text only**. It does not validate actual stage privileges, worker fulfilment, or production permissions. Previous `--no-owner --no-acl` disconnected stage is not role-equivalent to the persistent local DB.

The machine-readable register contains **6 findings** and **8 external prerequisites**, all blocked or requiring review, no signatories assigned or approvals fabricated. E6Z validator refuses to accept `productionApproved:true`, staged authorisation, completed G7 or D1–D5 approvals. **G7 31/31 NOT EXECUTED, G1–G10 0/10 APPROVED, privacy D1–D5 NOT SUPPLIED.**

## Safe checkpoint and next track

**E6Z QA verified on EAGLT02:** corrected synthetic negative-case harness **12/12 PASS**, including genuine altered-pack mutation rather than merely rejecting primitive inputs; source-only decision register validator PASS and exact E6O source clauses present. Read-only E6V/E6W prior source/catalogue checks PASS. Disconnected seven-proposed-migration SQL **301/301 assertions across 16 suites PASS**, fixture rollback + isolated container removal; persistent shared DB unchanged. Synthetic JWT HTTP negatives **23/23 PASS**, E6 independence **106/106 PASS**, E6S privacy source/local validators PASS, evidence scanner **101/101 PASS**. Fresh detached Flutter from exact prior committed E6Y source `538acc3`: **7 clean analyses**, Client **132/132**, Operations **43/43**, Technical **38/38** widget tests PASS (exit 0). No Flutter app source changed. Shared combined `npm run db:test` is **not claimed green** while pending migrations remain unapplied.

Source-only E6Z tooling is additive and does not change Flutter/T2.4 source, database migrations or APIs. The full private stage evidence and SQL catalogues remain ignored in `.wantok/` on EAGLT02. Record SQL, auth, evidence and fresh Flutter regression outcomes separately as automated engineering PASS, not human acceptance. When E safe preparation is exhausted, the existing integrated plan directs **non-mutating CX1 work** while E6 remains externally BLOCKED. No E7+/payments/provider activation/production work is authorised.
