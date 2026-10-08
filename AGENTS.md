# AGENTS.md — Wantok Services

## Read this before changing the project

For every new coding session, agent handover, Codex task, Desktop Commander task, or recovered ChatGPT conversation:

1. Read `docs/HANDOVER.md`.
2. Read `docs/ROADMAP.md`.
3. Read `docs/ROADMAP_FILLERS.md` for Mansfield's incremental additions and clarifications.
4. Read the architecture document relevant to the task:
   - `docs/SUPER_APP_ARCHITECTURE.md`
   - `docs/FLUTTER_PLATFORM_ARCHITECTURE.md`
   - `docs/ADMIN_CONTROL_PLANE_ARCHITECTURE.md`
5. Run `git status --short --branch` and inspect the latest commits before editing.
6. Preserve existing architecture unless Mansfield explicitly approves a refactor.
7. Use migrations for every database/security change.
8. Do not mix Wantok Services with GVE systems or Wantok Neurons implementation details. Wantok Neurons may later integrate only through approved API boundaries documented for Wantok Services.

## Safe-change rule

Do not break working modules to add a new module. Prefer additive, isolated changes. Validate before committing.

Minimum checkpoint validation:

- `scripts/flutter/check.ps1`
- `npm run db:test`
- `git diff --check`

For focused changes, run narrower checks during development, then the full checkpoint validation above before commit.

## Local and GitHub checkpoint rule

After each meaningful validated work session, retain both a **local Git commit** and a verified **GitHub branch push** to the existing project remote (`origin`, `https://github.com/mpokana/wantok-service.git`). Before pushing, inspect `git status`, the exact remote URL and branch, and the staged file list for accidental secrets, environment files, personal data or generated artefacts. Never push credentials or ignored `.wantok/` local settings. Push only the current feature branch; do not force-push, rewrite shared history, change the default branch or merge without explicit approval. Verify the remote branch's commit ID against local `HEAD` after pushing. If GitHub access is unavailable, keep the local commit, record the blocked remote backup and retry after restoring authorised access. GitHub complements, but is not a substitute for, independent database/asset backups.

## Smoke/sample data rule

Temporary demo/sample records are **opt-in, presentation-only and reversible**. The canonical manifest is `docs/SMOKE_DATA.md`, with fixture IDs prefixed `SMOKE_20261008_` and a small visible **s** badge on every sample item. The `WANTOK_SMOKE_DATA` Flutter compile-time flag defaults to false and must not be enabled for production. Never insert demo records into Supabase or treat samples as genuine provider approvals, payments, bookings or messages. When the project is ready, disable the flag and follow the manifest to remove all fixture code. Do not SQL-delete anything merely because its display name resembles a sample.

## Living handover rule

After a meaningful phase or safe Git checkpoint, update:

- `docs/HANDOVER.md`
- `docs/ROADMAP.md`
- `docs/ROADMAP_FILLERS.md` when filler items are added, resolved or remapped

Keep them compact. Record only information needed to safely resume work: current branch/commit, validated state, active architecture decisions, current phase, important local-development facts, and next tasks.

## Project identity

- Product: Wantok Services
- Domain: `wantokservices.com`
- Primary stack: Flutter + Supabase
- Operations console: Wantok Operations Admin
- Technical console: Wantok Technical Control Panel
