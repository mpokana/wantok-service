# CX1C — Independent Browser Refresh Witness Contract (Parallel Workstream)

**Prepared:** 13 October 2026 PNG | **Machine:** EAGLT02 | **Detached local source:** `91bd63074cb5ea43fc69944836d8d026a4a50306`
**Worktree:** `D:\Wantok_CX1C_Parallel_Witness_QA_20261013`

**Status:** SOURCE-ONLY ACCEPTANCE READINESS. Six real browser witnesses **NOT EXECUTED**. CX1 live acceptance OPEN. **No production, shared Supabase, Technical T2.4 or E6 G1–G10 approval**.

## Parallel ownership boundary

The CX1B workstream owns EAGLT02 Client static web servers on **:3000 and :3300** and is editing `scripts/qa/verify-cx1-local.ps1`, `scripts/qa/cx1-release-guard-offline.test.mjs`, and its own CX1B restoration report. CX1C deliberately did **not** edit those files or the main checkout. No ports, Chrome sessions, browser profiles, client database tables, APKs, provider records or release directories were changed. A separate detached worktree allows automated acceptance-contract QA to proceed without merging or stomping uncommitted CX1B work.

**CX1C owns only:**

- `docs/CX1C_BROWSER_REFRESH_WITNESS_MATRIX_20261013.json` — six open cases, not falsely accepted
- `scripts/qa/cx1-browser-witness-preflight.mjs` — pure source-only contract validator
- `scripts/qa/cx1-browser-witness-preflight.test.mjs` — fully synthetic negative / positive-shape tests
- `docs/CX1C_PARALLEL_BROWSER_WITNESS_PREPARATION_20261013.md` — this independently resumable handoff

Do not edit shared `docs/HANDOVER.md`, `docs/ROADMAP.md`, `docs/ROADMAP_FILLERS.md`, execution-plan, or CX1B report from CX1C until the main writer has checkpointed. Then serially reconcile the new files into the current feature branch and update the living records. **Never force-push or rewrite CX1B history.**

## Fresh acceptance contract (six distinct real signed-in cases)

| Case | Browser viewport | Actual action | Required evidence |
| --- | ---: | --- | --- |
| Saved — mobile | 320 logical px | Navigate to existing Account → Saved; centre-tap labelled Refresh | Real signed-in Client window, visible label, route unchanged, before/after count, actual clicked control, release JS digest and restricted screenshot/evidence hash |
| Saved — desktop | 1440 logical px | Same on desktop | Same plus check unexpected Vendor Onboarding does not occur |
| Inbox — mobile | 320 logical px | Navigate to existing Inbox; centre-tap labelled Refresh | Same, verify read-only message list/count without sending new messages |
| Inbox — desktop | 1440 logical px | Same on desktop | Same, no mistaken navigation or support submission |
| Track — mobile | 320 logical px | Navigate to Track/Completed; centre-tap labelled Refresh | Same, no booking/review change |
| Track — desktop | 1440 logical px | Same on desktop | Same, route unchanged and no undesired action |

**Historic known issue:** On 11 October an attempted Saved toolbar click unexpectedly went towards Vendor Onboarding. No form was submitted, and root cause was never established. The new matrix explicitly leaves `route_anomaly.state=UNRESOLVED` until real current-browser evidence exists; it is **not** marked fixed.

## Running the validator

From the detached CX1C worktree root:

`node --test scripts/qa/cx1-browser-witness-preflight.test.mjs`

`node scripts/qa/cx1-browser-witness-preflight.mjs --review docs/CX1C_BROWSER_REFRESH_WITNESS_MATRIX_20261013.json`

The committed baseline deliberately prints **6 NOT_EXECUTED**, `ready_for_independent_human_CX1_review:false`, `formal_CX1_accepted:false`, and returns **exit 2** (blocked as expected, not a failing widget). Malformed, deceptive or contradictory evidence returns **exit 1**. Only a fully populated structurally valid 6-case matrix with a current non-reproduced anomaly recheck can return **exit 0**, and then the output is merely **ready for independent HUMAN review**. It never asserts that the observer identity, screenshot, authentic Chrome session or JS provenance is externally verified.

**Important:** Even an exit-0 result is not a release decision. Anyone can type strings into a JSON file; structural validation alone cannot prove an actual person clicked anything. Independent human witness and restricted original evidence are still required.

## Recording real evidence later (do not edit the tracked plan)

Copy the baseline matrix to an ignored restricted `.wantok/cx1c-browser-witness-private.json` in a controlled local test environment. For each actual `OBSERVED` case, a real authorised browser session witness must record:

- `capture_source=ACTUAL_SIGNED_IN_CHROME_WINDOW`, true observed session/client window/visible labelled control/centre click
- non-sensitive before/after visible route tokens and counts; unexpected Vendor Onboarding flag
- independently computed `release_js_sha256` and `private_evidence_sha256` (no JWT, cookies or personal details in the tracked repository)
- a locally recorded human observer identifier, which this script cannot authenticate

Only after an actual separate recheck can `route_anomaly.state` become `REVIEWED_NO_REPEAT` with `current_live_recheck:true` and an evidence SHA-256. If the unexpected navigation recurs, record `REPRODUCED`; **do not** close the gate or infer a cause. If a route or list count changes, the validator blocks readiness pending explanation, even if a legitimate concurrent database update is eventually found.

## Known dependencies and blockers

- Before live tests, CX1B must verify which process serves `:3000`/`:3300`, actual Client JS/image parity, build provenance, and a stable authorised existing Chrome Client window. **Never infer signed-in acceptance from HTTP 200 alone.**
- Do not use CX1C to launch or stop CX1B's servers, change ports, inspect Chrome cookies/tokens, log into someone's account, capture identifying user records, or write to Supabase.
- Six inactive-category editorial photos, actual image-editor authorised save/rollback, Android/HONOR sign-in/physical acceptance remain **separate open CX1 gates**.
- E6 Security G1–G10 remain **0/10 human-approved**, G7 **31/31 NOT EXECUTED**, D1–D5 privacy unresolved, E6O-01 local writer grants OPEN; Technical T2.4 PAUSED, E7+/production blocked.

## QA labels and merge handoff

**Fresh EAGLT02 QA (13 October):** CX1C synthetic evidence-validator tests **13/13 PASS**; baseline `--review` reports 6 NOT_EXECUTED and exits 2 as intended. Full separate detached-source `scripts/flutter/check.ps1` returned **exit 0**, **7 clean analyses** and **Client 132/132 + Operations 43/43 + Technical 38/38 widget tests PASS** (213 total); no Flutter source changed. These are automated engineering results, not live browser acceptance.

The tests create only **synthetic** browser-shaped dictionaries in memory and assert fail-closed behaviour on fake approvals, widget-test provenance, missing evidence, mismatched routes/counts, Vendor Onboarding, and invalid case sets. They do not access the network or browser. **Do not label synthetic positive-shape tests as genuine Client acceptance.**

On returning to the main feature branch, confirm other session's source/remote commit, re-run tests, check `git status`, stage **only** the four CX1C-owned paths, update handover/roadmap serially, then fast-forward/push and verify a new source-only release archive if there are no overlapping writes. If the parallel session is still active, retain CX1C as a local detached commit/handoff. The current source baseline is `91bd630` and must be reconciled against the final CX1B tested commit, not silently renamed as its release.
