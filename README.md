# Wantok Service

Wantok Service is a Papua New Guinea multi-service super app platform.

The primary application stack is now **Flutter + Supabase**.

## Deployable applications

### Wantok

Flutter application targeting:

- Android
- iOS
- Web

One Wantok account can operate in two modes:

- **Client mode** — use services.
- **Vendor mode** — provide approved services.

A user does not need a separate identity to become a vendor. Provider capabilities are granted through verification and RBAC.

### Wantok Admin

Separate Flutter Web console for authorised administrators.

Target production URL:

```text
https://admin.wantokservices.com
```

System administration is intentionally excluded from the public Wantok application.

## Production domains

Planned public surfaces:

```text
https://wantokservices.com
https://www.wantokservices.com
https://admin.wantokservices.com
https://api.wantokservices.com
```

Studio, PostgreSQL and internal infrastructure are private administration surfaces and must not be exposed directly to the public internet.

## Repository layout

```text
apps/
  wantok_app/       Flutter Android/iOS/Web client + vendor app
  wantok_admin/     Flutter Web administration console

packages/
  wantok_core/      Shared domain models and primitives
  wantok_api/       Supabase configuration and repositories
  wantok_auth/      Authentication and RBAC helpers
  wantok_ui/        Shared Wantok design system

supabase/
  migrations/       Authoritative database/schema/security history
  tests/            pgTAP enterprise/workflow tests

config/
  *.example.json    Safe build configuration examples

scripts/flutter/
  bootstrap.*       Resolve all Flutter packages
  check.*           Analyze and test all Flutter modules
  create-local-config.ps1

deploy/vps/
  docker-compose.yml
  Dockerfile.flutter-web
  Caddyfile
  install.sh
  upgrade.sh
  backup.sh

docs/
  FLUTTER_PLATFORM_ARCHITECTURE.md
  SUPER_APP_ARCHITECTURE.md
```

The earlier Expo/React Native implementation is retained in this recovery repository as a reference during Flutter migration. It is no longer the target application architecture. It should only be removed after equivalent Flutter workflows have been verified.

## Current product scope

The shared marketplace supports:

- Taxi / rides
- Vehicle hire
- Private boat hire
- Boat / ship passenger rides
- Specialist and trade services
- General labour / people
- Venue booking
- Events
- Delivery
- Errands
- Food
- Groceries / shops
- Future bus/coach, accommodation and flights

Shared platform services include identity, RBAC, provider verification, listings, resources, bookings, quotes, availability, audit, notifications, payments/settlements boundaries and reviews.

## Local development on EAGLT02

### Flutter

Current development baseline:

```text
Flutter 3.47.6
Dart 3.13.5
Android SDK 36.1
Java 21
```

EAGLT02 keeps `PUB_CACHE` on `D:\\Development\\PubCache`, the same drive as the repository. This avoids a Windows/Kotlin incremental-compiler path issue that occurs when Flutter plugins are cached on `C:` while the Android project is on `D:`. This is a workstation setting only and does not change Linux/CI deployment behaviour.

Bootstrap all Flutter modules:

```powershell
powershell -ExecutionPolicy Bypass -File scripts\flutter\bootstrap.ps1
```

Run analysis/tests:

```powershell
powershell -ExecutionPolicy Bypass -File scripts\flutter\check.ps1
```

Linux equivalent:

```bash
bash scripts/flutter/bootstrap.sh
bash scripts/flutter/check.sh
```

### Local Supabase

The repository Supabase project is the authoritative development backend.

```powershell
npm run db:start
npm run db:status
npm run db:migrate
npm run db:test
npm run db:reset
npm run db:stop
```

Development ports:

```text
API       http://127.0.0.1:54321
Postgres  127.0.0.1:54322
Studio    http://127.0.0.1:54323
Mailpit   http://127.0.0.1:54324
```

The CLI development stack is not a production deployment and must never be published directly to an untrusted network.

## Flutter backend configuration

Flutter receives environment-specific settings using Dart defines.

Generate EAGLT02 local Flutter configuration from the ignored root `.env`:

```powershell
powershell -ExecutionPolicy Bypass -File scripts\flutter\create-local-config.ps1
```

This creates the ignored file:

```text
config/local.json
```

Example run:

```powershell
cd apps\wantok_app
flutter run -d chrome --dart-define-from-file=..\..\config\local.json
```

Admin:

```powershell
cd apps\wantok_admin
flutter run -d chrome --dart-define-from-file=..\..\config\local.json
```

Never commit production secrets or database/service-role credentials.

The Supabase publishable key is a public-client credential; privileged service-role/database/JWT signing credentials remain server-only.

