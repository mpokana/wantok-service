# Evidence scanner — isolated, fail-closed core
Date: 9 October 2026
Status: **LOCAL DEVELOPMENT ONLY — NO LIVE UPLOAD PATHWAY**

## Purpose and architecture

This is a self-contained, dependency-free Node.js package in `packages/evidence_scanner`. It prepares the scanning boundary for a future private document-ingestion service. It is **not connected** to the Flutter app, the Admin console, Supabase Storage, an HTTP upload route, or any provider-activation workflow. The existing `staged-provider-evidence` bucket remains **sealed**, with no ordinary user Storage object policies. No application can upload to or read evidence through this package.

Core module: `packages/evidence_scanner/src/scan.mjs`.
Test command from the repository root:

```powershell
cd D:\Project-M.2\wantok-service-recovery\packages\evidence_scanner
& "C:\Program Files\nodejs\node.exe" --test --test-reporter=tap test\scan.test.mjs
```

## Validation rules

`inspectEvidence({filename,declaredMime,bytes})` is a *preliminary* no-side-effect validator:
- Demands binary Buffer input of 12 bytes to 5 MiB and a simple filename without a path, Unicode bidirectional-control characters or Windows alternate-data-stream separators.
- Limits extensions to PDF, PNG, JPEG; checks declared MIME against the extension and checks basic file signature/structural markers against both.
- Checks PNG IHDR and image dimensions (max 25 million pixels), IEND and lack of trailing bytes. Checks JPEG SOI/EOI and PDF header/trailing EOF marker.
- Returns SHA-256, MIME and byte count. It does **not** execute or decompress untrusted content; however these inexpensive checks **do not prove** image/PDF safety, fully validate contents, or eliminate polyglots. A later isolated decoder/normaliser and separate MIME/content enforcement at the upload service boundary remain required.

`scanWithClamd(buffer, options)` implements the local ClamAV `zINSTREAM` TCP protocol, sending 64 KiB frames with a zero-length final frame. Host must be loopback (`127.0.0.1` or `::1`); default port 3310, default timeout 5 seconds. **No listener is opened.** No filesystem content is created or copied.

- Exact `stream: OK` response produces `candidate_clean` only.
- `... FOUND` returns a malware rejection error.
- Timeout, unavailable scanner, unexpected response, connection error, invalid size/config or missing explicit clean verdict **fails closed**. There is no "scanner unavailable: accept anyway" behaviour.
- `inspectAndScanEvidence` always sets `storagePermitted=false`, `reviewerAccessPermitted=false`, `approved=false`, **even if the scanner says clean**.

## Validation performed / not performed

Run `node --test --test-reporter=tap test/scan.test.mjs` (or `npm run test:evidence` from the repository root): **24 local Node tests** exercise signatures, MIME mismatch, filenames, limits, hash, 64 KiB multi-frame protocol streaming, simulated `FOUND`, no clean verdict, scanner failure, timeout and the always-disabled Storage/reviewer flags.

**ClamAV is NOT installed/running as part of this change; no real antivirus signatures or EICAR tests have been executed.** Tests use a local TCP protocol double; passing them is *not* proof of malware-detection effectiveness. EAGLT02 C: had ~7.6 GB free during audit, so we did not pull or start a large Docker antivirus image or change Docker Desktop's existing storage configuration. All running Supabase containers were left untouched.

## Release gates: must be done before accepting any documents

1. Provision a supported, updateable ClamAV instance with locked-down network visibility on appropriate storage/host capacity; health-monitor signature age/engine version, outbound update failures, limits and memory. Run harmless and AV-test-signature end-to-end scans against **the actual engine** on an isolated test environment.
2. Build a separately authenticated ingestion gateway with per-account eligibility and consent validation. **Do not issue signed upload URLs or public direct upload policies** without a genuine enforced quarantine/scanning pipeline. Enforce upload size, sniff content, use a sandboxed PDF/image decoder where appropriate, and reject encrypted/unsupported/active content.
3. Keep scanned bytes and verified SHA-256 bound to an immutable versioned object record; prevent storage/reviewer release until independent clean scan, digest matching, approval policy and a secure reviewer-access service are in place.
4. Design PII data minimisation, retention expiry, deletion/hold handling, encryption and key custody, separate reviewer roles, audited reads and incident response. Test isolation and recovery/restore.
5. Document environment-specific security architecture and obtain explicit production-release authorisation. The old owner-editable `provider-documents` bucket is **not** appropriate for verification evidence.

No real applicant records or samples were added to Supabase. Existing s-marked visual smoke data and the approved photographic Services theme were not changed. **Production remains untouched.**
