# E6 ↔ T2.4 shared-branch coordination and handover

**Owner request:** 12 October 2026 (PNG) — prevent E6 Operations acceptance work from clashing with parallel Technical Control T2.4. Only EAGLT02 may be used for project development. This protocol does not grant production, remote VM, real KYC or payment authority.

## Machine-readable handover marker

- **T24_HANDOFF_STATUS: OWNER_DIRECTED_T24_CONTINUATION (E6 NOT TRANSFERRED)**
- **T24_IMPLEMENTATION_OWNER: THIS_T24_CONTINUATION_RUN**
- **E6_SHARED_BRANCH_WRITES: PAUSED_EXCEPT_COORDINATION**
- **T24_HANDOFF_ACCEPTED_BY_E6: NO**
- **LAST_VERIFIED_IMPLEMENTATION_COMMIT: 0250bf9fa2b60b3bccf052f0d1f9ec262fd180cf**

**Do not treat this file as a lock enforced by Git or an acknowledgement from another ChatGPT session.** It records the user's coordination instruction. The user has now explicitly supplied the prior T2.4 handover and directed this run to continue T2.4. This is not confirmation that a separate ChatGPT session has stopped; the previous run must not resume shared branch writes without a new owner-coordinated handover.

## Current division of ownership

| Area | Current write owner | E6 boundary |
| --- | --- | --- |
| `apps/wantok_tech/`, `packages/wantok_api/` Technical Control observability, technical RPCs, `scripts/qa/t24-*` | **Current owner-directed T2.4 continuation** | E6 read-only QA; no edits to T2.4-owned paths until future handover |
| `supabase/migrations/20261011240000_*`, `...241000_*`, `...242000_*`, `...243000_*`, tests 090–093 | **Current owner-directed T2.4 continuation** | Never apply to shared Supabase or rewrite without coordinated ownership |
| E6 case/RLS/provisioning security logic (migrations <= `20261011233000`), `supabase/tests/051`–`057` and E6 acceptance documents | **E6 stream** | E6 may review isolated detached snapshots; no direct shared branch writes while T2.4 active |
| `docs/HANDOVER.md`, `docs/ROADMAP.md`, `docs/ROADMAP_FILLERS.md`, `AGENTS.md`, `package.json`, common Flutter packages and test/build scripts | **SHARED — SERIALISE** | Only one writer/checkpoint at a time; always re-read head, staged diff and remote immediately before commit/push |
| Shared local Supabase database, schema migrations, auth users, server keys, releases | **NO unilateral owner** | Schema remains unchanged; any apply needs separately authorised backup/staging plan and cross-stream acceptance |

The shared `feature/flutter-platform-v1` branch is used by both streams. Two sessions working on the same branch are **not isolated**, even if they edit different files. Neither should automatically stash, reset, cherry-pick or overwrite another session's changes. The pre-existing `supabase/snippets/` is untracked and must not be added, deleted or modified.

## Safe collaboration while T2.4 is ACTIVE

1. **T2.4 remains the implementation owner.** E6 does not begin T2.4 code, edit shared files, migrate shared Supabase, or push the common feature branch while T2.4 may be making changes. E6 may inspect `git status`, commits, docs and perform non-writing tests in independently detached worktrees or disposable Docker containers.
2. T2.4 starts sessions by reading `AGENTS.md`, this protocol and existing handover files. If unexpected tracked edits, a lock owned by another run, uncommitted work or a remote head mismatch appears, stop the write/checkpoint until reconciled.
3. Any necessary cross-stream SQL compatibility test uses a **disposable network-disabled database** and the safe `npm.cmd run test:e6:crossstream-local` script; it does not apply pending migrations to the shared database. T2.4 independently owns `scripts/qa/t24-isolated-staging.ps1`.
4. T2.4 can commit and push scoped code after its standard validations. E6 should not push unrelated work or amend the same handover/roadmap entries concurrently.
5. Git cannot message or stop another ChatGPT conversation. The supplied T2.4 handover authorises current local work; the prior session's stop is not independently witnessed. Do not run two T2.4 writers on this branch at once.

## T2.4 owner handover procedure

**Do not update this marker merely because tests pass or no process is currently visible.** When T2.4 finishes its current agreed code slice or explicitly pauses:

1. T2.4 finishes/commits/pushes the scoped source changes and independent QA evidence; reports **exact local and remote commit equality**, tracked working tree clean, any pending untracked paths and new migrations.
2. T2.4 writes a signed-by-workstream, non-personal **handover note** in this file with exact Git SHA, completed scope, failing/skipped tests, new migrations, still-unapplied schema, open security issues, rollback plan and outstanding jobs. Do not insert credentials, staff identity or private evidence.
3. T2.4 changes marker to **`T24_HANDOFF_STATUS: READY_FOR_TRANSFER`** and **`T24_IMPLEMENTATION_OWNER: PAUSED_FOR_HANDOFF`**, commits/pushes that note, and **stops writing** to the common branch until the transfer is acknowledged.
4. Before takeover, E6 verifies the marker, current Git SHA/remote, clean status, no concurrent T2.4 writing, any running tools, compatibility against E6 code, and migration ordering. If conflicts are found, mark **BLOCKED** and do not take over or apply schema changes.
5. Only after this evidence and a clear user-approved transfer may E6 change marker to **`T24_HANDOFF_STATUS: TRANSFERRED_TO_E6`**, **`T24_HANDOFF_ACCEPTED_BY_E6: YES`**, and begin T2.4 source coding. If the T2.4 owner resumes, coordinate a fresh ownership transfer first.

**Handover evidence** (T2.4 owner fills only when truly ready; not pre-signed):

- `T24_HANDOFF_COMMIT:` PENDING
- `T24_SOURCE_QA:` PENDING
- `T24_OPEN_ISSUES:` PENDING
- `T24_PENDING_MIGRATIONS:` 20261011240000, 20261011241000, 20261011242000, 20261011243000
- `T24_WRITER_STOP_CONFIRMED:` NO
- `T24_HANDOFF_REQUESTED_BY:` Owner-provided T2.4 handover, 12 October 2026

## Baseline as of checkpoint (not a handover)

- Latest T2.4E implementation commit `0250bf9fa2b60b3bccf052f0d1f9ec262fd180cf` adds central log-source readiness without connected collectors, while preserving scoped Technical Logs, Messaging queue, Technical Activity, and E6I.
- T2.4 isolated stage: four T2.4 migrations and **58/58 pgTAP assertions**. Integrated E6I disposable stage: E6H and all three T2.4 migrations, **145/145 pgTAP assertions** across 7 tests.
- Clean Flutter QA at E6I source checkpoint: 7 analysis targets, 132 Client, 43 Operations, 38 Technical widget tests PASS.
- The shared local Supabase still lacks E6H and four T2.4 pending migrations; shared full SQL suite is **not green** on unmigrated DB.
- **T2.4 remains IN PROGRESS**, including secure central logs, verified worker liveness, read-only monitoring provenance, real signed-in staging, exact role/ACL/owner fidelity and approved job-action governance. E6 formal gates G1–G10 remain open. Both prohibit online VM, service activation, KYC evidence, payments and production release.

## Takeover check rule

The owner directly authorised **T2.4 continuing in this run** by providing the prior handover notes and asking to proceed. This does **not** transfer T2.4 to the E6 workstream and does not prove the previous chat is stopped. Any later E6 takeover requires T2.4 `READY_FOR_TRANSFER`, stopped-writer evidence and matching Git commits; the other T2.4 chat must not write in parallel.
