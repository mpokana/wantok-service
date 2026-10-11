# Wantok Services — Next Chat Start Here (11 October 2026)

**Purpose:** Short, authoritative transition checkpoint for a new coding chat. Read it with `AGENTS.md`, `docs/HANDOVER.md`, `docs/ROADMAP.md`, `docs/ROADMAP_FILLERS.md` and the feature's architecture/security design. The living documents contain earlier work; the latest requirements and caveats below supersede older implementation suggestions where they conflict.

## Owner directive — highest priority

**DO NOT deploy to, log into, synchronise, reinstall or change the online VM.** Owner expressly says it is not yet time for VM deployment. Complete the outstanding enterprise platform work on **EAGLT02 local development** first. Throughout development, maintain a **repeatable, versioned, independently testable Linux VM package** (application images/build, additive migrations, secrets/config separation, backup/restore, install/upgrade and integrity verification). Do not assume packaging means production readiness. Do not silently activate payments, providers, public emergency listings or file uploads.

End of this handover task: **stop feature work; let the new chat take over.**

## Authorised development environment

- Workstation: `eaglt02`, Desktop Commander device ID `5087a7f7-e618-4c84-b534-8dde28f6497f`. It was **online at handover**; check it again before work. Do **not** touch other Remote Desktop Commander devices.
- Project root: `D:\Project-M.2\wantok-service-recovery`. Git branch `feature/flutter-platform-v1`. Remote `origin=https://github.com/mpokana/wantok-service.git`.
- Supabase is local Docker. Do not use `supabase db reset`; do not remove volumes or alter production. Commands from repository root: `npm.cmd run db:migrate`, `npm.cmd run db:test`, `npm.cmd run test:evidence`.
- Flutter installed at `D:\Development\flutter\bin\flutter.bat`. Flutter workspaces: `apps/wantok_app` (Customer/Vendor), `apps/wantok_admin` (**Operations**; internal package name retained), `apps/wantok_tech` (**Technical Control**), shared `packages/wantok_api`, `packages/wantok_ui`, other packages.
- Local web previews on EAGLT02: Client `http://127.0.0.1:3000`, Technical Control `:3100`, Operations `:3200`, Client staging `:3300`, Technical staging `:3400`. `localhost` is local to EAGLT02, not to a phone/VM. Staging builds may lag canonical builds: check actual served bundle and avoid claiming parity from port HTTP 200 alone.
- Existing emulator `Medium_Phone_API_36.1` and offline-demo APK around Android versionCode **4009**; **do not wipe** or reinstall without explicit acceptance scope. Physical HONOR and signed-in Android acceptance remain open.
- **Concurrent edits:** Handover began with unrelated untracked `supabase/snippets/`. During docs staging, additional **unstaged** Client changes appeared in `apps/wantok_app/lib/src/home/activity_page.dart`, `client_account_tools.dart` and `messages_page.dart`. These belong to a parallel stream and are **excluded from the handover Git commit**. Do not stage, delete or format them. Inspect fresh `git status` before each edit and stage an explicit file list.
- Keep Wantok Services separate from GVE corporate infrastructure and Wantok Neurons (a separate personal AI platform; potential future API provider, not the Services transaction authority).

## Current confirmed delivery checkpoint (11 October)

- **Latest enterprise security change:** `af63232` (`af632329546c98adf8eab718f2536430b82140b4`) — country/region/service policy **internal drafts**, mandatory preview, author submission, different reviewer, reasons/audit events, immutable revision lineage. Read `docs/INTERNATIONAL_VENDOR_POLICY_GOVERNANCE_PHASE2E.md`. In Operations: **Verification & KYC → International compliance policy proposals** on `:3200`.
- That work passed **49 local pgTAP files / 937 assertions**, **33 Operations Flutter widget tests**, clean Operations static analysis, successful web release build and served JS feature checks. These are **point-in-time results**, not a blanket production audit.
- **Vendor onboarding and trust foundation:** individual/business intake case with category-dependent metadata and owner/staff RLS, preliminary tasks and two-person procedural review; evidence requests/withdrawal; applicant-local fail-closed preflight; emergency clearance revocation and service pause; offline synthetic scanner/quarantine/custody metadata and restricted reconciliation. See `docs/VENDOR_ENTERPRISE_INTAKE_PHASE1.md`, `docs/VENDOR_VERIFICATION_PHASE2A.md`, `docs/VENDOR_EVIDENCE_PHASE2B_LOCAL.md`, `docs/EVIDENCE_PREFLIGHT_PHASE2C_LOCAL.md`, `docs/EVIDENCE_CUSTODY_RECONCILIATION_DRYRUN.md`, `docs/WANTOK_VM_RELEASE_PACKAGING.md`.
- **CRITICAL:** no production-ready document upload/storage/reviewer evidence release, no approved privacy/legal notice or signed consent, no verified government ID/business registry integration, and no final independent KYC clearance issuance. New vendor service activation remains gated. Never accept raw NID/passport/TIN/licence documents through chat/email or the preliminary forms; drafting/acknowledgement is **not consent**.
- **Client CX1 stream:** approved category imagery, shared global branding, local Customer and Technical web screens, backend-governed catalogue with six additional inactive categories; signed-in Web category-first provider discovery and Saved after hard reload read-only have some accepted checks. CX1 is **still in progress**, particularly real browser click acceptance for Saved/Inbox/Track refresh, real Android/HONOR checks, and real category image CRUD + six PNG/Pacific category photos. **T2.4 diagnostics/logs/jobs deferred**. See latest `docs/CX1_RELEASE_PARITY_GUARD_20261011.md`, `docs/CX1_WEB_READONLY_ACCEPTANCE_20261011.md`, `docs/CX1_LIVE_SAVED_INBOX_TRACK_20261011.md`; don't generalise Flutter widgets to browser acceptance.

