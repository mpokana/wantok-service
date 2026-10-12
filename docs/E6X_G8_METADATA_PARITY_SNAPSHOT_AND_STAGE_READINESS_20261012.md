# E6X — G8 Read-Only Privilege Baseline and Fail-Closed Snapshot Comparator

**Prepared:** 12 October 2026 PNG | **Authorised device:** EAGLT02 | **Source branch:** `feature/flutter-platform-v1`
**Classification:** Local PostgreSQL metadata-only engineering evidence. **NO** database migration, production change, stage authorisation, credentials, user-account creation, independent witness or G1–G10 sign-off.

## Scope and controls

E6X follows E6W's 12 latest-by-name audit-writer candidate routines plus the two privileged shared internal writers. It adds `scripts/qa/e6x-g8-parity-snapshot.mjs` and `scripts/qa/e6x-g8-parity-snapshot.test.mjs`. Local mode takes one `BEGIN TRANSACTION READ ONLY` PostgreSQL **catalogue-only** snapshot on `supabase_db_wantok-service`. It does not read application table rows, auth identities, credentials or SQL function source bodies. It returns stable function-definition MD5 digests for *comparison only*, not proof of security, code provenance or tamper-resistance.

The snapshot includes **all selected exact installed function signatures**, owners/role flags, `SECURITY DEFINER`, search settings, explicit and effective SQL EXECUTE ACLs, argument default counts, metadata hashes of function definitions, role memberships, schema USAGE ACLs, PostgreSQL version and extension versions, **all public base-table** RLS/FORCE RLS/table and column grant metadata, **all public RLS policies** with hashed `USING`/`WITH CHECK` expressions, and PostgreSQL default-privilege grants.

**Sensitive operational metadata:** Keep full JSON snapshots in the ignored `.wantok/` private working area and any future independently authorised restricted evidence store. Do **not** push snapshots, raw SQL bodies, data exports, roles identifying real people, secrets or credentials to GitHub. Baseline captures are not cryptographic evidence of who ran the command or when; a trustworthy future stage process must independently attest environment, capture date, Git SHA, container image, database migration ledger, signer and storage integrity.

## Repeatable E6X commands on EAGLT02

From repository root:

- `node scripts/qa/e6x-g8-parity-snapshot.mjs --local` — JSON to standard output; redirect to an ignored local file such as `.wantok/e6x-metadata-local.json`. The script never writes the database.
- `node --test scripts/qa/e6x-g8-parity-snapshot.test.mjs` — synthetic comparator/unit tests, no PostgreSQL required.
- `node scripts/qa/e6x-g8-parity-snapshot.mjs --compare .wantok/e6x-metadata-local.json .wantok/e6x-metadata-local.json` — **self-comparison only**, confirms parser and checksum integrity but is **NOT** staging parity. The actual future `--compare <baseline> <candidate>` requires independent authenticated source attestations and an approved matching collector at the stage environment.

The comparison verifies a SHA-256 metadata JSON fingerprint, required fields, minimum expected catalogue coverage, duplicate function signatures and structural differences, and produces useful drift paths. **Identical metadata returns exit 0; any detected metadata drift returns exit 3; invalid, incomplete or tampered input returns exit 1.** It always reports `human_G8_accepted:false`, `stage_provenance_verified:false`, `productionApproved:false`. Matching JSON is not an authorisation or real security acceptance.

## Current local EAGLT02 snapshot (NOT a production or stage baseline)

| Read-only catalogue fact | Observed |
| --- | ---: |
| PostgreSQL | **17.11** |
| Exact selected privileged function signatures | **14** |
| Selected functions with `anon` SQL EXECUTE | **14/14** |
| Selected functions with `authenticated` SQL EXECUTE | **14/14** |
| Selected functions with SQL PUBLIC execute | **1/14**, the trigger-return case needs reviewer treatment |
| Public base tables | **93** |
| Public tables with RLS enabled | **93/93** |
| Public tables with FORCE RLS | **0** |
| Public RLS policies | **117** |
| Extensions | **6** |
| Selected system roles | **5** |
| Role membership records involving selected roles | **10** |
| Default-privilege catalogue entries | **27** |

