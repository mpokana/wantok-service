# CX1 — Client Experience Completion Gate

**Status:** IN PROGRESS; CX1A foundation implemented, live gate evidence still open before T2.4.
**Environment:** EAGLT02 local development; existing accounts/data preserved.
**T2.3 checkpoint:** `46d6208`.
**Prior CX1 reliability/discovery checkpoint:** `0c33a37`.

## Locked client navigation

Wantok Services keeps its own five-button bottom navigation:

**Home · Services · Track · Wallet · Inbox**

This is intentional and must not be renamed to Grab-style Discover / Activity / Payment / Messages. The product concepts are adapted, not cloned:

- **Services** owns discovery, browse, search, saved items and local service exploration.
- **Track** owns ongoing/scheduled/completed service activity, messaging entry points and reviews.
- **Wallet** owns Wantok Pay preview and future payment history.
- **Inbox** owns messages/updates.
- Profile/Account remains outside the bottom bar.

## Acceptance and evidence

| Area | Evidence at this checkpoint | Status |
| --- | --- | --- |
| Client shell | Five Wantok tabs, Home search/profile/back; selected-tab semantics | Automated PASS; live QA pending |
| Services discovery | Search/family filters; errors/empty states; Saved shortcut and category bookmarks | Automated baseline PASS; live bookmark QA pending |
| Profile & identity | Personal profile, bio/avatar URL foundation, separate Business/Vendor profile | Implemented; signed-in visual QA pending |
| Linked accounts | Google/Facebook Supabase identity-linking UI; email sign-in remains visible | Implemented; provider OAuth configuration/live flow pending |
| Privacy | Profile/review visibility, saved privacy, recommendations and profile-sharing settings | Database/API/UI implemented; live QA pending |
| Saved | Owner-scoped saved-entity store, secured validation RPC and Saved screen | pgTAP PASS; provider/resource/event Save controls still pending |
| Trusted people / delegated booking | Owner-scoped family/relative/staff records; shared beneficiary selector and snapshot contracts | Generic reservations/open requests + Taxi/Ride + Events + Commerce PASS; Water module pending |
| Reviews | Existing booking-linked review model extended with title/photo URLs/visibility; secured completed-booking RPC; Track Review/Edit action | pgTAP PASS; live completed-booking QA pending |
| Activity/Track | Existing specialised ride/order/event/water links plus generic booking review path | Automated baseline PASS; populated live records pending |
| Wallet | Kina K; Top up/Scan/Send/Receive preview, verification, PNG planned services, recent-activity framing | Automated PASS; no transaction movement |
| Role boundary | Client/Vendor switch does not grant provider or technical authority | Automated PASS; pgTAP baseline retained |
| Database | CX1/CX1B migrations and security tests | 21 files / 492 pgTAP tests PASS |
| Flutter client | Analysis plus existing regression suite | 32 tests PASS |
| Visual evidence | Earlier shell QA exists; CX1A surfaces require fresh Android/Web evidence | PENDING |

## CX1A implemented changes

- Migrations `20261006130000_cx1_client_experience_foundations.sql`, `20261006140000_delegated_booking_foundation.sql`, `20261006141000_taxi_delegated_booking.sql`, `20261006142000_event_delegated_booking.sql`, and `20261006143000_commerce_delegated_booking.sql` are applied locally.
- `profiles` adds avatar URL and bio foundation.
- `account_preferences` adds profile visibility, review visibility, saved-item privacy, recommendation opt-in and profile-sharing controls.
- `client_saved_items` is owner-scoped and RPC-only for ordinary bookmark access; the server validates that an entity is still discoverable before saving/showing it.
- `trusted_people` is owner-scoped with RLS and now feeds the shared delegated-booking contract. `service_bookings` snapshots beneficiary name/relationship/phone/email while retaining the authenticated customer as `customer_id`; source deletion clears only the Trusted-person foreign key.
- `service_reviews` reuses the existing booking-linked review system and adds title, photo URL list and visibility.
- Direct authenticated review insertion was removed; `submit_service_review` enforces completed customer-booking eligibility.
- Existing provider-rating aggregation remains the source of provider rating averages/counts.
- `AccountPage` exposes Privacy & sharing, Linked accounts, Saved, Trusted people and My reviews.
- Personal and Business/Vendor profiles remain separate identities under the same Wantok login.
- `ServicesHubPage` remains the client discovery hub and now supports saving service categories.
- `ActivityPage` / Track now offers Review service / Edit review for eligible completed generic bookings.
- Wantok Pay remains preview-only. No payment adapters, balance ledger, settlement or custody logic was added.

## Coverage limits and remaining CX1 work

1. Delegated booking is complete for Vehicle Hire, Boat Hire, Venue Booking, Delivery, Errands/Pabili, Specialist Services, General Labour, Taxi/Ride, Events/ticketing and Food/Groceries commerce. Continue with scheduled Boat/Ship passenger transport. The signed-in customer remains the payer/requesting account; beneficiary identity must not confer account access.
2. Extend Save controls to providers, venues/resources and events, not only service categories.
3. Add managed Supabase Storage/image-upload flows for avatars and review photos; URL columns are only the current data foundation.
4. Implement recommendation logic only after real saved/history/location inputs are available and honour the recommendation opt-out.
5. Add PNG province/town/destination discovery driven by real service coverage rather than hard-coded destination buttons.
6. Add achievements/rewards only after core service flows are stable.
7. Defer follow/follower/social metrics until privacy, abuse/moderation and notification design are approved.
8. Perform fresh signed-in Android/Web QA on Account tools, Services bookmarks, Track reviews and Wallet.
9. Verify Taxi map/location permission handling and populated Track/Inbox/account records without creating destructive test data.
10. Run full project checkpoint validation and keep T2.4 deferred until CX1 evidence is complete.

## Safety boundaries

- Do not reset/reseed local Supabase or replace local development accounts.
- Do not enable Wantok Pay movement before payment-rail, settlement, custody and regulatory decisions are approved.
- Do not copy Grab branding/layout. Use only product concepts adapted to Wantok Services and PNG.
- Keep **Home · Services · Track · Wallet · Inbox** unless Mansfield explicitly approves a future navigation redesign.
