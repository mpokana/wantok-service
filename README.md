# Wantok Service

Wantok Service is a Papua New Guinea-focused multi-service marketplace and super-app platform. It uses one Expo application for Android, iOS and web, with a version-controlled Supabase backend for authentication, PostgreSQL, row-level security, realtime, storage and trusted server-side functions.

The product is broader than ride-hailing. Taxi is one specialised vertical inside a shared platform for transport, delivery, people/services, hire, venues, events, food, shopping and later travel services.

See `docs/SUPER_APP_ARCHITECTURE.md` for the product and domain architecture.

## Current enterprise development baseline

- Email/password authentication with persistent mobile sessions.
- One account can act as customer and, after approval, one or more provider types.
- Customer Services hub for taxi, vehicle/boat hire, venues/events, specialists, general labour, delivery/errands and food/shopping.
- Native taxi map on Android/iOS and MapLibre/OpenStreetMap on web.
- Secure server-side nearest-driver assignment and ride lifecycle foundation.
- Generic marketplace catalogue, provider services/resources, bookings, quotes and reviews.
- Live quote-based marketplace workflow for Specialist Services and People / General Labour: customer request → qualified provider quote → customer acceptance → confirmed booking.
- Resource availability and database-enforced overlap protection for vehicles, boats, venues and other reservable assets.
- Enterprise RBAC roles for customer, provider, driver, admin, operations, support, finance and moderation.
- RLS enabled on every application table.
- Operational audit events and status-change auditing.
- In-app notification records plus a delivery outbox for push/email/SMS workers.
- Payment-intent, payment-event and provider-settlement boundaries with no direct client payment mutation.
- Push-device registration model.
- Private provider-document storage policies.
- Reproducible Supabase migrations and pgTAP database tests.
- GitHub CI validates frontend, database migrations/tests and all platform bundles.
- Android package and iOS bundle identifier: `io.wantok.service`.

## Architecture

```text
Android / iOS / Web
        |
     Expo Router
        |
  Supabase client
        |
+-----------------------------------+
| Wantok Service Backend            |
|                                   |
| Supabase Auth                     |
| PostgreSQL + RLS                  |
| Realtime                          |
| Private Storage                   |
| Trusted RPC / Edge Functions      |
| Notification Outbox              |
| Payment Integration Boundary      |
+-----------------------------------+
        |
+-----------------------------------+
| Shared Marketplace Core           |
| Identity / RBAC                   |
| Providers / Verification          |
| Catalogue / Listings / Resources  |
| Bookings / Quotes / Reviews        |
| Availability / Reservations       |
| Audit / Notifications / Payments  |
+-----------------------------------+
        |
+-----------------------------------+
| Specialised Verticals             |
| Rides / Taxi                      |
| Delivery / Errands                |
| Food / Shopping                   |
| Events / Ticketing                |
| Travel integrations               |
+-----------------------------------+
```

Taxi remains specialised because dispatch, live driver location, routing and trip state have different concurrency and safety requirements from general marketplace bookings.

## Requirements

- Node.js and npm
- Docker Desktop with Linux containers/WSL2
- Supabase CLI (included as a development dependency)
- Android Studio for Android emulator/native development
- EAS or macOS/Xcode for native iOS release builds

## Environment

Copy `.env.example` to `.env` and use only a Supabase publishable key in the Expo application:

```env
EXPO_PUBLIC_SUPABASE_URL=http://YOUR-DEVELOPMENT-HOST:54321
EXPO_PUBLIC_SUPABASE_PUBLISHABLE_KEY=YOUR_PUBLISHABLE_KEY
```

Never place a Supabase secret/service-role key in any `EXPO_PUBLIC_*` variable.

For a physical Android/iOS device, use EAGLT02's current reachable LAN/VPN address rather than `127.0.0.1`. The local Supabase API listens on port `54321`.

## Install and frontend validation

```bash
npm ci
npm run check
npx expo install --check
```

Run the app with:

```bash
npm run web
npm run android
npm run ios
```

## Local Supabase backend

The Git repository is the authoritative backend definition.

```bash
npm run db:start
npm run db:status
npm run db:migrate
npm run db:test
npm run db:stop
```

To prove the backend can be recreated from migrations:

```bash
npm run db:reset
npm run db:test
```

On Windows, `scripts/supabase-local.js` automatically targets the Docker Desktop Linux engine.

Local development endpoints use the standard Supabase ports:

- API: `54321`
- PostgreSQL: `54322`
- Studio: `54323`
- Mailpit: `54324`

Studio and PostgreSQL are development/admin surfaces. Do not expose them to the public internet. Future external testing should publish only the intended application/API endpoints through a controlled reverse proxy/tunnel with appropriate access controls.

## Backend migrations

Current migration sequence:

1. `20261004143000_initial_wantok_service.sql` — profiles, provider applications, drivers and rides.
2. `20261005002000_marketplace_core.sql` — multi-service catalogue, provider listings/resources, bookings, quotes and reviews.
3. `20261005010000_enterprise_platform.sql` — RBAC, audit, notifications, payment boundaries, settlements and devices.
4. `20261005011000_availability_and_reservations.sql` — provider availability and resource double-booking protection.

Every backend schema/security change must be made through a migration. Do not make production-only dashboard schema changes that are absent from Git.

## Security model

- Ordinary clients cannot grant themselves provider/admin/finance roles.
- Provider approval is performed by trusted database functions.
- Sensitive role changes generate audit events.
- RLS is enabled across all application-owned tables.
- Riders receive a limited approved-driver listing.
- Ride assignment occurs server-side with concurrency protection.
- Provider documents are private and user-scoped.
- Authenticated clients cannot directly create payment intents, processor events, settlements, audit events or outbound notification jobs.
- Resource double-booking is blocked by a PostgreSQL exclusion constraint, not merely by UI checks.
- Payment capture/refund/payout logic will be implemented only on trusted server infrastructure when payment providers are selected.

## Database tests

Run:

```bash
npm run db:test
```

The current pgTAP contract suite verifies core tables/functions, seeded service and role catalogues, RLS coverage, protected financial/audit write boundaries and reservation overlap protection.

## Product scope

Active foundation categories include:

- Taxi / Ride
- Vehicle Hire
- Boat Hire
- Boat / Ship Rides
- Specialist Services
- People / General Labour
- Venue Booking
- Events
- Delivery / Courier
- Errands / Pabili
- Food
- Groceries / Shops

Later reserved modules include buses/coaches, accommodation and flights.

## Remaining major work

The enterprise backend foundation is now reproducible, but launch still requires real provider document upload UI, complete driver accept/decline/trip controls, background driver location, route-based distance/ETA, generic marketplace search/booking screens, merchant catalogues/carts/orders, notifications worker/Edge Functions, payment-provider integrations, settlement operations, chat, safety/SOS, disputes/refunds, monitoring, backups, production hosting, automated end-to-end tests and store signing/release workflows.

## Version-control rule

Git is the source of truth. Use committed branches/tags as checkpoints. Never overwrite a working source tree with an unverified folder snapshot.
