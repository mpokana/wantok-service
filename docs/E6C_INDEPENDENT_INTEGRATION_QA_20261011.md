# E6C1 Independent Integration Acceptance — 11 October 2026

**Source commit tested:** `8604ea24ce1edd6a3149ef768e540633fa87f6e4`.
**Parent:** `05bb91fe747ed7e3a432302259db336a2b3f9895`, including separately verified CX1 image staging.
**Independent checkout:** `D:\Wantok_E6C_Independent_QA_20261011` detached at `8604ea2`.
**Source of truth:** `D:\Project-M.2\wantok-service-recovery`, branch `feature/flutter-platform-v1`.

## Test gates completed

- `npm.cmd run db:migrate`: local additive migration `20261011220000_operations_scoped_clearance_safety.sql` applied without reset.
- `npm.cmd run db:test`: **52 pgTAP files / 1,043 assertions PASS**, including 34 new E6C privilege/isolation tests plus updated 044/045 rollback-only synthetic fixture checks.
- `npm.cmd run test:evidence`: **101/101 Node evidence safety tests PASS**. No evidence acceptance or release enabled.
- `flutter analyze --no-pub` Operations: no issues. Direct Operations `flutter test --no-pub`: **38/38 PASS**.
- Full `scripts/flutter/check.ps1` at `8604ea2` in clean detached worktree: **all seven Flutter analysis targets PASS; Client 132/132, Operations 38/38 and Technical Control 16/16 widget tests PASS**. Independent checkout remained clean; `ProgramFiles(x86)` was restored only within the remote PowerShell process to avoid a known Windows env problem.
- Repository at the time of E6C code commit had only unrelated untracked `supabase/snippets/`; it was not staged or modified.

## Acceptance boundaries

These results are **automated local source regression**, not signed-in browser multi-user acceptance, full security penetration testing, officially sourced regional classification, staffed approval governance or production certification. E6 as a whole remains open; old staged-provider paths, cross-module direct activation paths, applicant/business COI, staff authorisation governance and E7–E12 gates still need work.

No online VM accessed, no real ID files, payments, new approvals, real-case data changes, or provider activation. A HEAD-matched release archive and GitHub push must be verified as separate steps and recorded with their exact commit/checksum.
