# Real ClamAV runtime — EAGLT02 local development
Date: 9 October 2026 (PNG time)

## State and limits

The prior `packages/evidence_scanner` unit tests used a loopback TCP protocol simulator. A **real antivirus service** was subsequently installed and tested.

- Official image: `clamav/clamav:stable` (official Cisco Talos ClamAV Docker image).
- Downloaded image digest at install time: `sha256:ebec5bc138401b36ae987caa1a3fa3c3b2a21ed3d51f0bfa5852825e663e67b0`.
- Container name: `wantok-clamav-scanner`, managed independently of Supabase.
- TCP port: `127.0.0.1:3310:3310` only. **Never publish 3310 to 0.0.0.0 / LAN / Internet:** the ClamAV TCP protocol has no authentication or encryption.
- Virus-definition persistence: named Docker volume `wantok-clamav-signatures` mounted at `/var/lib/clamav`; it is not tracked by GitHub.
- Limits: 4 GiB maximum RAM, 2 GiB reservation, 2 CPU, 200 PIDs; restart policy `unless-stopped`.
- At acceptance: `ClamAV 1.5.4`, daily signatures `28147`, dated 8 October 2026 UTC. FreshClam updated the original 28136 signatures, and `clamd` reloaded approximately 3.63 million signatures.
- Observed scanner memory use approximately 1.1 GiB, with 51.2 GiB still free on C: after installation. Running Supabase containers were not reconfigured.

The initial FreshClam attempt failed and the host was receiving HTTP 403 from the signature CDN. A **single scanner-only restart** restored the DNS/version-check path; FreshClam then downloaded, verified and loaded daily database version 28147. Keep monitoring FreshClam; a healthy `clamd` process does not guarantee signature freshness indefinitely. Do not use scripted curl/wget downloads of ClamAV databases, which are discouraged by the vendor. If updates fail again, check DNS TXT for `current.cvd.clamav.net`, FreshClam logs, proxy/CDN restrictions and signature age before declaring the scanner ready.

## Verified real scanner tests

Two test suites exist and serve different purposes:

- `npm run test:evidence`: 24 deterministic unit/protocol tests using a local TCP test double; no real antivirus service required.
- `npm run test:evidence:real`: 3 integration tests against **the running actual ClamAV daemon**. It identifies a clean in-memory PDF-like payload, rejects the 68-byte **official harmless EICAR antivirus-test signature** with `MALWARE_FOUND`, and proves that even a genuine clean scan leaves `storagePermitted`, `reviewerAccessPermitted` and `approved` all **false**. No test documents are saved or uploaded.

The local runtime test recorded **3/3 passing** against ClamAV 1.5.4, signatures 28147. This confirms a working AV scanning interface and EICAR detection, not detection of all malware or safety of arbitrary PDFs/images.

## Safe operating commands

From EAGLT02 in PowerShell:

```powershell
cd D:\Project-M.2\wantok-service-recovery
powershell -NoProfile -ExecutionPolicy Bypass -File scripts\clamav-local.ps1 -Action Status
powershell -NoProfile -ExecutionPolicy Bypass -File scripts\clamav-local.ps1 -Action Test
powershell -NoProfile -ExecutionPolicy Bypass -File scripts\clamav-local.ps1 -Action Stop
powershell -NoProfile -ExecutionPolicy Bypass -File scripts\clamav-local.ps1 -Action Start
```

The script affects **only the Wantok ClamAV container**. Start reuses the existing container and signature volume if present; it will not remove/rebuild other containers, change Docker Desktop's data root or modify Supabase. A newly created container requires startup/signature loading time before it is healthy.

Useful Docker diagnostics (with Docker Desktop running):

```powershell
docker ps --filter name=wantok-clamav-scanner
docker logs --tail 80 wantok-clamav-scanner
docker exec wantok-clamav-scanner clamd --version
docker stats --no-stream wantok-clamav-scanner
```

## Explicitly NOT activated

The `staged-provider-evidence` bucket remains **sealed**. No client Storage object permissions were added, and neither the mobile app nor Admin console offers evidence uploads. There is no uploader, quarantine gateway, document normaliser/decoder, read-only review access, final provider approval or payment/booking activation in this phase.

Before exposing uploads: implement authenticated and consented ingestion, malware-detection health/freshness thresholds, true file validation/sandboxing, immutable digest-bound quarantine and versions, clean-only controlled reviewer release, audit and retention/erasure rules, safety monitoring and test-restores. Require separate deployment approval. **Production remains unchanged.**

## Backups

The scanner scripts/test source live in the GitHub feature branch and independent local Git bundle. The **Docker image, running container, signature volume and runtime definitions are machine-local and are not included in Git**. Recreate the scanner using the documented script, check that signatures are current and rerun real tests after machine recovery. The database schema and data were not changed in this stage, so the previous restricted PostgreSQL archive remains the local DB recovery point.
