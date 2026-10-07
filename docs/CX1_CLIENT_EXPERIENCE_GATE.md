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
| Client shell | Five Wantok tabs, Home search/profile/back; selected-tab semantics; compact Wantok Agent client-header action | Automated PASS; fresh Android Home/Services/Agent visual PASS |
| Services discovery | Search/error/empty states; Saved controls; privacy-aware **For you** recommendations; **Explore PNG** places; shared enterprise taxonomy **Move & travel · Food & shopping · Send & errands · People & skills · Book & events** drives both filters and grouped catalogue | Automated PASS; signed-in Android grouped catalogue, retained Saved provider, live recommendation opening Specialist Services, and Explore PNG Lae/Morobe place sheet PASS |
| Provider discovery | Empty-state evidence was followed by one deliberately labelled non-commercial local QA provider created through the normal approval workflow. Signed-in Android now verifies populated `plumber` search, Specialist Services → Morobe → Lae filters, 5.0 (1) rating, Saved persistence and approved-service storefront/detail. | Android PASS; Web QA pending |
| Wantok Agent | User-facing assistant renamed **Wantok Agent** and moved from a large Home card to a compact client-header action. Signed-in Android capability status, plumber-search fallback, disabled model input and Talk to a person submission verified; one persisted owner request confirmed. | Android entry/handoff PASS; owner request now also surfaces under Inbox Help & support; staff triage/live human chat/model gateway and Web remain |
| Inbox | Booking-linked provider conversations remain authoritative under **Services**; owner-private Wantok Agent handoff requests surface separately under **Help & support** with status/detail. The two sources fail independently so one backend cannot take down the whole Inbox. | Automated category/fault-isolation PASS; signed-in Android Services (0) / Help & support (1) and support-detail PASS; live human chat remains disabled by capability contract |
| Profile & identity | Personal profile, bio, managed private avatar upload, separate Business/Vendor profile | Signed-in Android Account shell/profile visual PASS; avatar upload/media mutation QA pending |
| Linked accounts | Google/Facebook Supabase identity-linking UI; email sign-in remains visible | Signed-in Android UI PASS: Email & password Connected; Google/Facebook Connect actions visible. Provider OAuth configuration/live linking remains pending |
| Privacy | Profile/review visibility, saved privacy, recommendation opt-out and profile-sharing settings; recommendation opt-out enforced in the RPC | Signed-in Android privacy surface PASS: Private profile, Public default reviews, saved privacy, recommendations and profile-sharing controls rendered; mutation/save QA remains |
| Saved | Owner-scoped saved-entity store, secured validation RPC, Saved screen, category/provider/resource/event Save controls | pgTAP PASS; Android Save persistence and Account Saved page PASS with retained provider; other entity types remain pending |
| Trusted people / delegated booking | Owner-scoped family/relative/staff records; shared beneficiary selector and snapshot contracts | Backend/delegated flows PASS; signed-in Android Trusted people empty state and Add person entry PASS; live create/edit/delete QA still pending |
| Reviews | Existing booking-linked review model extended with title/managed review photos/visibility; secured completed-booking RPC; Track Review/Edit action | pgTAP PASS; Account My reviews PASS with retained 5-star public QA review; Track Edit review entry PASS; edit/photo mutation QA pending |
| Activity/Track | Existing specialised ride/order/event/water links plus generic booking review path; PostgREST embedded to-one/to-many quote/review rows are normalised; records are grouped as Ongoing / Scheduled / Completed | Automated grouping + embedded-relation regressions PASS; retained completed booking live Android PASS; other populated live states pending |
| Taxi / Ride | Current-location pickup, map point selection, delegated-beneficiary selector, explicit Request ride action and passenger history | Signed-in Android read-only runtime PASS: location service enabled, fine/coarse permission granted, Pickup populated as Current location, retained cancelled ride shown under Recent rides with fare; no ride request submitted |
| Wallet | Kina K; Top up/Scan/Send/Receive preview, verification, PNG planned services, recent-activity framing | Automated + signed-in Android visual PASS; K0.00 preview and all payment actions remain non-clickable; no transaction movement |
| Role boundary | Client/Vendor switch does not grant provider or technical authority | Automated PASS; pgTAP baseline retained |
| Database | CX1 through CX1I foundation migrations and security tests | 27 files / 598 pgTAP tests PASS |
| Flutter client | Analysis plus existing regression suite including compact Wantok Agent header action, enterprise service taxonomy, Track relation/grouping logic, responsive Inbox categories and source fault isolation | **42 tests PASS** |
| Visual evidence | Fresh signed-in Android Home/Services/Agent, populated provider discovery, For you/Explore PNG interactions, Taxi current-location/history runtime, Track Completed history, Account privacy/linked/saved/trusted/reviews, Wallet preview and categorised Inbox/support-detail QA on 2026-10-07 confirms the locked five-button Wantok navigation without visible overflow; remaining mutation/other populated journey/Web evidence still required | PARTIAL PASS |