Local snapshot SHA-256 metadata fingerprint (unattested):
`97f56f9cd16e8b7aa69b2aed90f9a0c3d019a77ad50ed68cad766791419da113`.

**Critical interpretation:** `anon` SQL EXECUTE on a protected definer does not prove the internal function authorises a request or that PostgREST exposes a usable route. `audit_status_change()` returns `trigger`, so do not count it as an ordinary callable REST RPC. `SECURITY DEFINER` under a BYPASSRLS owner still needs independent caller-bound authorisation and nested side-effect review. Both `write_audit_event` and `enqueue_notification` retain untrusted direct EXECUTE in the persistent local DB — **E6O-01 remains OPEN**. The proposed E6O correction is **unapplied**.

## Why the existing disposable SQL stage cannot claim parity

The current disconnected `e6-crossstream-isolated-staging.ps1` restores metadata using `pg_restore --no-owner --no-acl` plus test-specific reconstructed grants. It deliberately loses original owner, ACL/default-privilege and role membership fidelity. Its 301/301 pgTAP PASS demonstrates selected logic in a controlled synthetic fixture **only**, not strict ACL/RLS parity, real GoTrue sessions, REST publication or notification delivery. Do not use a synthetic cloned manifest or copied local JSON to fake stage equivalence.

### Dedicated stage stop/go checklist — all PENDING

| Stage evidence requirement | Current | Independent role |
| --- | --- | --- |
| Explicit scope/authorisation, target system identity and data classification | NOT SUPPLIED | Product owner/Security |
| Backup and restoration verified (hash, rollback, isolation) | NOT SUPPLIED | DR owner |
| Stage PostgreSQL build, extensions and migration ledger provenance | NOT SUPPLIED | Platform operator |
| G8 baseline and stage snapshots from authenticated collectors, reviewed differences | NOT SUPPLIED | Independent application-security reviewer |
| Exact function owner/ACL/default ACL, role memberships and RLS/column grant parity | NOT WITNESSED | Independent G8 reviewer |
| Approved E6O change, legitimate nested audit and notification worker positive path | NOT EXECUTED | Separate Security/Operations QA |
| Genuine separate GoTrue identities, direct PostgREST negatives, revoked-role tests | NOT EXECUTED | Separate Security/Operations QA |
| Privacy D1–D5, E6K public fields, E6R roles and Technical E6O-02 decisions | NOT SUPPLIED | Privacy, Legal, Technical owner |
| Witnessed cleanup/recovery, audit continuity, signed G1–G9 and G10 decision | NOT SUPPLIED | Authorised human signatories |

**Do not apply** E6H/T2.4/E6N/E6O migrations to the persistent shared local DB or production, provision users, enable provider services or conduct privilege-changing browser tests from this checklist. The paused T2.4 module remains unchanged.

## Regression and next continuation

**EAGLT02 test results (validated):** E6X comparator **13/13 synthetic tests PASS**, including metadata equality with no approval, deliberate owner/ACL/RLS-policy/column grant/version/role/default privilege drift, forged checksum, missing field, duplicate function identity and **CLI exit-code enforcement**. E6X `--local` metadata collection PASS with no application data or SQL writes. Existing unchanged E6W source/local scanners and E6V source scan PASS. Disconnected SQL seven pending migrations **301/301 assertions in 16 suites PASS**, all fixtures rollback and isolated container removed; persistent shared DB unchanged. Local synthetic JWT HTTP negative **23/23 PASS**, independent-case rollback **106/106 PASS**, evidence scanner **101/101 PASS**, E6S proposed privacy contract source/read-only local checks PASS. Fresh detached Flutter checkout at exact prior E6W SHA `9934cc8` exited **0** with **seven clean analyses** and Client **132/132**, Operations **43/43**, Technical **38/38** widget tests PASS. E6X introduces no Flutter app source changes. The shared combined `npm run db:test` is **NOT CLAIMED GREEN** because proposed E6H/T2.4/E6N/E6O migrations are not applied to the persistent shared database.

Continue with G8 independent acceptance readiness and non-mutating CX1 groundwork only where explicitly within the programme plan. **G7 real-session cases 31/31 NOT EXECUTED; G1–G10 0/10 approved; D1–D5 not supplied; production false.**
