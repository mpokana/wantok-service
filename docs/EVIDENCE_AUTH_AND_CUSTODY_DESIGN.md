# Evidence Auth and Encrypted Custody — EAGLT02 design checkpoint

**Date:** 2026-10-09 · **Status:** INTERNAL DEVELOPMENT ONLY · **No public evidence upload**

## Implemented in this checkpoint

- `packages/evidence_scanner/src/admission.mjs` is a **loopback-only server-side adapter**, not an HTTP listener. The constructor rejects remote Supabase origins, missing/misused keys, and unsafe URLs.
- It extracts a strict Bearer JWT from a caller's Authorisation header, requests `GET /auth/v1/user` from the fixed EAGLT02 Supabase GoTrue endpoint, and trusts **only** the returned authenticated user ID. It does **not** decode a JWT locally and accept unverified claims, or use a client-supplied applicant ID.
- Only after GoTrue authorisation does the adapter use the server-held `service_role` credential to invoke `claim_staged_evidence_intake`. That credential belongs exclusively to a future backend runtime, never Flutter or a browser. All errors fail closed without echoing HTTP bodies, credentials or JWTs. Network redirects are rejected; requests have five-second timeouts.
- Migration `20261009043000_evidence_one_time_claim.sql` adds `claimed_for_quarantine`, `claimed_at`, `claim_id` and a private claim-receipt table with RLS. The claim RPC is execute-granted **only** to `service_role`, never to `authenticated` or `anon`.
- The claim RPC performs a single conditional `UPDATE ... RETURNING`, checking intent/applicant/application/check consistency, status, planned requirement, preliminary-review status and category readiness. The private receipt INSERT runs in the same transaction. Exactly one competing caller may change `awaiting_secure_gateway` to `claimed_for_quarantine`; a duplicate/revoked intent fails.
- An applicant may withdraw **after** a claim, preventing the claim from remaining active. Historical receipt metadata is retained for audit. The original draft-notice marker continues to be **not consent**.

## What this does not do

- **No public upload route, no network listener, no production Auth deployment, no applicant file, no Storage grant, no client UI wiring, no reviewer read and no provider activation.**
- The authenticated claim adapter is **not connected** to `quarantineWithVerifiedIntent`. That existing code still accepts an injected verification callback and uses only synthetic test bytes; it is not a production-grade custody mechanism.
- A successful claim is **not** permission to store a file. A clean scanner verdict is **not** provider approval. The `staged-provider-evidence` bucket remains sealed.
- A claim can be consumed without producing a file. There is currently **no safe retry/reset procedure**. Do not manually reopen claims to recover failures.
- The private SQL receipt is an operational audit record, **not** append-only or tamper-resistant off-host evidence. It does not bind to an encrypted file or scanner result.
- The current Windows local temp-file encryption tests do **not** prove protected ACLs, crash-safe durability, file-version immutability, key rotation, erasure, restore, content sanitisation or consent.

## Architecture for a later, separately approved secure intake

1. **Legitimate consent and identity:** approved and jurisdiction-reviewed privacy notice; version, scope, time, lawful basis and account consent receipt; accessible withdrawal/retention details; GoTrue verification on every new admission request. Do not treat a draft version string as informed consent.
2. **Edge admission:** independent authenticated HTTPS gateway after deployment authorisation, strict Origin/CORS policy, CSRF design for cookie auth, request/body rate and size quotas, no unauthenticated redirects, non-persistent access-token handling, fixed app/check/intent linkage and abuse auditing.
3. **Atomic custody state machine:** eligible -> reserved/claimed -> scanning -> encrypted -> held -> separately reviewer-released or rejected/deleted. Implement crash recovery, lease-expiry policy, retries without reopening a consumed claim, transactional outbox, reconciliation and orphan cleanup with explicit approvals. Claim records and object manifests must be digest-bound and strongly consistent.
4. **Malware and content validation:** limit input to permitted 5 MiB PDFs/PNGs/JPEGs initially; scanner health and signature-age threshold required before ingestion; fail closed on FreshClam, ClamAV, timeout or decoder errors; isolate PDF/image inspection in resource-limited unprivileged processes. Reject active content, parser exploits and malformed/polyglot structures; scanning alone is never sufficient.
5. **Private encrypted quarantine:** run in a dedicated restricted Linux service account/volume or a Windows location with explicitly verified NTFS ACLs (not POSIX `0700`/ `0600` semantics on Windows). Never store inside repo, home documents, public web root or ordinary Supabase Storage. Use atomic/fsync-safe writes and manifests, no symlink traversal, immutable/versioned blob paths, object hash/size/metadata authentication and separate encrypted key material.
6. **Key custody:** managed KMS or vault-generated data-encryption keys, key IDs/versions, independent access policies, rotation and disaster-recovery procedures. No key in Git, receipt JSON, browser bundle, unprotected environment output or database row; test inability to decrypt when key custody is lost.
7. **Audit, retention, privacy and release:** append-only/off-host audit anchored to claim, scanner report, ciphertext digest and consent; time-bound retention, legal holds, approved deletion and cryptographic erasure; independent Operations Admin reviewer authorisation and least-privilege release. Technical Control may monitor integration health but cannot grant provider approval.
8. **Operations and tests:** replay/race/revocation tests; invalid/malicious PDFs and images; scanner-outage/old-signature handling; interrupted I/O and partial DB commits; user enumeration leaks; file/DB integrity, KMS recovery, permission/ACL inspection, audited restore drills and sign-off before any applicant upload.

