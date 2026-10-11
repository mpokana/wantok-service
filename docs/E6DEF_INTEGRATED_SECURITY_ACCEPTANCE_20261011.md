# E6D–F Integrated Security Checkpoint — 11 October 2026

**EAGLT02 source commit:** `0ad0fde5b64b364143830e9b5ac5bf844c9e66e9`
**Integrated base:** T2.4 `0ba95ef` and earlier E6A–C1; unrelated T2.4 implementation preserved.
**Independent clean checkout:** `D:\Wantok_E6DEF_Independent_QA_20261011` detached HEAD `0ad0fde`.

## Exact automated gates

- `npm.cmd run db:migrate`: local additive migrations `20261011230000`, `20261011231000`, `20261011232000` applied without database reset.
- `npm.cmd run db:test`: **56 SQL files / 1,139 pgTAP assertions PASS**, including negative-access and workflow suites 053–056. Prior synthetic tests 030–035 and 047 continue to pass with explicit verified staging scope and no real records. All synthetic user, service and role data are in rolled-back test transactions.
- `npm.cmd run test:evidence`: **101/101 PASS**, file intake/release disabled.
- Direct Operations analysis: no issues; full direct Operations widget suite **43/43 PASS** including five new independent duty-approval view tests.
- Clean detached checkout `scripts/flutter/check.ps1`: **seven Flutter analysis targets PASS**, complete Client **132/132 PASS**, Operations **43/43 PASS**, Technical Control **22/22 PASS**. The original checkout and T2.4 tracked source were not touched. Process-local `ProgramFiles(x86)` was set to the normal Windows path for the test runner only; no locked build folder deleted.
- `git diff --cached --check`: PASS before functional commit. E6 functional source commit based on concurrent T2.4 security commit `0ba95ef`. Only E6-owned paths staged; untracked `supabase/snippets/` preserved.

## Supported conclusions

Code-level country, region and service-family isolation, dual-authorised staff provisioning, staged applicant owner reads, conflict recusal, direct critical-column grants and sealed old activation functions are covered by the local test suite. The new staff-duty page's requester/approver/read-only UI and original staged-review widgets passed. No new E6 migration, widget or test was deployed or synchronised to the online VM.

**Not established by these tests:** independently witnessed, authenticated multi-user/browser matrix with named staff and fresh sign-in/out; legally evidenced country/subdivision authority, independently attested employee appointments, beneficial ownership/related-party screening, secret custody, dual approval of live bootstrap/emergency use, final security/pentest review, disaster-recovery exercises or regulatory/legal acceptances.

These outstanding human/security controls are **formal E6 sign-off blockers**. Do not confuse E6 coding checkpoint with production release or enable E7–E12 identity collection/KYC, live service activation or payments. No production staff duties, real applicant evidence or remote VM changed.

## Delivery

GitHub branch and verified source archive are recorded against the final docs commit once created. Preserve the exact source hash, archive checksum and `productionApproved:false` in the final handover. Next staff-ready activity: collect country-authorised requester/approver confirmations and source evidence, then execute witnessed role-by-role access/revocation acceptance in authorised local accounts.
