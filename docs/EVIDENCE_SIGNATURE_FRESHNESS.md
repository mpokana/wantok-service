# Internal ClamAV signature freshness gate — EAGLT02

Date: 9 October 2026. Status: LOCAL / INTERNAL ONLY; applicant uploads SEALED.

## Behaviour

The synthetic-candidate quarantine library now uses `scanWithFreshClamd` as its default scanner. It performs a separate authenticated-by-location (local loopback, NOT a network identity protocol) `zVERSION\0` probe before sending any applicant-like bytes to `zINSTREAM\0`. It parses clamd's UTC signature-build timestamp and refuses admission when the report is missing, malformed, stale or more than five minutes ahead of the host clock.

- Default maximum signature age: 48 hours; configuration cannot increase it beyond 72 hours.
- Socket limited to `127.0.0.1` or `::1`; connection timeout, bounded responses and configuration limits enforced. A disconnected, slow or invalid scanner fails closed.
- Live probe uses the trusted backend clock. Unit parser accepts an explicit test timestamp; live callers cannot supply an alternative `nowMs` to bypass aging.
- No bytes are scanned when the preflight fails. Passing it then requires the existing explicit `stream: OK` clean verdict, separate from virus-detection failures.
- Test-injected `scanner` callbacks in `quarantineWithVerifiedIntent` intentionally bypass the ClamAV checks to permit hermetic tests. They must never be passed from clients or a public endpoint.
- A positive scan or fresh virus database provides no permission to store, release, review, activate providers or handle real applicant documents.

## Verification

`npm run test:evidence` has 57 deterministic tests, including 11 freshness tests: exact age thresholds, future clock skew, malformed/oversize replies, remote-host restrictions, timeout, scanner error, no scan for stale signatures and a successful two-socket probe/scan.

`npm run test:evidence:real` has 5 tests against the actual EAGLT02 ClamAV process: current signature timestamp/preflight plus clean payload, official harmless EICAR rejection, no storage/reviewer access, and synthetic encrypted candidate verification. These are not a malware safety certification or encrypted custody acceptance.

Review `packages/evidence_scanner/src/freshness.mjs` and `packages/evidence_scanner/test/freshness.test.mjs` for exact implementation. Run `scripts/clamav-local.ps1 -Action Status` for runtime status; a healthy Docker container alone never guarantees timely signature updates. When stale, diagnose FreshClam safely, do NOT skip the gate or substitute manual unverified signature files.

## Outstanding blockers

The current account claim adapter and encrypted quarantine are still **not joined into a durable authenticated transaction**. No production-grade ACL, isolated storage mount, KMS, consent, object/DB manifest, recoverable outbox, content decoder isolation, reviewer permission gate, retention/deletion policy, off-host audit or restore drill has passed acceptance. The local `staged-provider-evidence` bucket remains sealed and no client upload/reviewer route is activated. Do not infer that any user documents have been accepted.

Flutter presentation, official category photographs, sample `s` markers, real accounts/emulator state, production deployment and all other equipment remain unchanged.
