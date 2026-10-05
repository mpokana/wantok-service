# Wantok Service Flutter Platform Architecture

## Product model

Wantok Service is a Papua New Guinea multi-service super app.

There are two deployable applications:

1. **Wantok** — Android, iOS and Web. One account contains:
   - Client mode
   - Vendor mode
2. **Wantok Admin** — Web-first administration and operations console.

The public application never exposes system administration controls.

## Experience model

### Client mode

Client mode is designed for fast service discovery and everyday transactions:

- Taxi / rides
- Vehicle hire
- Boat hire
- Boat / ship passenger services
- Specialists and trades
- General labour / people
- Venue booking
- Events
- Delivery
- Errands / Pabili-style tasks
- Food
- Groceries / shops
- Future travel services

### Vendor mode

A user can become a vendor without opening a second user account. RBAC and provider verification unlock vendor capabilities such as:

- Jobs and requests
- Quotes
- Active bookings
- Service listings
- Resources
- Availability
- Earnings and settlements
- Provider documents
- Reviews

Taxi/delivery driver capabilities remain specialised modules because they require dispatch, online status and location tracking.

## Repository layout

```text
apps/
  wantok_app/       Flutter Android/iOS/Web
  wantok_admin/     Flutter Web

packages/
  wantok_core/      Domain primitives and shared models
  wantok_api/       Supabase bootstrap and repositories
  wantok_auth/      Authentication and RBAC access
  wantok_ui/        Shared Wantok design system

supabase/
  migrations/       Authoritative schema/security changes
  tests/            pgTAP contracts and workflows

deploy/vps/         Linux VPS web/edge install, upgrade and backup
config/             Build-time configuration examples
scripts/flutter/    Cross-platform Flutter bootstrap/check helpers
```

## Backend

Supabase remains the backend platform:

- PostgreSQL
- Row Level Security
- Auth
- Realtime
- Storage
- Edge/server functions where required
- RBAC
- Audit
- Notifications
- Payment boundaries

The local Supabase CLI stack is development-only.

Production uses the official Supabase self-hosted Docker distribution. Its vendor runtime is kept separate from this repository and versioned by Supabase's `.supabase-version` mechanism. Wantok owns only its migrations, policies, functions and application configuration.

## Public domains

Production target:

- `https://wantokservice.com` — Wantok Web
- `https://admin.wantokservice.com` — Wantok Admin
- `https://api.wantokservice.com` — Supabase API/Auth/Storage gateway

Studio, PostgreSQL and internal container services must not be publicly exposed.

## Design language

The experience is inspired by proven Southeast Asian super-app interaction patterns: rapid service discovery, compact service cards, prominent location/search actions and clear activity/history surfaces.

Wantok does not copy another company's brand or pixel-level interface. Its design system uses original tropical PNG-oriented colours, terminology and service groupings.

## Release model

The repository contains a `VERSION` file.

Recommended release sequence:

1. Merge tested feature work.
2. Tag a semantic version.
3. Run backend migration tests.
4. Run Flutter analysis/tests.
5. Build Android/Web artifacts.
6. Back up production data.
7. Apply database migrations.
8. Rebuild/recreate web containers.
9. Verify health and smoke tests.

iOS source is developed in the same Flutter app but final signing/build requires macOS/Xcode.

## Upgrade principle

Application code and Supabase vendor runtime are upgraded separately:

- **Wantok release:** Git tag/release + migrations + Flutter builds.
- **Supabase runtime:** official self-hosted `update.sh`, only after a database/storage backup and dry-run review.

This separation prevents Wantok business code from forking Supabase's upstream Docker configuration.
