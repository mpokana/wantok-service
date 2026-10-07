# Wantok Services — Super-App Architecture

## Product direction

Wantok Services is not a taxi-only application and is **not limited to Papua New Guinea**. It is a global multi-service marketplace, service-delivery and travel platform built from PNG as its launch/home market. PNG-specific strengths remain first-class, but country boundaries must not be embedded into the platform core.

One signed-in account may act as a customer and, after approval, as one or more kinds of provider. There is no separate provider application. Provider tools appear according to approved roles and services.

Global expansion must preserve one Wantok account and one consistent product model while allowing market-specific catalogue availability, currencies, languages, time zones, addresses, payment rails, tax/regulatory requirements, provider rules and travel integrations.

## Core service scope

Initial and planned customer verticals:

- Taxi / ride-hailing.
- Vehicle hire.
- Private boat hire.
- Boat / ship passenger services.
- Specialist and trades hire: electricians, plumbers, builders, solar technicians, ICT/networking, drivers, logistics coordinators, guides, translators, trainers, consultants, photographers, media and event crew.
- General labour / people hire for short-term and scheduled work.
- Venue booking: halls, conference rooms, fields and other spaces.
- Events discovery and later ticketing.
- Delivery / courier for parcels, documents and goods.
- Errands / Pabili-style buying and collection tasks.
- Food ordering.
- Groceries / shops / everyday goods.
- Global travel: flights, accommodation, buses/coaches/rail/ferries where supported, airport transfers, itinerary management and destination services through specialised travel integrations.

## Design principle: shared core plus specialised verticals

Do not force every transaction into the taxi `rides` table. Keep a shared marketplace core for concepts that are common across services, and use specialised tables/workflows where a vertical has materially different behaviour.

```text
                         Wantok Services
                               |
              +----------------+----------------+
              |                                 |
        Shared marketplace                 Vertical modules
              |                                 |
  +-----------+-----------+          +-----------+-----------+
  | Identity / profiles   |          | Rides                 |
  | Provider verification |          | Delivery / errands    |
  | Service catalogue     |          | Food / shopping       |
  | Listings / resources  |          | Events / tickets      |
  | Bookings / quotes     |          | Travel integrations   |
  | Reviews               |          +-----------------------+
  | Payments / settlement |
  | Notifications / chat  |
  +-----------------------+
```

## Shared marketplace model

### `service_categories`

Defines the catalogue and booking style. Categories include on-demand, scheduled, quote-based, reservation, commerce and ticketing services.

### `provider_profiles`

A generic provider identity for an individual, business or organisation. It is separate from customer identity and can coexist on the same user account.

### `provider_services`

The actual services a verified provider offers. Examples:

- an electrician offering hourly work;
- a consultant offering quote-based work;
- a vehicle company offering daily 4WD hire;
- a venue operator offering conference-room reservations;
- a food vendor participating in the commerce module.

### `provider_resources`

Bookable physical resources owned or managed by a provider, such as:

- cars and 4WDs;
- boats and dinghies;
- halls and conference rooms;
- fields or event spaces;
- later equipment or accommodation inventory.

### `service_bookings`

Generic booking/request lifecycle for non-ride services. It supports targeted provider bookings and open requests where qualified providers can quote.

Typical lifecycle:

```text
requested -> quoted -> confirmed -> in_progress -> completed
     |          |            |
     +----------+------------+--> cancelled / rejected / expired
```

### `service_quotes`

Supports competitive or negotiated work such as building work, electrical jobs, consultants, general labour and errands where a price is not known before the provider reviews the request.

### `service_reviews`

Shared ratings/reviews for completed marketplace bookings. Ride ratings can later use the same presentation layer while retaining ride-specific records.

## Specialised ride module

Taxi/ride-hailing remains specialised because it requires:

- driver online/offline state;
- continuous location updates;
- nearest-driver matching;
- dispatch locking/concurrency control;
- fast status changes;
- route distance and ETA;
- background location;
- safety and trip tracking.

The existing `rides`, `driver_profiles` and `driver_locations` tables therefore remain separate from generic marketplace bookings.

## Provider model

A user can hold multiple provider capabilities. For example, one person may be an approved taxi driver and also offer vehicle hire or translation services.

Provider onboarding should evolve toward:

1. Choose one or more service categories.
2. Supply identity/business documents.
3. Supply category-specific documents and qualifications.
4. Admin verifies the provider.
5. Provider creates service listings/resources.
6. Listings/resources are reviewed where required.
7. Provider receives requests/orders/jobs in the Provider area.

## Customer navigation

Keep one customer-facing Services hub rather than a bottom tab for every service. Each service opens its own route/stack.

The current client navigation decision is locked as:

**Home · Services · Track · Wallet · Inbox**

Global travel, international discovery and itineraries must live within this product hierarchy rather than creating a permanent tab for every vertical. Account/Profile remains outside the bottom bar. Provider and administrative authority remain role/permission driven rather than being granted by client navigation.

## Future shared platform services

These should be designed once and reused across all verticals:

- Wallet/payment intents and provider settlement.
- Cash, mobile-money and card payment adapters.
- Promotions/rewards.
- In-app and push notifications.
- Chat between customer and assigned provider.
- Safety/SOS and incident reporting.
- Identity/KYC/document verification.
- Fraud/risk controls.
- Disputes/refunds.
- Audit log.
- Search/discovery and location-aware ranking.
- Provider availability/calendars.
- Media/document storage.

## Wantok Neurons integration boundary

Wantok Services remains the user-facing transaction platform. Wantok Neurons may later provide intelligence through APIs for support chat, translation, voice booking, OCR/KYC assistance, fraud detection, route optimisation, listing generation and travel assistance. Core bookings, payments, provider state and customer records remain owned by Wantok Services.

## Current engineering rule

Build new capabilities against the shared marketplace core unless the vertical has a clear reason for a specialised data model. Preserve committed checkpoints and use migrations for every backend schema change.
