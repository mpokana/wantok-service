# E6V — Internal Writer Dependency Review and G8 Stage Compatibility Preparation

**Checkpoint:** 12 October 2026 PNG | **Branch:** `feature/flutter-platform-v1` | **Machine:** EAGLT02 only
**Disposition:** Source-only engineering review. **NO** shared-database or production changes; **NO** human G1–G10 approvals; Technical T2.4 still paused.

## Purpose and scope

E6T and E6U proved, in disconnected rollback-only SQL fixtures, that a synthetic anonymous role could call `public.write_audit_event` under reconstructed pre-fix permissions and that the proposed E6O restriction denies untrusted direct calls while preserving one synthetic `service_role` audit write. This does **not** establish live GoTrue/PostgREST reachability, real worker compatibility or stage/production parity.

E6V adds `scripts/qa/e6v-internal-writer-dependency-map.mjs`: a source-only historical scan of `supabase/migrations/*.sql`, `apps/` and `packages/`. It reads neither database rows nor function bodies from the running database; it never sends HTTP requests or modifies permissions. Run from repository root: `node scripts/qa/e6v-internal-writer-dependency-map.mjs`.

## Results observed on the checked-in E6U source

| Evidence | Observed result |
| --- | ---: |
| Checked migration files | 77 |
| Historical SQL migration files naming either writer | 9 |
| `write_audit_event` declarations | 1 |
| Historical direct SQL call candidates to `write_audit_event` | **16** |
| `enqueue_notification` declarations | 1 |
| Historical direct SQL call candidates to `enqueue_notification` | **0** |
| Named writer references in scanned app JS/TS/Dart sources | **0** |
| Historical ACL line references for each writer | 4 each |
| Checked-in E6O corrective migration | Present; **not deployed** |

The 16 audit-writer calls occur in historical privileged routines covering the provider/booking status-change trigger, role administration, Technical configuration and access, public service switching, branding and category editing. Several historical definitions of the same function appear across migrations. **These are lexical occurrences, not 16 distinct currently installed callers.** The nearest enclosing function headings reported by the scanner are tentative. Some functions run as SECURITY DEFINER, so revoking direct EXECUTE from `anon`/`authenticated` may preserve an authorised nested call under the function owner's permissions; **that is a hypothesis, not a witnessed compatibility PASS**.

No tracked source call to `enqueue_notification` was identified in this scan. That neither proves the function is unused nor validates queue/outbox delivery: external processes, generated clients and dynamic calls fall outside the lexical scan.

## Security interpretation

1. **E6O-01 OPEN / PRIORITY:** Local persistent DB still has untrusted effective SQL EXECUTE on the two internal writers. E6O correction exists only in unapplied source; local SQL reproduction is not evidence of an external exploit or production breach.
2. **Nested audit integrity:** The candidate `audit_status_change` trigger and Operations/Technical/branding/category paths need distinct positive and negative authorised-stage tests, especially when a caller is a definer with BYPASSRLS owner. Do not grant wider access simply to make nested tests pass.
3. **Notification continuity:** The E6U `066` positive only tested a fake audit write. Real notification enqueue, idempotency, outbox observation and delivery status need separate approved worker witnesses.
4. **Role/ACL parity:** The disposable `pg_restore --no-owner --no-acl` harness is NOT an exact stage replica. Compare exact owner, search path, role membership, EXECUTE and RLS effects, schema exposure, default privileges and any PostgREST route before/after.
5. **E6S privacy D1–D5, E6K provider-field exposure, E6R role metadata and E6O-02 Technical helper** all remain independently blocked. Do not change paused T2.4 SQL or expand public RPCs.

## Dedicated-stage witness additions — PLANNED, NOT EXECUTED

On **separately approved and backed-up** owner/ACL-equivalent staging, with independent Security/Operations witnesses and test identities, run the existing G7-23, G7-29 and G7-30 plans. **Proposed G7-31** additionally compares a restricted direct writer call against a properly authorised nested `audit_status_change` or selected Operations role/category action, confirms the right attributable audit record, and proves wrong-role requests have no audit or business side-effects. Include a reversible controlled notification enqueue/outbox path and cleanup; do not activate real workers/payment/provider accounts merely for QA.

**Stop:** any role/owner ACL mismatch, worker regression, successful untrusted direct writer call, missing session/witness/backup, data disclosure or unauthorised Technical scope. Production remains `productionApproved:false`.

## QA and next engineering actions

The new scanner is deliberately read-only/source-only and asserts both writer definitions and presence of the unapplied E6O corrective REVOKE clauses. **Verification completed on EAGLT02:** `node --check` and E6V source scan PASS; `git diff --cached --check` clean after fixing a Markdown whitespace issue; E6U PostgreSQL READ ONLY catalogue PASS (10/10 selected definers, both writers still untrusted-callable); disconnected SQL stage **301/301 over 16 suites PASS**, fixtures rollback/container removed; synthetic signed-JWT negative HTTP **23/23 PASS**; independent-case rollback checks **106/106 PASS**; E6S proposed privacy-contract source and read-only catalog PASS; evidence scanner **101/101 PASS**. A clean detached E6U-source Flutter QA worktree passed **7 clean static analyses, 132 Client + 43 Operations + 38 Technical widget tests, process exit 0**. The first main-checkout Flutter run hit a missing test-shell `ProgramFiles(x86)` variable; a retrial hit a pre-existing locked Technical `build/unit_test_assets` directory. Neither indicates an app-code failure: a fresh detached checkout succeeded without altering those main-build assets. **No Flutter app source was changed in E6V.**

**Next:** Map the *latest* installed function definitions and nested caller privileges in a dedicated privilege-parity environment; prepare concrete G7-31 role/route/owner-matrix evidence, not a fake sign-off. G1–G10 remains **0/10 signed**; E active, CX1 queued, T2.4 paused, E7+/production sealed.