## Offline consistency and evidence reconciliation (9 October 2026)

- Read-only `custody-reconcile.mjs` compares a synthetic WQE2 scratch file against a **caller-supplied untrusted snapshot** and claim status. It never obtains records from the database, creates/reopens claims, writes files, releases ciphertext or approves providers. Mismatches, withdrawal or interrupted artifacts require investigation; an exact match still has **zero release rights**.
- Required next phase: authenticate metadata read using a service-restricted server-only interface, bind it to the **current** one-time claim/withdrawal state, add durable transactional outbox and audited reconciliation with independently verified sealed filesystem permissions. Do not infer that an untrusted snapshot or unit test is a live custody proof.

## Local restricted custody metadata and NTFS ACL audit (9 October 2026)

- New `20261009060000_custody_manifest_metadata.sql` creates a private, claim-receipt-linked, one-time server-role-only custody digest record. It is ALWAYS pending independent reconciliation: no physical file verification, no status release/review or upload. The new offline proposal function builds matching request fields from **synthetic** AES-GCM envelope inspection and intentionally makes **no RPC call**.
- Read-only `scripts/verify-evidence-vault-acl.ps1` audits an empty isolated NTFS lab using only explicit FullControl grants for current EAGLT02 Windows user and SYSTEM. It does not establish a dedicated service account, network boundary, full restore, unprivileged account denial or production-grade storage. See `docs/EVIDENCE_CUSTODY_MANIFEST_AND_ACL_LAB.md`. Real uploads remain disabled.

## Offline single-envelope recovery prototype (9 October 2026)

- Additive `packages/evidence_scanner/src/custody.mjs` uses only synthetic offline fixtures: claim ID and bounded non-secret key ID authenticated in a one-file AES-GCM envelope, exclusive lock/pending publication, non-overwriting filesystem hard-link, and read-only interrupted-state inspection. Detailed limits and testing are in `docs/EVIDENCE_CUSTODY_OFFLINE_RECOVERY.md`.
- It is **not connected** to the real GoTrue adapter or database claim. Simulated interrupted-operation tests are not Windows power-loss durability evidence; there is no independently verified NTFS ACL, KMS, outbox, immutable audit, consent or reviewer path. All uploads remain disabled.

## Local scanner freshness increment (9 October 2026)

- `freshness.mjs` runs the internal candidate-quarantine default scanner only after verifying the real loopback ClamAV VERSION signature time. It enforces at most 48 hours since definitions (72-hour configurable absolute upper limit), no negative clock skew beyond five minutes and strict bounded parsing, timeout and origin checks; see `docs/EVIDENCE_SIGNATURE_FRESHNESS.md`.
- The scanner still accepts an explicitly injected test double in test code. This new gate is **not** an independently authorised network intake service. Authorised custody, consent, decoded-content security, audit and restore remain unimplemented.

## Testing status and open risks

- 2026-10-09: `npm run db:test` **34 files / 736 assertions PASS**; local SQL schema migration applied to EAGLT02 only.
- `npm run test:evidence` **46 tests PASS** (including 11 new admission adapter tests with controlled mock HTTP responses).
- `npm run test:evidence:real` **4 tests PASS** against the actual loopback ClamAV 1.5.4 scanner/signatures 28147.
- Tests of GoTrue and its claim RPC are currently **separate**, not a joined live JWT/account upload flow. The adapter's HTTP tests use synthetic mock responses; PostgreSQL role/eligibility/duplicate/withdrawal tests use rolled-back pgTAP transactions. A genuine JWT-authenticated end-to-end race test and cross-system fault injection remain release blockers.
- Windows safe-root ACL acceptance, KMS, private volume, durable outbox, filesystem rollback handling, signature-age enforcement, decoder isolation, real consent, independent reviewer authorisation and full restore rehearsals are **not implemented**.

## File scope

- Source: `packages/evidence_scanner/src/admission.mjs`.
- Migration: `supabase/migrations/20261009043000_evidence_one_time_claim.sql`.
- Tests: `packages/evidence_scanner/test/admission.test.mjs`, `supabase/tests/034_evidence_one_time_claim.test.sql`.
- Test script updates: root and scanner `package.json`.
- No edits to Flutter widgets, reference photos, service categories, `WANTOK_SMOKE_DATA`, application auth sessions or existing scanner/quarantine logic.
