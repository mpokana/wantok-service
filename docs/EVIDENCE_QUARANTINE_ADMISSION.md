# Sealed candidate quarantine and account-bound intake intents
Date: 9 October 2026 · EAGLT02 local development only

## Completion boundary

This checkpoint introduces **authenticated account-bound intent metadata** and an **isolated, encrypted quarantine library**. It does **not** create an HTTP upload route, service-role gateway, reviewer download, live applicant consent capture, evidence publication, or provider verification/activation.

The Supabase `staged-provider-evidence` bucket is still sealed: no client INSERT/SELECT/UPDATE/DELETE Storage object policies are added. Do not request applicant documents until the remaining release gates are implemented and approved. No real user files or credentials were ingested.

## Database — migration 20261009024500_evidence_intake_intents.sql

`public.staged_evidence_intake_intents` tracks ONLY a future request to admit evidence, not the evidence itself. It stores check/application/account UUIDs, a **draft notice version identifier**, `awaiting_secure_gateway` or `withdrawn` state and timestamps. There are no file paths, blobs, upload tokens, signatures, API keys, or medical/financial documents.

- RLS: authenticated applicant sees only their own row; platform administrators have read access. Anonymous users and direct authenticated table INSERT/UPDATE/DELETE are denied.
- `prepare_staged_evidence_intake(check_id, notice_version)` obtains caller identity exclusively from `auth.uid()`; verifies the staged category is enabled only for information, provider activation is disabled, the application is in manual review and belongs to the caller, and the checklist requirement is actively planned. The version string must match `WANTOK-EVIDENCE-INTAKE-DRAFT-2026-10`. Repeat requests are idempotent.
- `withdraw_staged_evidence_intake(intent_id)` permits withdrawal by the same account only. Withdrawn intents cannot be silently reopened.
- The hard-coded notice string is a **draft technical version handshake, NOT an approved privacy notice or meaningful/recorded informed consent**. Before a real upload, publish and approve a complete PNG-specific privacy/retention notice, capture explicit consent with time and audit, and allow revocation/withdrawal implications to be honoured.
- The test `033_evidence_intake_intents.test.sql` runs under a rolled-back pgTAP transaction, covering blocked/unplanned/foreign-account requests, RLS, notice version, repeat protection, withdrawal and unchanged Storage closure. The test does not insert permanent smoke/provider records.

## Internal encrypted candidate component

Code: `packages/evidence_scanner/src/quarantine.mjs`; tests: `quarantine.test.mjs`, plus a real-clamd integration test in `real-clamd.test.mjs`.

`quarantineWithVerifiedIntent(...)` is **not callable from a public route**. It requires a verification callback which MUST later come from a separate trusted server that validates the presented Supabase session and reads the database intent, not from Flutter or caller-controlled JSON. The current tests use a deliberate fake callback and **do not demonstrate live end-to-end authentication between the Node library and Supabase**.

For a test candidate, the function:
1. Requires UUID account, application, checklist and intent identifiers, a 32-byte AES key supplied from memory and a trusted eligibility decision matching all four identifiers and `awaiting_secure_gateway` state.
2. Performs the existing preliminary file-signature/size checks and a live or test-double ClamAV scan **in memory**, before writing anything.
3. After an explicit `candidate_clean` verdict, writes one AES-256-GCM encrypted object with authenticated metadata (UUIDs, SHA-256, MIME and byte length) as additional authenticated data. Uses an exclusive `wx` write to prevent replacement; a metadata receipt accompanies the ciphertext.
4. Returns only digest, size and `quarantined_not_released` status. The receipt does not contain the original filename or file contents. There is no reviewer-access operation.
5. Provides `verifyQuarantineIntegrity` to detect tampered ciphertext/receipt/wrong key and return only non-sensitive integrity status, **never decoded bytes**.

A storage-side lock, atomic DB/FS transaction, and irrevocable immutability are NOT established by exclusive creation alone. On Windows, POSIX `mode=0600`/`0700` is NOT an adequate ACL enforcement mechanism. This module **must not be installed as a live file-ingestion service** until protected Windows ACLs or isolated Linux-volume permissions, reliable KMS/key rotation/recovery, audit-ledger binding, retention/expiry/erasure, quotas/rate limits, crash recovery and atomic admission/object status changes are designed and tested. Local temp test fixtures are automatically destroyed after each test. No production encryption keys are generated/stored.

## Validation

- `npm run test:evidence`: scanner transport tests plus encrypted-quarantine unit tests; tests cover scan failure, missing/untrusted verifier, duplicate intents, tampered ciphertext, receipt digest changes, wrong key and no plaintext on disk.
- `npm run test:evidence:real`: actual ClamAV daemon against clean synthetic PDF-like bytes and harmless EICAR; isolated temporary encrypted test candidate with integrity verification. All temp files deleted.
- `npm run db:test`: RLS/identity/intent/Storage denial checks, plus prior database regression suite.
- `scripts/flutter/check.ps1`: full Flutter analysis and smoke/widget suite. No Dart screens are modified by this milestone.
- `git diff --check`, private local PostgreSQL archive, verified GitHub feature-branch push and independent local Git bundle before checkpoint.

## Following local one-time claim implementation (9 October 2026)

The next additive checkpoint implements a GoTrue-verified, **internal loopback-only** admission adapter and `service_role`-restricted one-time SQL claim, but does **not** wire either to Flutter or an upload endpoint. See `docs/EVIDENCE_AUTH_AND_CUSTODY_DESIGN.md`, `packages/evidence_scanner/src/admission.mjs` and migration `20261009043000_evidence_one_time_claim.sql`. It adds claim state, a private same-transaction receipt, and post-claim owner withdrawal. The existing encrypted quarantine prototype is unchanged. Tests: 34 SQL files / 736 assertions, 46 unit tests and 4 genuine ClamAV tests pass. Live Auth-to-claim and custody crash/retry validation remain open.

## Required next phase before real uploads

Implement an authenticated network gateway with session JWT validation **on the server**, server-side record admission and one-time claim/consumption, approved privacy notice, strict rate/size limits, scanner health and fresh signatures, robust decoder/normaliser, private encrypted quarantine with safe ownership/ACLs, durable digest-bound atomic manifests, retention and deletion/holds, key management, separate least-privilege reviewer release and independent account/listing authorisation. Perform end-to-end negative tests and restore drills; deploy only with explicit approval.

Production and legacy provider approval remain unchanged. Do not expose localhost clamd to the LAN or Internet.