## CX1 implemented changes

- Migrations `20261006130000_cx1_client_experience_foundations.sql`, `20261006140000_delegated_booking_foundation.sql`, `20261006141000_taxi_delegated_booking.sql`, `20261006142000_event_delegated_booking.sql`, `20261006143000_commerce_delegated_booking.sql`, `20261006144000_water_delegated_booking.sql`, `20261006145000_client_media_storage.sql`, `20261007015000_client_media_ownership_hardening.sql`, `20261007062000_client_service_recommendations.sql`, `20261007063000_client_recommendation_acl_hardening.sql`, `20261007065000_png_service_place_discovery.sql`, `20261007071000_provider_service_discovery.sql`, and `20261007072000_wantok_ai_agent_foundation.sql` are applied locally.
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
- `ServicesHubPage` remains the client discovery hub, supports Saved controls, presents a compact **For you** strip, and now adds **Explore PNG**. Structured province/town coverage lives on each service, resource and event, while water routes carry origin/destination coverage. `list_client_service_places` aggregates only active verified coverage; free-text addresses and provider headquarters are deliberately not treated as destinations. A covered-place sheet lists only service categories genuinely available there. Recommendation location remains cached/permission-respecting and `allow_recommendations = false` returns no personalised recommendations.
- CX1F provider discovery adds `search_client_providers`/`list_top_client_providers`, confidence-aware organic ranking, daily Top Wantoks rotation, 1–5 star/review-count cards, provider storefront/detail, Saved provider controls, and client category/province/town filters backed by structured coverage.
- CX1I exposes the user-facing **Wantok Agent** as a compact global client-header action, with authenticated capability RPC, real provider-search examples and an owner-private human-help handoff queue. The former large Home Agent card is removed. Model chat, privileged actions and money movement remain disabled; staff triage/model gateway are later work. Internal API/database compatibility names remain `WantokAiAgent*` / `wantok_ai_agent`.
- `ActivityPage` / Track now offers Review service / Edit review for eligible completed generic bookings.
- Wantok Pay remains preview-only. No payment adapters, balance ledger, settlement or custody logic was added.

## Android evidence — 2026-10-07 continuation from b69656b