## Flutter application identifiers

Public Wantok mobile identity:

```text
Android applicationId: io.wantok.service
iOS bundle identifier: io.wantok.service
```

Final native iOS compilation/signing requires macOS with Xcode. Shared Dart/Flutter development remains cross-platform.

## Database migrations

Current migration sequence:

1. `20261004143000_initial_wantok_service.sql`
2. `20261005002000_marketplace_core.sql`
3. `20261005010000_enterprise_platform.sql`
4. `20261005011000_availability_and_reservations.sql`
5. `20261005012000_rbac_authority.sql`
6. `20261005020000_resource_reservation_workflow.sql`
7. `20261005021000_provider_onboarding.sql`
8. `20261005022000_open_request_workflow.sql`
9. `20261005023000_taxi_dispatch_lifecycle.sql`
10. `20261005024000_commerce_core.sql`
11. `20261005025000_events_core.sql`
12. `20261005026000_water_passenger_transport.sql`

All production schema/security changes must be migrations committed to Git.

## Current backend validation

The pgTAP suite currently verifies:

- enterprise table/function contracts;
- RLS on application tables;
- catalogue and RBAC seeds;
- customer service-request creation;
- qualified-provider visibility;
- quote submission;
- customer quote acceptance;
- confirmed booking/provider assignment;
- provider-role synchronisation;
- administrative role grant/revoke;
- legacy admin flags cannot independently grant server-side admin authority;
- resource overlap protection;
- secure vehicle/boat/venue reservation creation with availability-rule and time-off enforcement;
- trusted multi-category vendor onboarding with duplicate/unsupported application protection;
- open marketplace request creation, provider visibility and quote assignment;
- taxi nearest-driver offers, decline redispatch, acceptance and enforced ride-state transitions;
- Food/Groceries server-priced commerce orders, catalogue ownership and fulfilment transitions;
- Events discovery, ticket capacities, registration, cancellation and organiser check-in;
- scheduled water passenger routes, vessels, departures, fare capacity, manifests, boarding and lifecycle enforcement;
- restricted direct payment/audit/outbox mutation.

## Linux VPS deployment

Production is designed for a standard Linux VPS with Docker Engine and Docker Compose.

### Supabase

Production backend uses Supabase's **official self-hosted Docker distribution**, not the CLI development containers.

Keep the vendor runtime separate, for example:

```text
/opt/wantok-service/runtime/supabase
```

On a fresh VPS, `deploy/vps/install.sh` calls `provision-supabase.sh`, which installs the pinned official self-host release when the runtime is absent, generates its keys, applies Wantok's private-network hardening override, starts Supabase and synchronises the public client configuration. Re-running the installer is intended to be idempotent.

This preserves Supabase's supported `.supabase-version` and `update.sh` upgrade model while Wantok keeps its own schema changes under `supabase/migrations/`.

### Wantok edge/web

Copy:

```text
deploy/vps/.env.example
```

to:

```text
deploy/vps/.env
```

and configure it.

Install/rebuild:

```bash
sh deploy/vps/install.sh
```

Normal Wantok upgrade:

```bash
sh deploy/vps/upgrade.sh
```

Supabase vendor upgrade is explicit and separate:

```bash
WANTOK_UPGRADE_SUPABASE=1 sh deploy/vps/upgrade.sh
```

The upgrade script performs a backup first and runs the official Supabase self-host dry-run/update sequence before recreating services.

Manual backup:

```bash
sh deploy/vps/backup.sh
```

See `deploy/vps/README.md` for production commissioning details.

## Design direction

Wantok uses an original PNG-focused design system informed by successful Southeast Asian super-app interaction patterns:

- strong service discovery from the home screen;
- location/search first;
- simple everyday action cards;
- visible activity/history;
- fast Client/Vendor switching;
- safety and payments treated as platform capabilities rather than isolated screens.

The visual system does not copy Grab branding or pixel-level UI.

Current Wantok palette begins with tropical green, deep green, gold and coral accents and will evolve into a dedicated PNG brand system.

## Release version

Current platform version:

```text
0.1.0-alpha.3
```

The `VERSION` file is the application release source of truth.

## Security principles

- `user_roles` is the authoritative authorization source.
- Admin controls exist only in Wantok Admin.
- Ordinary clients cannot grant themselves privileged roles.
- Provider/service approval occurs through trusted backend functions.
- RLS is mandatory on application-owned tables.
- Payment capture/refund/payout mutation remains server-side.
- Audit records and outbound notification jobs are not directly client-writable.
- Provider documents remain private.
- VPS database/Studio/internal service ports are not public.
- Production upgrades are preceded by tested migrations and backups.
