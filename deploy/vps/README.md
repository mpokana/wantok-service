# Wantok Service Linux VPS Deployment

This folder is the production deployment boundary for Wantok Web, Wantok Operations Admin, Wantok Technical Control, the public edge proxy and production Supabase provisioning helpers.

## Public DNS

Create these records when the VPS is commissioned:

- `wantokservices.com` -> VPS public IP
- `www.wantokservices.com` -> VPS public IP
- `admin.wantokservices.com` -> VPS public IP
- `tech.wantokservices.com` -> VPS public IP
- `api.wantokservices.com` -> VPS public IP

Only ports 80/443 should be publicly exposed for the Wantok edge layer.

## 1. Server prerequisites

Install:

- Docker Engine
- Docker Compose plugin
- Git
- OpenSSL
- jq

Clone the tested Wantok release under a stable path such as:

```text
/opt/wantok-service/app
```

## 2. Configure deployment

```bash
cd /opt/wantok-service/app
cp deploy/vps/.env.example deploy/vps/.env
chmod 600 deploy/vps/.env
nano deploy/vps/.env
```

The default configuration places the official Supabase vendor runtime under:

```text
/opt/wantok-service/runtime/supabase
```

`SUPABASE_SELF_HOST_REF` pins the official self-host release. Review and test that pin before changing it.

Never place service-role keys, JWT signing secrets or database passwords in Flutter source. The Supabase publishable key is a public-client credential and is synchronised into the private deployment environment file during provisioning.

## 3. Fresh install

```bash
sh deploy/vps/install.sh
```

The installer is designed to be repeatable. On a fresh VPS it:

1. clones the pinned official Supabase self-host release when the runtime is absent;
2. generates the Supabase secrets/keys;
3. applies Wantok's external Docker hardening override;
4. starts Supabase;
5. synchronises the publishable key and local-only database connection;
6. applies all version-controlled Wantok migrations;
7. builds Wantok Web, Wantok Operations Admin and Wantok Technical Control;
8. starts the Caddy TLS/reverse-proxy edge.

The Supabase CLI development stack is never used as the production runtime.

## 4. Network boundary

The Wantok Supabase override intentionally removes host port publication for:

- the Supabase API gateway;
- Supavisor/pooler.

PostgreSQL is bound to loopback only for controlled migration/backup access.

Caddy joins the private Supabase Docker network and publishes only supported application API paths through:

```text
https://api.wantokservices.com
```

Public routes include Auth, REST, Realtime, Storage, Functions and GraphQL. Other gateway paths return 404. Supabase Studio and PostgreSQL are not public web services.

## 5. Wantok upgrades

Deploy a tested Git tag/release and run:

```bash
sh deploy/vps/upgrade.sh
```

Normal application upgrade flow:

1. back up PostgreSQL and Storage;
2. reapply the Wantok Supabase hardening/runtime configuration;
3. apply Wantok database migrations;
4. rebuild the Flutter web containers;
5. recreate the Wantok edge/web stack.

Database migrations in `supabase/migrations/` remain the authoritative schema/security history.

## 6. Supabase vendor upgrades

Supabase runtime upgrades are explicit and separate from normal Wantok releases.

After reviewing the upstream release notes:

```bash
WANTOK_UPGRADE_SUPABASE=1 sh deploy/vps/upgrade.sh
```

The upgrade flow performs a backup first, runs the official self-host `update.sh --dry-run`, applies the vendor update and then reapplies Wantok's external hardening override.

Do not fork or casually edit Supabase's vendor Docker files. Wantok-specific behaviour belongs in migrations, environment configuration and the external override.

## 7. Backups

Manual backup:

```bash
sh deploy/vps/backup.sh
```

Default location:

```text
/opt/wantok-service/backups/<UTC timestamp>/
```

Backups include, when available:

- PostgreSQL custom-format dump;
- Storage volume files;
- protected Supabase runtime environment file;
- Supabase self-host version pin;
- Wantok application version.

Production should also use off-server/offline backup copies and regularly tested restores.