- EAGLT02 branch `feature/flutter-platform-v1` was clean at `b69656b`. The prior debug APK build completed: Gradle daemon log `daemon-66820.out.log` records the Android build finishing and dispatching Success at 08:32:04 PGT; APK and SHA-1 sidecar were produced at 08:32:04/06. This continuation attempted a rebuild with `.wantok/local-android.json`; both normal and IPv4 retries failed with `java.io.IOException: Unable to establish loopback connection`. Those retries are not build PASS evidence.
- Installed the completed prior APK with `adb install -r` on existing `emulator-5554` / `Medium_Phone_API_36.1`: Success. Package `io.wantok.service`, debug version `0.1.0`/3; first install remains `2026-10-05 23:44:14`, last update `2026-10-07 08:56:03`. APK SHA-256: `E110324CA7E2A3C256A21C361258CC2BE547A3CFEC69CC4A408F050E644D3C81`.
- Existing Mansfield session survived; Account showed the existing profile, and local Auth/Profile counts remained 2/2. No app clear/uninstall, AVD wipe, Supabase reset/reseed or role change was performed. Home and Services retained **Home · Services · Track · Wallet · Inbox** without visible overflow in captured screens.
- Services → Find providers and Agent → Find a plumber opened the real provider-discovery page. `plumber` returned No matching providers; clearing returned Top Wantoks with the same empty state. Category/province menus opened with only All categories/All provinces; town was disabled. Read-only database counts confirmed **0 provider profiles / 0 provider services**. Populated category/province/town selection, rating cards, provider save/persistence and storefront/detail were **not verifiable**; no provider fixtures were created or approved.
- Wantok Agent loaded capability status, displayed AI chat is being prepared, and kept model input disabled. Talk to a person accepted the clearly labelled QA summary, closed the dialog and showed Your help request was sent for human follow-up. Read-only database verification confirmed one new `open` request `640eded2-0367-402a-8555-1252b306acb0`, owned by the existing Mansfield profile, at 08:58:47 PGT with context `source=wantok_ai_agent`, `chat_enabled=false`. The summary explicitly says no operational assistance is required. Request retained for evidence; no staff response or live human chat was claimed.
- Local evidence is retained in ignored `.wantok/`: `cx1-home.png`, `cx1-services-current.png`, `cx1-provider-plumber.png`, `cx1-provider-top-empty.png`, category/province option PNG/XML captures, `cx1-agent-ready.png`, `cx1-human-entry.png`, `cx1-handoff-form.png`, `cx1-handoff-filled.png`, `cx1-handoff-result.png`, `cx1-account-confirmed.png`; build attempt logs and `cx1-flutter-check-20261007.log` / `cx1-db-test-20261007.log`. Captures are local artifacts, not tracked Git files.
- Fresh full checkpoint checks: `scripts/flutter/check.ps1` PASS (seven analysis targets, Wantok app 34 tests, Admin/Technical one smoke test each); `npm run db:test` PASS (27 files / 598 tests). Standard process-only `PROGRAMFILES(X86)` value supplied. CX1 remains open; T2.4 deferred; CX1G not started.

## Populated provider Android evidence — 2026-10-07 after 4fe0a34

- The earlier **0 provider profiles / 0 provider services** state above is retained as historical evidence. To close the populated Android CX1F gap without bypassing verification, one clearly labelled **non-commercial local QA provider** was created using the existing authenticated workflow: provider application → Operations/Admin approval → provider-owned listing update → provider service review submission → Admin activation. No Mansfield role change, direct verified-provider insert, Supabase reset/reseed or payment movement was used.
- Local QA provider **Wantok QA Plumbing Services** is a verified active business provider. Active service **QA Plumber & Maintenance** is in **Specialist Services**, with structured coverage **Morobe / Lae** and QA metadata stating it is non-commercial.
- A single QA service booking owned by the existing Mansfield account was accepted by the provider, advanced through `in_progress` to `completed`, then reviewed through secured `submit_service_review`. This produced a real provider aggregate of **5.0 (1 review)**. The booking/review explicitly states that no commercial service was rendered.
- Signed-in Android populated discovery PASS: Top Wantoks/rating card rendered; `plumber` search returned the provider; **Specialist Services → Morobe → Lae** filters selected successfully and retained the correct result.
- Android provider Saved interaction PASS: tapping **Save provider** created the owner-scoped `client_saved_items` provider bookmark for Mansfield and the live control changed to **Remove from saved**.
- Android storefront/detail PASS: provider detail showed **Business**, **5.0 (1)**, Morobe coverage, and the active approved **QA Plumber & Maintenance — Specialist Services — Lae, Morobe — Quote** listing.
- Evidence is retained only under ignored `.wantok/`, including the QA workflow/log, populated-filter/search XML/PNG captures, Saved-state capture and provider-detail capture.
- Emulator stability investigation found the first software-rendered/audio-enabled cold run later exited after repeated Windows `UpdateLayeredWindowIndirect` failures plus DirectSound startup failure. The replacement visible run using host GPU plus `-no-audio`, cold boot and snapshots disabled booted successfully and remained responsive through the populated QA and full Flutter checkpoint. Persistent AVD defaults were changed without wiping userdata to cold boot, Fast Boot off, 4 CPU cores, host GPU and audio input off; ignored `.wantok/start-wantok-emulator.ps1` preserves the working launch flags.
- Retaining the new QA provider and earlier AI handoff correctly exposed three pgTAP files that assumed an otherwise empty local database. Tests 025–027 were hardened so place/provider counts and support handoff updates are scoped to their own deterministic fixture rows. The full suite now passes with preserved development data: **27 files / 598 tests PASS**.
- Fresh full Flutter checkpoint after the populated QA remains PASS: all seven analysis targets, **34 Wantok app tests**, Operations Admin smoke and Technical Control smoke.
- **Android CX1F provider-discovery evidence is now PASS. Web CX1F QA remains open.** CX1 overall remains open; T2.4 remains deferred and CX1G has not started.

