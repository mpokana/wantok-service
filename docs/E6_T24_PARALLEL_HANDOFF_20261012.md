# Wantok Services — E6/CX1/T2.4 Workstream Handover Status

**Effective 12 October 2026. Superseded predecessor:** the earlier parallel E6/T2.4 owner split in this file. The user subsequently supplied the T2.4 handover and **explicitly directed this conversation to coordinate all three workstreams with E-series and CX1 before T2.4**.

## Current status — owner-directed programme

- **T24_HANDOFF_STATUS: ACCEPTED_IN_SINGLE_CHAT_AND_PAUSED**
- **T24_IMPLEMENTATION_OWNER: SINGLE_CHAT_COORDINATOR_WHEN_RESUMED**
- **T24_WRITES_ALLOWED_NOW: NO**
- **E6_IMPLEMENTATION_OWNER: SINGLE_CHAT_COORDINATOR**
- **E6_WORKSTREAM_STATUS: ACTIVE**
- **CX1_WORKSTREAM_STATUS: QUEUED_AFTER_E6_ENGINEERING**
- **T24_WORKSTREAM_STATUS: PAUSED_UNTIL_E_AND_CX1_PRIORITIES**
- **T24_HANDOFF_ACCEPTED_BY_SINGLE_CHAT: YES_USER_SUPPLIED_NOTES**
- **PARALLEL_CHAT_STOP_INDEPENDENTLY_CONFIRMED: NO**
- **FINAL_T24_COMPLETED_SOURCE_CHECKPOINT: 0250bf9fa2b60b3bccf052f0d1f9ec262fd180cf**
- **SHARED_BRANCH_LAST_RECONCILED: 53a75e2e705275dcc2f98113bc79e37d7491e6ef**

This is an advisory Git-documented handover marker, not a distributed lock. A separate ChatGPT session cannot be stopped by this file; the user should halt other writers. The coordinator must verify local and remote Git HEAD and working-tree status before every checkpoint, and stop on unexpected changes.

## Ownership and sequencing

1. **P0 E-series:** enterprise Operations duties, provisioning, country/category/legal scope, conflict recusal, applicant independence, trusted APIs and acceptance. Proceed with safe E6 engineering and isolated tests; **G1–G10 human/legal/security sign-offs remain BLOCKED** until independently witnessed. Do not call E6 complete, implement E7 or migrate live/shared DB.
2. **P1 CX1:** after the safe E engineering checkpoint, complete signed-in Client Web category-first search/filters/provider detail, Saved/Inbox/Track Refresh and route tests, photographs/editor and Android/HONOR gate; protect saved data and credentials. P0 external blockers remain recorded, not waived by CX1 work.
3. **P2 T2.4:** retain source-completed A–E module diagnostics/logs, queue snapshot, privacy-reduced Technical Activity and central-log **not_connected** readiness. T2.4E at `0250bf9` has 58 isolated SQL assertions; additional real source provenance, worker liveness, exact staging ACL acceptance, job-action governance remain OPEN. **No T2.4 functional work until explicit unpause.**

## Shared branch collision controls

- Git remote `https://github.com/mpokana/wantok-service.git`, branch `feature/flutter-platform-v1`, machine EAGLT02 only. Avoid parallel writers and simultaneous Git operations; before each commit verify branch HEAD, remote SHA, status, scoped staged paths, secrets and ignored artefacts.
- Use independent detached worktrees for new QA/development snapshots, and a serial fast-forward for integration. Do not stash/delete/reset/rebase the other stream's uncommitted changes, overwrite `docs/HANDOVER.md`, `docs/ROADMAP.md`, `docs/ROADMAP_FILLERS.md`, `AGENTS.md`, `package.json` or force-push.
- Preserve existing `supabase/snippets/` untracked material; exclude from commits unless expressly authorised and separately inspected.
- Do not apply E6H or any pending T2.4 migrations to shared local Supabase. Four Technical migrations `20261011240000`, `20261011241000`, `20261011242000`, `20261011243000` and E6H `20261011233000` require controlled coordination in **disposable** staging or separately authorised backed-up real staging.
- T2.4 source QA and E6I tests provide evidence only, not production-equivalent ownership, GoTrue signed-in user sessions, external HR/legal approvals, live app publishing, usable central collector or worker heartbeat.

**Canonical current plan:** `docs/PROGRAM_EXECUTION_PLAN_20261012.md`. Historical T2.4 handover notes supplied by the user are acknowledged as the development baseline, **not** a command to outrank the more recent priority decision.

## Before resuming T2.4

The owner must confirm a switch after P0 engineering and P1 gate, or explicitly change priority. Recheck source, local/remote SHA, all E6/CX1 blockers, migrations, tests and no other writer. Update this marker to `T24_WORKSTREAM_STATUS: ACTIVE` only at that time. Retain E/CX1 release restrictions.