## Packagability — preserve from the beginning

- Installer/upgrade: `deploy/vps/install.sh`, `deploy/vps/upgrade.sh`, `deploy/vps/backup.sh`, Docker Compose, separate `.env`, migration/provision helpers.
- Build/test source archive via `node scripts/build-vps-release.mjs`, `node scripts/verify-vps-release.mjs <archive.tar.gz>`. No secrets or development database in source archive.
- Latest **verified** package at this checkpoint: `D:\Project-M.2\wantok-service-recovery\.wantok\releases\wantok-vps-af632329546c.tar.gz` (11,685,311 bytes; SHA-256 `d62fc9b5ee3d1def087425a6482401cdd821d539bdfc32d4577774abb2fdca5b`; **62** migrations), with `.sha256` and `.manifest.json` sidecars. That is a **source-based installer**, not a standalone offline binary or approved production package; later commits require rebuilding a new archive if exact HEAD parity is wanted.
- No staging/production VM first-install, upgrade or restore drill has been authorised or executed. Do not attempt it until the owner explicitly allows VM work.

## Next engineering milestones — prioritised, not yet completed

1. **Country-scoped Operations/Compliance roles and isolation**: move from broad is_admin staff actions to explicit least-privilege policy-author/reviewer, evidence officer, independent approver and jurisdiction-scoped rights. Database guards first. Add country/province negative-access and two-person conflict-of-interest tests; do not broaden legacy users automatically.
2. **Purpose-bound privacy/legal consent governance**: ISO country/subdivision reference validation; locale, legal-source/effective-date research; independently reviewed legally approved/versioned notices and explicit per-purpose applicant consent/withdrawal. Current Phase 2E policy states end at `internal_review_complete` intentionally; nothing publishes or authorises uploads.
3. **Secure evidence upload and custody**, only after approved notice/consent and security design: real GoTrue authentication; least-privilege gateway; scanner/sandbox, private encrypted storage/KMS, durable tamper-evident off-host custody, retention and recovery drills. Current preflight fails closed; existing scanners/custody demos are **synthetic/offline**.
4. **Actual identity/business/licence verification** using authorised sources, exception handling, independent final approval/clearance, revocation, expiry maintenance, renewal and appeals; *do not infer KYC from procedural checks*.
5. **Separate enterprise Helpdesk** for requests, safety incidents, complaints, fraud, SLA timers/escalation, staff case assignments and audit/private attachments; don't confuse existing `SupportInquiriesPage` with a complete Helpdesk.
6. **International and enterprise hardening**: category/provider/transport/food/equipment jurisdiction-specific eligibility; country/province/city filters; payment/regulatory segregation, localisation, accessibility, observability/alerts, security threat model, E2E browser/device acceptance, backups/DR drills.
7. **Deployment rehearsal only after explicit owner permission**, using disposable Linux staging VM. Preserve independent Technical Control vs Operations and data/secret separation.

**Stop after documentation handover:** do not start #1 inside the handover chat.

## New chat instructions (copyable)

> Continue Wantok Services enterprise development on EAGLT02 only. First read AGENTS.md, docs/START_NEXT_CHAT_20261011.md, docs/HANDOVER.md, docs/ROADMAP.md, docs/ROADMAP_FILLERS.md, docs/ENTERPRISE_RELEASE_READINESS_GATES.md. Check the current Git HEAD/status/branch and validate the existing local Supabase state before coding. The owner expressly forbids online VM deployment at present. Start with country-scoped Operations/Compliance RBAC as the next security prerequisite, keep actual ID uploads/final clearance disabled, preserve existing CX1 and unrelated work, test and commit exact files to Git/GitHub, and keep the versioned installer package compatible with changes. Ask for explicit authorisation before touching any VM or live marketplace/payment/provider activation.
