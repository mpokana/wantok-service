# Wantok Services — photographic category assets

**Date:** 11 October 2026
**Status:** CX1 photo implementation deployed to Web and Android emulator; no image generation used.

## Shared Flutter image policy

- Category identity and bundled media are declared in `apps/wantok_app/lib/src/home/wantok_category_ui.dart` (`WantokCategoryStyles`). Home, Services, full catalogue, emulator offline demonstration and browser use the **same Dart registry and bundled files**, not separate platform-specific media directories.
- `WantokCategoryPicture` resolves the Technical Control **homeIcon** slot on both Web and Android Home tiles, with published **cardImage** as fallback if no home-specific published image exists; catalogues use **cardImage**. If neither published image exists or the network image fails, both platforms use the same bundled, category-specific photograph. This preserves the independently editable media slots in Theme & Media rather than making one of them inert.
- 18 visible *service* categories must have distinct `photoAsset` values, with no duplicate source image copied across categories. **More** is the nineteenth *navigation* entry and deliberately retains an ellipsis rather than a misleading stock photograph. Small buttons/navigation icons are not category photographic cards.
- Photographs are illustrative catalogue art, **not** images of approved Wantok providers, PNG government agencies or actual bookable products. Do not represent any source photo as a local business, agency endorsement, real listed hotel or verified public service.
- `Public Services` uses the pre-existing repository photograph `assets/images/reference/services_public_photo.jpg` (PNG public institution building), not its previous symbol-only `services_public_icon.png`. The bundled image source is the owner's existing approved project reference. **Public Services** remains an informational directory only, never a live emergency dispatch system.
- New remote stock photographs are converted to individual, compressed 960×610 WebP files; original photographs are not AI-generated, and media is shipped with both Flutter Web and Android for offline reliability. Preserve the original source references and licence reviews below.

## Newly bundled service category photos

| Category | Bundled file under `apps/wantok_app/assets/images/categories/` | Source | Licence basis |
| --- | --- | --- | --- |
| Education & Training | `category_education.webp` | [Quilia classroom photograph](https://unsplash.com/photos/students-in-classroom-with-teacher-presenting-zFSo6bnZJTw), CDN `photo-1509062522246-3755977927d7` | Unsplash License |
| Hotels / Accommodation | `category_hotels.webp` | [Unsplash photo CDN](https://images.unsplash.com/photo-1566073771259-6a8506099945), known hotel/resort photograph | Unsplash License; photographer details to be verified before public commercial artwork approval |
| General Labour | `category_labour.webp` | [Concrete construction workers](https://unsplash.com/photos/construction-workers-pouring-and-leveling-concrete-VHPFxU6eqto), CDN `photo-1743130940757-42d780087c3a` | Unsplash License |
| Financial Services | `category_financial.webp` | [Unsplash photo CDN](https://images.unsplash.com/photo-1554224155-6726b3ff858f), financial paperwork/calculator photograph | Unsplash License; photographer details to be verified before public commercial artwork approval |
| Venue Booking | `category_venue.webp` | [Unsplash wedding/event hall](https://unsplash.com/photos/a-room-with-tables-and-chairs-bt5Br2xp1pU), CDN `photo-1670529776286-f426fb7ba42c` | Unsplash License |
| Errands | `category_errands.webp` | [Mathias Reding, person carrying shopping bags](https://unsplash.com/pt-br/fotografias/uma-pessoa-que-transporta-sacos-wU7Gg87M5XE), CDN `photo-1656956171309-ed6e25eafcbc` | Unsplash License |
| Boat Hire | `category_boat_hire.webp` | [Harbour motorboats at dock](https://unsplash.com/photos/a-dock-with-boats-in-the-water-KdUnQH2m1kc), CDN `photo-1661714018351-01fc8efe50d4` | Unsplash License |

Unsplash licence information: https://unsplash.com/license. Images are bundled copies, not third-party hotlinks. Keep source references with the project and obtain any additional clearance required for future campaigns, especially if a business or government agency might appear to be endorsing Wantok Services.

## CX1 follow-up — complete backend category photo coverage (11 October 2026)

An actual read-only query to the local `public.service_categories` table returned **23 distinct backend slugs** (20 active, 3 inactive). All 20 active categories were already mapped to existing, individually distinct photographs. Two dormant slugs had a media identity gap: `bus-coach` used the navigation-only `More` fallback, while `flights` reused `travel-flights` imagery. Neither was enabled during this update.

Two distinct, bundled 960×610 WebP photographic assets were created from externally sourced photographs, rather than using the image generator's unsuitable whole-dashboard mock-ups:

| Backend category | Asset | Visual identity | Original licensed source |
| --- | --- | --- | --- |
| `bus-coach` (inactive) | `category_bus_coach.webp` | Passenger touring coach, broad view of the vehicle on the road | [Unsplash CDN photo-1570125909232-eb263c188f7e](https://images.unsplash.com/photo-1570125909232-eb263c188f7e), [Unsplash licence](https://unsplash.com/license); visible operator livery is illustrative, not a Wantok provider |
| `flights` (inactive) | `category_flights.webp` | Airport self check-in terminal, visually distinct from `travel-flights` aircraft-in-sky picture; airline logo region blurred | [Anna Shvets / Pexels](https://www.pexels.com/photo/person-checking-in-at-the-airport-3943950/), [Pexels licence](https://www.pexels.com/license/) |

In `WantokCategoryStyles` both are now first-class, slug-matched style entries, and `backendCatalogue` explicitly enumerates all 23 backend slugs. **No two backend slugs use the same bundled photograph path**. `backend_category_media_test.dart` additionally checks every image is loadable from Flutter's asset bundle and rejects byte-for-byte image duplicates. New future slugs must be added to the backend artwork audit before being publicly shown; never silently map a service to the `More` navigation image.

The 23-category audit includes inactive `bus-coach`, `accommodation` and `flights`. The two newly created images were downloaded/cropped and encoded as WebP, **not AI-generated photographs**. Both failed attempts at AI generation produced full dashboard mock-ups, were rejected and **were not added to the project**. Inactive services remain inactive.

## UX/operational safeguards

- The Home **Public Services** and other real service category cards now display photographic art on both form factors, using the same media fallback. New artwork only changes visual presentation: no module enabled/disabled, data inserted, payment activated or booking changed.
- User-facing port `3200` name: **Operations** (not Operations Admin, which can be confused with Technical Control). Internal `wantok_admin` package/class/RLS identifiers stay unchanged to protect integrations.
- **Acceptance** requires visual review of current Web 3000 and Android emulator/HONOR at relevant widths *after* the updated binaries are deployed; source tests alone are not final device acceptance. CX1 remains in progress and T2.4 deferred.
