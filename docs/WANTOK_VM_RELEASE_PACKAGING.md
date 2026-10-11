# Wantok Services — repeatable Linux VM packaging and upgrade
**Status: development readiness, not production go-live clearance.**

## Existing deployment foundation
`deploy/vps/` already contains a three-site Flutter Web build
(Customer Web, Operations, Technical Control), Caddy TLS proxy,
self-hosted Supabase provisioning, migrations, backup, install and
upgrade helpers. Phase 2D corrects Bash helper execution when the
Windows Git archive has non-executable script permission bits.

This release is a **versioned source installation archive**, not a
fully offline executable bundle. The destination VM must have Docker,
Docker Compose, Git, OpenSSL, jq, network access to official container
and Flutter/Supabase sources, adequate RAM/disk and a supported Linux
distribution. Initial build time may be significant.

## Package on EAGLT02
From the tested repository branch:
```powershell
cd D:\Project-M.2\wantok-service-recovery
npm run db:test
npm run test:evidence
node scripts/build-vps-release.mjs
node scripts/verify-vps-release.mjs .wantok/releases/wantok-vps-<commit>.tar.gz
```
The packager refuses uncommitted **tracked** changes to avoid an
archive of a different source revision. It extracts only selected
version-controlled directories from **HEAD**. Untracked project files,
device configuration, local `.env`, generated Flutter builds,
`node_modules`, database volumes and credentials are excluded.

For every archive it creates:
- `wantok-vps-<commit>.tar.gz`
- `wantok-vps-<commit>.tar.gz.sha256`
- `wantok-vps-<commit>.tar.gz.manifest.json`

The verifier checks SHA-256, archive safety and required installer,
app and migration files. Checksums detect accidental changes;
they are **not a digital signature or proof of publisher identity**.

## First Linux VM installation (only after production sign-off)
Upload the archive and its sidecars via an authenticated channel.
On the VM, verify the checksum **before extraction**:
```bash
sha256sum -c wantok-vps-<commit>.tar.gz.sha256
sudo mkdir -p /opt/wantok-service/app
sudo tar -xzf wantok-vps-<commit>.tar.gz -C /opt/wantok-service/app
cd /opt/wantok-service/app
cp deploy/vps/.env.example deploy/vps/.env
chmod 600 deploy/vps/.env
# Edit domain, ACME email, runtime paths and external DB settings.
nano deploy/vps/.env
bash deploy/vps/install.sh
```
Use a **new, empty approved production database** on first install,
or an expressly planned migration with backup, mapping and consent;
do not copy laptop/demo user, NID, fake KYC or application test data.

The checked-in configuration defaults to
`WANTOK_DOMAIN=wantokservices.com`. Confirm the **actual owned
domain**, DNS and certificate plan before installation. In particular,
`wantok.io` versus `wantokservices.com` should not be silently
assumed interchangeable.

## Application upgrade on VM
1. Record current Git/release ID, runtime and migration versions.
2. Take and **verify** PostgreSQL and Storage backup; test restore
   on a disposable environment; keep off-host copies.
3. Confirm the new SHA-256 release and its migration compatibility.
4. Replace **only application source** in the deployment directory;
   preserve `deploy/vps/.env`, production Supabase runtime, volumes,
   keys and database separately. Use a separate staging directory and
   an atomic app switch where possible.
5. Run `bash deploy/vps/upgrade.sh` only after staging acceptance.
   The existing helper backs up, migrates and rebuilds services.
6. Verify HTTPS, Auth, Operations RBAC, service discovery, user session,
   pending applications and audit events; monitor errors.
7. If a migration has changed data/schema, **switching back a web
   container is not equivalent to rolling back the database**.
   Use a reviewed migration-reversal or tested restoration plan.

```bash
bash deploy/vps/backup.sh
bash deploy/vps/upgrade.sh
```

## Before calling this an unattended installer
- Run first/upgrade/restore drills on a dedicated Linux staging VM.
- Confirm pinned official Supabase version actually exists and is
  supported, DB migrations work against that deployed runtime, disk
  permissions and health checks are effective.
- Keep private secrets and managed encryption keys outside the Git
  source archive, with verified rotation and recovery.
- Review the Dockerfile build args; only publishable Supabase keys
  are allowed in frontend builds.
- Pin images by digest, scan dependencies, sign releases, add CI
  build/test attestation and security monitoring.
- Verify Caddy DNS/certificates, rate limiting, backup encryption,
  unattended volume growth, maintenance windows and failover.
- Keep identity-upload endpoints, external access to sealed evidence
  and vendor clearance issuance disabled until independent sign-off.

## Phase 2D restricted custody status reader
`20261011195000_trusted_custody_reconciliation_read.sql` introduces a
`service_role`-only, read-only RPC exposing the **current** claim state
and minimal digest-bound manifest metadata. The local Node
`trusted-reconciliation.mjs` checks this database response against
**offline synthetic** WQE2 envelopes and reports missing objects,
withdrawal, tampering, inconsistent IDs, or pending reconciliation.
No real applicant files, keys, manifests, Storage objects or approvals
are written or released by this feature. The current manifest
remains pending independent reconciliation, even if digests match.

No network listener is started for custody reconciliation.
