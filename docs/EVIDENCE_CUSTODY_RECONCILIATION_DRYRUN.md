# Read-only offline custody snapshot reconciliation and Android emulator continuity

Date: 9 October 2026, EAGLT02 local development ONLY.

## Emulator — preserve the installed app and account

The EXISTING Android Virtual Device `Medium_Phone_API_36.1` was started without `-wipe-data`, reinstall, package reset or cache clear. Its first remote launch ran invisibly in Windows Session 0, so it was stopped **gracefully** via `adb emu kill` and restarted using a named, on-demand, non-recurring Windows scheduled task `Wantok_Emulator_Interactive` configured with `InteractiveToken` for the already logged-on `EAGLT02\\Mansfield` desktop account. The final emulator and qemu processes run in **active console Session 1**, not Session 0. ADB confirmed `emulator-5554`, `sys.boot_completed=1`, installed package `io.wantok.service`, and `io.wantok.service/.MainActivity` as the top resumed activity. The task remains registered and running to avoid disrupting the emulator; it has no automatic schedule. Do not close the emulator, replace photographs, reset sessions or seed production demo data.

## New offline reconciliation component

`packages/evidence_scanner/src/custody-reconcile.mjs` exports `reconcileOfflineCustodySnapshot`, a **read-only, synthetic-fixture-only** comparator. It consumes (1) an existing scratch-held WQE2 envelope and its supplied test AES-GCM key; (2) synthetic, externally supplied untrusted SQL-shaped manifest metadata; and (3) a caller-supplied claim state. No actual Supabase query, database write, GoTrue integration, file modification, key store, upload, storage policy, scan or reviewer access is performed.

The comparator calls the existing scratch-only, read-only inventory and integrity verifier; binds the claim, intent, applicant, application, check, plaintext/ciphertext digests, byte counts, MIME, envelope version, non-secret key ID and pending-only metadata state. It rejects mismatches, missing sealed files or manifests, withdrawn claims, corrupt sealed ciphertext and interrupted operations. Results have **no hash, key, path, plaintext or filename**, and ALWAYS set approval, Storage and reviewer permissions to false. A matching snapshot is explicitly named `snapshot_matches_still_pending_independent_reconciliation` and **still requires manual independent reconciliation**; it is NOT file-custody proof or a consent/approval decision.

The API cannot authenticate the supplied snapshot or claim state. A compromised caller can supply matching invented metadata. It MUST NOT be used as a production custody/approval gate. Storage location is still restricted to synthetic scratch directories. No path from the protected NTFS lab is accepted by this module.

## Local verification

- New focused `custody-reconcile.test.mjs`: 12 deterministic tests for matching-but-non-releasing snapshot, absence, withdrawal, tamper, wrong key, identity/size/hash/version mismatches, and interrupted pending files.
- `npm run test:evidence`: **85 deterministic scanner/auth/custody/reconciliation tests PASS**.
- `npm run db:test`: **35 files / 767 pgTAP assertions PASS** with unchanged schema and sealed Storage bucket.
- `npm run test:evidence:real`: **6 real ClamAV/EICAR tests PASS** after restarting existing Docker containers.
- `scripts/flutter/check.ps1`: **7 analysis targets clean and 72 Flutter tests PASS** (68 Wantok app, 3 Admin, 1 Technical).

## EAGLT02 Docker issue observed during emulator start

Docker Desktop initially failed after launching from Remote Desktop Commander because the remote process environment had no `ProgramData` variable. The Docker log showed `unable to get 'ProgramData'`; no data-file damage was demonstrated. A **process-scoped** `ProgramData=C:\ProgramData` (and `ProgramFiles(x86)` for compatibility) was supplied for a normal Docker Desktop GUI launch, following a stop of its failed UI/backend processes while its WSL engine was down. Docker restarted the **existing** Supabase and ClamAV containers (no factory reset, volume removal, data-root change or container rebuild). The machine/system environment was NOT modified. Check `docker ps` and health on each subsequent session.

## Remaining security prerequisites

A trusted service-role-only read of an authentic SQL custody snapshot and externally validated account/claim state, a real transactional file+database reconciliation outbox, a dedicated service identity and vault permissions, managed keys and recovery, independent restore and crash drills, parser sandbox, approved privacy consent, retention/legal holds, off-host tamper evidence and Operations Admin reviewer gates all remain open.

**Live applicant uploads, reviewer read/release and provider approval stay disabled.** CX1 signed-in Web acceptance remains open, and T2.4 is not advanced.
