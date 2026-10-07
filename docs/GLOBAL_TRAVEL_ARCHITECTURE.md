# Wantok Services — Global Travel Architecture

**Status:** PLANNED architecture. Do not implement ahead of the current CX1 completion gate.

## Product decision

Wantok Services is a global platform launched from Papua New Guinea. PNG remains the home market and first-class launch experience, but the platform core must support customers, providers and travel inventory across countries.

Global travel is a specialised Wantok vertical, not a copy of generic local service booking. It must still reuse the shared Wantok account, Track, Inbox, Wallet/payment-intent boundary, notifications, reviews, safety, audit and Wantok Agent.

## Global market foundation

Before global commerce/travel scales, shared data contracts must be country-aware:

- country and subdivision codes rather than PNG-only enums;
- IANA time zones and UTC-normalised timestamps;
- ISO-style currency codes and money represented as currency + minor units/decimal amount, never an implicit single currency;
- locale/language preferences with fallback;
- E.164-style phone-number storage/normalisation where possible;
- country-aware postal/address structures instead of assuming province/town only;
- market capability/configuration records controlling which services, payment rails and provider types are available by country/region;
- tax/regulatory and consumer-protection metadata separated from UI text;
- distance/unit formatting as presentation, not storage authority;
- explicit source/provider identifiers for third-party inventory and quoted prices.

The current **Explore PNG** experience remains valid for the PNG launch market. It should later become a market-aware **Explore** experience that can select/derive country and destination without removing PNG-specific discovery.

## Travel domain boundary

Travel should use dedicated domain objects because airline/hotel inventory has offer expiry, supplier confirmation and change/refund rules that do not fit ordinary marketplace bookings.

Recommended future concepts:

### Trip / itinerary

A user-owned trip container with:
- title and destination summary;
- start/end dates;
- home/origin time zone;
- travellers;
- itinerary items;
- notes/documents;
- booking/payment references;
- sharing/delegation controls.

An itinerary may combine:
- flights;
- accommodation;
- airport transfers;
- rail/bus/ferry legs where supported;
- vehicle hire;
- local Wantok taxi/ride;
- events/tickets;
- local providers, tours or services;
- reminders and free-form itinerary items.

### Traveller

Traveller identity is distinct from account ownership and payment authority.

Store only information necessary for the selected supplier/workflow, such as:
- legal name;
- date of birth where required;
- nationality;
- loyalty-program reference;
- required travel-document references.

Sensitive passport/identity data needs a dedicated protected-document design. Do not expose raw document values broadly to staff or AI tools.

The signed-in customer remains the booking owner unless an approved delegated-booking rule explicitly states otherwise.

### Travel search and offer

A travel search creates ephemeral supplier offers.

Flight offer data should preserve at minimum:
- origin/destination;
- departure/arrival date-time with source time zone;
- operating/marketing carrier details where supplied;
- flight/segment identifiers;
- cabin/fare brand;
- baggage allowance;
- stops/layovers;
- total price, taxes/fees and currency;
- fare/change/refund conditions where provided;
- supplier/source;
- supplier offer ID;
- offer expiry/revalidation requirement.

A displayed price is not a confirmed booking. Offers must be revalidated before commitment.

### Travel order / booking

Travel purchase lifecycle should be independent of generic service-booking status.

Indicative state model:

```text
draft
  -> offer_selected
  -> revalidating
  -> awaiting_customer_approval
  -> payment_authorising
  -> supplier_booking
  -> confirmed/ticketed
       -> changed
       -> cancelled
       -> refund_pending
       -> refunded
```

Supplier-specific states remain mapped behind adapters. Wantok should never show **ticketed/confirmed** until the external supplier confirms that state.

## Supplier integration boundary

Use replaceable server-side adapters for:
- airline direct/NDC sources;
- GDS/travel-content providers;
- hotel/accommodation inventory;
- rail/bus/ferry suppliers;
- travel insurance or other later approved products.

Do not leak supplier-specific payloads into client business logic.

The client calls Wantok APIs. Wantok server-side services:
1. validate permission/context;
2. call configured supplier adapters;
3. normalise results;
4. persist only required references/state;
5. audit external calls and state transitions.