## Client information architecture Android evidence — 2026-10-07

- User-facing assistant naming is now **Wantok Agent**. The large Home Agent card is removed and the Agent is exposed as a compact sparkle action in the client app bar; tapping it opens the existing controlled Agent guide.
- Wantok Pay is no longer duplicated on Home. The locked **Wallet** tab remains the authoritative Wantok Pay surface, and payment movement is still disabled.
- Home is intentionally shortcut-first: scenic search hero, six high-frequency **Quick access** services, **See all** routing to Services, then lightweight service spotlights. The complete catalogue is not duplicated on Home.
- `service_catalog_taxonomy.dart` centralises client information architecture as **Move & travel**, **Food & shopping**, **Send & errands**, **People & skills**, and **Book & events**. Services uses this same taxonomy for compact filters and grouped default catalogue panels while backend service categories remain independently managed.
- Fresh debug APK built and installed in place with `adb install -r`; existing sign-in, Supabase data and AVD userdata were preserved. Live Android captures under ignored `.wantok/` confirm the simplified Home, grouped Services catalogue and renamed Wantok Agent without visible overflow.
- The initial build attempt hit the known generated `cleanMergeDebugAssets` file lock. Stopping the Gradle daemon and clearing only generated `apps/wantok_app/build` resolved it; the retry produced `app-debug.apk` successfully.
- Track continuation normalises PostgREST embedded quote/review relationships whether returned as a single object or list, with a dedicated regression test.
- Track now groups shared service records into **Ongoing · Scheduled · Completed** sections with tested status/time classification. Fresh signed-in Android QA against the retained completed plumbing QA booking shows **Completed (1)** with provider, location, Message provider and Edit review controls; no new booking data was created for this evidence.
- Fresh full checkpoint after this hierarchy change PASS: all seven Flutter analysis targets, **40 Wantok app tests**, Operations Admin smoke, Technical Control smoke, and **27 files / 598 pgTAP tests**.

## Coverage limits and remaining CX1 work

1. Delegated booking is complete across every currently implemented client service family: Vehicle Hire, Boat Hire, Venue Booking, Delivery, Errands/Pabili, Specialist Services, General Labour, Taxi/Ride, Events/ticketing, Food/Groceries commerce and scheduled Boat/Ship passenger transport. The signed-in customer remains the payer/requesting account; beneficiary identity must not confer account access. Future accommodation/flights modules should explicitly adopt or reject this shared contract during their design phase.
2. Add achievements/rewards only after core consumer workflows are stable.
3. Defer follow/follower/social metrics until privacy, abuse/moderation and notification design are approved.
4. Continue fresh signed-in Android/Web QA on Account tools, avatar/review-photo upload, Services bookmark interaction/recommendations/Explore PNG live data, **Web** provider search/filter/save/detail, Web Wantok Agent human handoff, Track reviews and Wallet; Android Client → Services shell/navigation, Android CX1F populated provider discovery and Android AI handoff capture are PASS within the evidence limits above.
5. Verify Taxi map/location permission handling and populated Track/Inbox/account records without creating destructive test data.
6. Run the final CX1 evidence review and keep T2.4 deferred until the client gate is complete.

## Safety boundaries

- Do not reset/reseed local Supabase or replace local development accounts.
- Do not enable Wantok Pay movement before payment-rail, settlement, custody and regulatory decisions are approved.
- Do not copy Grab branding/layout. Use only product concepts adapted to Wantok Services and PNG.
- Keep **Home · Services · Track · Wallet · Inbox** unless Mansfield explicitly approves a future navigation redesign.
