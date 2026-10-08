# Claim-bound offline custody and recovery prototype

**Date:** 9 October 2026 · **Environment:** EAGLT02 only · **Status:** synthetic fixtures only · **Applicant evidence uploads remain disabled**

## Scope and critical boundary

`packages/evidence_scanner/src/custody.mjs` is a **separate offline research component**; it does **not** replace the historical `quarantine.mjs`, connect to the GoTrue claim adapter, update Supabase, open a network route, enable Storage permissions or grant reviewer access. No actual user documents, identities or production key material were processed. Only synthetic PDF-like fixtures are used in tests.

The entry point requires `mode: 'OFFLINE_SYNTHETIC_FIXTURE_ONLY'` and a pre-existing directory **directly under the system temp directory** beginning `wantok-offline-custody-`. It refuses other roots and symlink roots. These safeguards limit accidental invocation but **do not authenticate callers, distinguish a forged synthetic document from real data, or establish real private storage**. The supplied `verifyClaim` callback is deliberately a **test double**; a caller could forge it, so this API MUST NOT become a real upload endpoint.

## Tested offline operations

1. The component demands UUIDs for claim, intent, applicant, application and check, matching the callback's `claimed_for_quarantine` identity and a false approval/review/storage flag. No authority is derived from browser/Flutter state.
2. The 5 MiB signature/MIME/sha256 input gate and default 48-hour freshness-checked local ClamAV scanner must return `candidate_clean` before writing to scratch. Tests inject a clean scanner to exercise deterministic file states; an additional real-ClamAV test exercises the actual daemon.
3. Creates a **single AES-256-GCM sealed envelope** (`WQE2`) containing authenticated metadata: claim ID, intent/applicant/application/check IDs, a **non-secret** key identifier, file digest/size/MIME and a held-only state. There is **no plaintext or actual encryption key in the envelope**. The key is supplied temporarily in memory by the test, not stored or provisioned by a KMS. `verifyOfflineCustody` checks AEAD/hash/binding but never returns bytes to an applicant or reviewer.
4. The writer exclusively acquires a claim-specific `.lock`, exclusively writes a `.pending` envelope, calls the file handle's `sync()`, publishes the final `.held` path using a **same-filesystem hard link** that refuses existing target replacement, and normally removes pending/lock artifacts. No database update is attempted.
5. A **read-only, non-repairing** `inspectOfflineCustody` classifies absence, interrupted lock-only/pending, cleanly sealed candidate and sealed candidate with crash leftovers. A failed/partial operation retains its files/lock for investigation. **Never automatically reopens an already consumed database claim, retries, deletes forensic artifacts or grants review.**
6. Tests simulate interruption **after pending sync** and **after exclusive publication**; verify detection, blocked replay and no plaintext. Tests also cover parallel publication, non-overwrite, corrupted ciphertext, wrong key/key ID, cross-account/check binding, failed scans and invalid/symlink roots.

## Durability and security limits — NOT production acceptance

- `sync()` on the pending file and non-overwriting same-volume `link()` improve the prototype's ordering and collision resistance. **Windows directory-entry persistence after abrupt power loss is not established**, and there is no verified hardlink-capable dedicated NTFS volume or tested crash reboot. Simulated exceptions do not constitute power-failure validation.
- The scratch filesystem's **Windows NTFS ACLs are not independently accepted**. The prefix restriction, POSIX modes on Windows, a filename lock and authenticated encryption do not make a tamper-resistant storage service. Symlink/reparse-point races inside a writable root and privileged filesystem attackers require separate mitigation.
- The `.held` path is not filesystem-immutable/WORM: a privileged process with write permission could alter or delete it. There is no independent off-host digest/audit anchor.
- Neither the single-file envelope nor its metadata is a **transaction-linked PostgreSQL claim receipt**, a durable outbox, a recoverable key escrow or an authorised storage manifest. The existing one-time SQL claim still has no safe retry path.
- Real application use requires a review-approved privacy notice and consent; a trusted one-time GoTrue/DB claim-to-file protocol with transaction/outbox reconciliation; verified isolated ACLs/volume, KMS rotation and recovery, a sandboxed format normaliser, rejection of stale AV signatures, off-host audit, retention/legal holds/erasure, independent least-privilege reviewer approval and a full restore/power-failure drill.
- Keep existing `staged-provider-evidence` Storage bucket completely sealed and do not enable live uploads, provider approval or payment movement.

## Local validation

- `npm run test:evidence`: **71 tests PASS**, including 14 offline custody tests for sealing, concurrency, tamper, non-replacement and simulated crashes.
- `npm run test:evidence:real`: **6 tests PASS**, including real ClamAV + offline claim-bound envelope plus EICAR tests.
- Full Flutter and database suite results are recorded in `docs/HANDOVER.md` after checkpoint acceptance.

**Code:** `packages/evidence_scanner/src/custody.mjs`; tests: `packages/evidence_scanner/test/custody.test.mjs`, `packages/evidence_scanner/test/real-clamd.test.mjs`. The old `quarantine.mjs` remains supported/untouched.
