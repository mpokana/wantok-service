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
| Services discovery | Search/family filters; errors/empty states; Saved controls; privacy-aware **For you** recommendations; **Explore PNG** places generated only from structured active verified service coverage | Automated PASS; live bookmark/recommendation/place QA pending |
| Profile & identity | Personal profile, bio, managed private avatar upload, separate Business/Vendor profile | Implemented; signed-in visual/media QA pending |
| Linked accounts | Google/Facebook Supabase identity-linking UI; email sign-in remains visible | Implemented; provider OAuth configuration/live flow pending |
| Privacy | Profile/review visibility, saved privacy, recommendation opt-out and profile-sharing settings; recommendation opt-out enforced in the RPC | Database/API/UI implemented; live QA pending |
| Saved | Owner-scoped saved-entity store, secured validation RPC, Saved screen, category/provider/resource/event Save controls | pgTAP PASS; live interaction QA pending |
| Trusted people / delegated booking | Owner-scoped family/relative/staff records; shared beneficiary selector and snapshot contracts | PASS across generic reservations/open requests, Taxi/Ride, Events, Commerce and scheduled Water transport |
| Reviews | Existing booking-linked review model extended with title/managed review photos/visibility; secured completed-booking RPC; Track Review/Edit action | pgTAP PASS; live completed-booking/media QA pending |
| Activity/Track | Existing specialised ride/order/event/water links plus generic booking review path | Automated baseline PASS; populated live records pending |
| Wallet | Kina K; Top up/Scan/Send/Receive preview, verification, PNG planned services, recent-activity framing | Automated PASS; no transaction movement |
| Role boundary | Client/Vendor switch does not grant provider or technical authority | Automated PASS; pgTAP baseline retained |
| Database | CX1/CX1B/CX1C/CX1D/CX1E migrations and security tests | 25 files / 564 pgTAP tests PASS |
| Flutter client | Analysis plus existing regression suite | 34 tests PASS |
| Visual evidence | Earlier shell QA exists; CX1A surfaces require fresh Android/Web evidence | PENDING |

## CX1A implemented changes

- Migrations `20261006130000_cx1_client_experience_foundations.sql`, `20261006140000_delegated_booking_foundation.sql`, `20261006141000_taxi_delegated_booking.sql`, `20261006142000_event_delegated_booking.sql`, `20261006143000_commerce_delegated_booking.sql`, `20261006144000_water_delegated_booking.sql`, `20261006145000_client_media_storage.sql`, `20261007015000_client_media_ownership_hardening.sql`, `20261007062000_client_service_recommendations.sql`, `20261007063000_client_recommendation_acl_hardening.sql`, and `20261007065000_png_service_place_discovery.sql` are applied locally.
- `profiles` adds avatar URL and bio foundation.
- `account_preferences` adds profile visibility, review visibility, saved-item privacy, recommendation opt-in and profile-sharing controls.
- `client_saved_items` is owner-scoped and RPC-only for ordinary bookmark access; the server validates that an entity is still discoverable before saving/showing it.
- `trusted_people` is owner-scoped with RLS and now feeds the shared delegated-booking contract. `service_bookings` snapshots beneficiary name/relationship/phone/email while retaining the authenticated customer as `customer_id`; source deletion clears only the Trusted-person foreign key.
- `service_reviews` reuses the existing booking-linked review system and adds title, photo URL list and visibility.
- Direct authenticated review insertion was removed; `submit_service_review` enforces completed customer-booking eligibility.
- Existing provider-rating aggregation remains the source of provider rating averages/counts.
- `AccountPage` exposes Privacy & sharing, Linked accounts, Saved, Trusted people and My reviews.
- managed client media now stores profile avatars and review photos in the private `client-media` Supabase Storage bucket. The app stores stable `storage://client-media/...` references, resolves signed URLs for display, limits uploads to JPG/PNG/WebP up to 5 MiB each, and binds managed references to the owning account folder.
- Personal and Business/Vendor profiles remain separate identities under the same Wantok login.
- `ServicesHubPage` remains the client discovery hub, supports Saved controls, presents a compact **For you** strip, and now adds **Explore PNG**. Providers can attach structured province/town coverage to services, resources and events, plus origin/destination coverage to water routes. The client RPC aggregates only active verified coverage; free-text addresses are deliberately ignored for destination creation. A covered-place sheet lists only service categories actually available there. Recommendation location remains cached/permission-respecting and `allow_recommendations = false` returns no personalised recommendations.
- structured PNG place metadata is stored on each service/resource/event/water-route endpoint rather than inferred from provider headquarters or free-text addresses. `list_client_service_places` exposes only active verified coverage, and `ServicesHubPage` renders those results as **Explore PNG** place cards that open the service types genuinely covered there.
- `ActivityPage` / Track now offers Review service / Edit review for eligible completed generic bookings.
- Wantok Pay remains preview-only. No payment adapters, balance ledger, settlement or custody logic was added.

## Coverage limits and remaining CX1 work

1. Delegated booking is complete across every currently implemented client service family: Vehicle Hire, Boat Hire, Venue Booking, Delivery, Errands/Pabili, Specialist Services, General Labour, Taxi/Ride, Events/ticketing, Food/Groceries commerce and scheduled Boat/Ship passenger transport. The signed-in customer remains the payer/requesting account; beneficiary identity must not confer account access. Future accommodation/flights modules should explicitly adopt or reject this shared contract during their design phase.
2. Add achievements/rewards only after core consumer workflows are stable.
3. Defer follow/follower/social metrics until privacy, abuse/moderation and notification design are approved.
4. Perform fresh signed-in Android/Web QA on Account tools, avatar/review-photo upload, Services bookmarks/recommendations/Explore PNG, Track reviews and Wallet.
5. Verify Taxi map/location permission handling and populated Track/Inbox/account records without creating destructive test data.
6. Run the final CX1 evidence review and keep T2.4 deferred until the client gate is complete.

## Safety boundaries

- Do not reset/reseed local Supabase or replace local development accounts.
- Do not enable Wantok Pay movement before payment-rail, settlement, custody and regulatory decisions are approved.
- Do not copy Grab branding/layout. Use only product concepts adapted to Wantok Services and PNG.
- Keep **Home · Services · Track · Wallet · Inbox** unless Mansfield explicitly approves a future navigation redesign.