API credentials, signing keys, OAuth tokens and supplier secrets belong in Technical Control/secret references, never in the public client.

## Wantok Agent — global travel role

Wantok Agent should become the conversational travel orchestrator for the platform.

It may:
- understand a natural-language trip request;
- ask for missing origin, destination, dates, traveller count and preferences;
- search authorised flight/accommodation/transport inventory through controlled tools;
- compare valid offers;
- explain stops, duration, baggage, fare conditions and trade-offs from returned supplier data;
- assemble a multi-day itinerary;
- combine international travel with local Wantok services at the destination;
- surface accommodation, airport transfers, taxi/ride, vehicle hire, events and local providers;
- track confirmed itinerary items and explain status;
- propose alternatives when a supplier offer expires or changes;
- prepare booking/checkout steps;
- create reminders and disruption/help hand-offs later.

It must not:
- invent live fares, availability, entry/visa requirements or supplier policies;
- call arbitrary supplier endpoints or databases;
- expose another traveller's protected identity information;
- autonomously spend money;
- ticket, cancel, change or refund travel without the authority/confirmation defined by the workflow;
- bypass supplier, fraud, KYC, payment, age or regulatory controls.

### Explicit approval boundary

The Agent can prepare a booking basket and say what will be purchased, but commitment requires an explicit user approval step showing at least:
- travellers;
- selected itinerary/offer;
- current revalidated total and currency;
- major fare/refund/change conditions available from the source;
- payment method/rail when enabled;
- any Wantok service/booking fee;
- supplier/booking terms acknowledgement where required.

Material changes after approval (price increase, changed flight, changed hotel room/rate, added fee) require re-approval.

## Track and Inbox

**Track** should become the lifecycle view for the user's trip and booked travel items, not just local service activity.

Travel Track cards may show:
- upcoming trip countdown;
- flight status/terminal/gate when a trusted real-time source exists;
- check-in window;
- hotel check-in/out;
- transfer/ride status;
- changes/cancellations/refunds;
- itinerary timeline.

**Inbox** should separate supplier/system travel updates from provider conversations and Help & support while preserving the existing authority model.

## Wallet and payments

Wantok Wallet remains a payment-intent/settlement boundary until payment rails are approved.

Global travel requires:
- multi-currency amounts;
- quote currency vs settlement currency where applicable;
- supplier amount vs Wantok service fee;
- taxes/fees;
- authorisation/capture/refund references;
- partial/full refund handling;
- exchange-rate source/time if Wantok presents converted estimates.

Never silently treat supplier funds as Wantok revenue.

## Operations and Technical administration

**Wantok Operations Admin** should handle:
- customer support and booking exceptions;
- supplier booking review where human intervention is required;
- approved manual actions;
- cancellation/refund cases;
- itinerary/service incidents;
- fraud/risk escalations;
- commercial/service-fee configuration where authorised.

**Wantok Technical Control** should handle:
- travel adapter configuration;
- supplier API credentials/secret references;
- webhook/callback health;
- provider capability/health;
- technical diagnostics and job failures.

Technical integration authority must not automatically grant commercial booking/refund authority.

## Reliability and audit

Every external travel action must be idempotent where supported and auditable.

Record:
- Wantok request/correlation ID;
- user/actor;
- supplier adapter;
- external request/reference ID;
- previous/new state;
- price/currency at approval and at supplier confirmation;
- timestamps;
- failure/retry information;
- manual intervention and reason.

Do not retry purchase/ticket/refund commands blindly.

## Sequencing

1. Finish current CX1 evidence and T2.4 as already gated.
2. Add global market/country/currency/time-zone foundations without breaking PNG.
3. Implement provider-agnostic Wantok Agent tool gateway and permission/audit model.
4. Add read-only travel search/itinerary composition first.
5. Add travel-order/offer revalidation and explicit-approval workflow.
6. Add payment/ticketing only after Wallet/payment and supplier-commercial decisions are approved.
7. Add disruption, change, cancellation and refund workflows.
8. Expand destination-local Wantok service orchestration.

No current PNG workflow should be rewritten merely to introduce global travel.
