# AGENTS.md — Wantok Service

## Read this before changing the project

For every new coding session, agent handover, Codex task, Desktop Commander task, or recovered ChatGPT conversation:

1. Read `docs/HANDOVER.md`.
2. Read `docs/ROADMAP.md`.
3. Read the architecture document relevant to the task:
   - `docs/SUPER_APP_ARCHITECTURE.md`
   - `docs/FLUTTER_PLATFORM_ARCHITECTURE.md`
   - `docs/ADMIN_CONTROL_PLANE_ARCHITECTURE.md`
4. Run `git status --short --branch` and inspect the latest commits before editing.
5. Preserve existing architecture unless Mansfield explicitly approves a refactor.
6. Use migrations for every database/security change.
7. Do not mix Wantok Service with GVE systems or Wantok Neurons implementation details.

## Safe-change rule

Do not break working modules to add a new module. Prefer additive, isolated changes. Validate before committing.

Minimum checkpoint validation:

- `scripts/flutter/check.ps1`
- `npm run db:test`
- `git diff --check`

For focused changes, run narrower checks during development, then the full checkpoint validation above before commit.

## Living handover rule

After a meaningful phase or safe Git checkpoint, update:

- `docs/HANDOVER.md`
- `docs/ROADMAP.md`

Keep them compact. Record only information needed to safely resume work: current branch/commit, validated state, active architecture decisions, current phase, important local-development facts, and next tasks.

## Project identity

- Product: Wantok Service
- Domain: `wantokservices.com`
- Primary stack: Flutter + Supabase
- Operations console: Wantok Operations Admin
- Technical console: Wantok Technical Control Panel
