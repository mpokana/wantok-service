# Wantok Service

Wantok Service is a Papua New Guinea-focused service marketplace built as one Expo application for Android, iOS and web, with Supabase providing authentication, PostgreSQL, realtime, storage and server-side business functions.

## Current baseline

The recovered baseline includes:

- Email/password authentication and persistent mobile sessions.
- Customer service catalogue.
- Taxi map with native `react-native-maps` and a MapLibre/OpenStreetMap web implementation.
- Secure server-side nearest-driver ride assignment.
- Ride history and passenger cancellation.
- Provider applications and secured admin approval.
- Approved-driver online location updates and realtime map updates.
- Version-controlled Supabase schema, RLS policies, realtime publication and private provider-document storage.
- Android package and iOS bundle identifier: `io.wantok.service`.

## Architecture

```text
Android / iOS / Web
        |
   Expo Router
        |
 Supabase client
        |
+--------------------------+
| Supabase                 |
| Auth                     |
| PostgreSQL + RLS         |
| Realtime                 |
| Storage                  |
| Database RPC functions   |
+--------------------------+
```

The application uses one shared business/UI codebase. Platform-specific map rendering lives in `components/TaxiMap.tsx` for Android/iOS and `components/TaxiMap.web.tsx` for web.

## Requirements

- Node.js and npm
- Docker Desktop
- Supabase CLI (installed as a development dependency)
- Android Studio for local Android builds/emulation
- EAS or a macOS/Xcode environment for native iOS builds

## Environment

Copy `.env.example` to `.env` and supply a development Supabase URL and public/publishable key:

```env
EXPO_PUBLIC_SUPABASE_URL=http://YOUR-DEVELOPMENT-HOST:54321
EXPO_PUBLIC_SUPABASE_ANON_KEY=YOUR_PUBLIC_OR_PUBLISHABLE_KEY
```

Never place a Supabase secret/service-role key in an `EXPO_PUBLIC_*` variable.

For a physical Android/iOS device, the Supabase URL must be reachable from that device. `127.0.0.1` points to the phone itself, not the development computer.

## Install and validate

```bash
npm ci
npm run check
npx expo-doctor
```

Start Expo:

```bash
npm start
```

Or target one platform:

```bash
npm run web
npm run android
npm run ios
```

## Local backend

Start the repository's local Supabase stack:

```bash
npm run db:start
npm run db:status
```

Apply pending migrations to a running local stack:

```bash
npm run db:migrate
```

Stop it with:

```bash
npm run db:stop
```

The authoritative backend definition is under `supabase/`. Do not make production schema changes only through a dashboard; create a migration so the backend remains reproducible.

## Security model

- Role flags such as `is_admin`, `is_driver` and `is_driver_approved` cannot be changed by ordinary users.
- Provider approval is performed by the secured `review_provider_application` database function.
- Riders receive a limited available-driver listing that does not expose driver phone numbers.
- `request_ride` selects and locks the nearest available approved driver server-side and returns contact information only for the assigned ride.
- Direct arbitrary ride insertion by authenticated clients is not granted.
- Provider documents use a private storage bucket with per-user access policies.
- Realtime access remains subject to RLS.

## Important backend objects

Tables:

- `profiles`
- `provider_applications`
- `driver_profiles`
- `driver_locations`
- `rides`

RPCs:

- `list_available_drivers()`
- `request_ride(...)`
- `review_provider_application(...)`

## Remaining product work

This baseline is suitable for continued development, but a production launch still needs product-level work including real document upload UI, driver trip accept/progress controls, background driver location, route-based distance/ETA, payments and settlement, notifications, food/delivery/vendor ordering, stronger admin operations, automated application tests, store signing/release workflows, monitoring and production Supabase/hosting deployment.

## Version-control rule

Git is the source of truth. Use committed branches/tags for checkpoints and keep the project reversible. Do not overwrite a working copy with an unverified folder snapshot.
