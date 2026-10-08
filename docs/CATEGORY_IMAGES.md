# Wantok Services — shared generated category pictures

**Design instruction:** The Services categories should use realistic, friendly, locally bundled pictures with category names immediately underneath, like a premium marketplace or transport app. The **same category must have the same picture on all screens**.

## Source and assets

The twelve pictures in `apps/wantok_app/assets/images/categories/` were cropped from a single newly AI-generated Wantok Services design reference on 8 October 2026. The crop excludes mock-up labels, ensuring Flutter owns category text and translations independently of the artwork. The images are compressed WebP, 288 x 192 pixels each, with category backgrounds and coordinated photo composition. No third-party stock images, service-specific real customer photos or live provider images are passed off as these illustrations.

| Category | Stable file |
|---|---|
| Taxi & Transport | `category_taxi.webp` |
| Food & Restaurants | `category_food.webp` |
| Groceries & Essentials | `category_groceries.webp` |
| Shopping & Retail | `category_shopping.webp` |
| Home Services | `category_home_services.webp` |
| Beauty & Wellness | `category_beauty.webp` |
| Health & Medical | `category_health.webp` |
| Travel & Flights | `category_travel.webp` |
| Events & Tickets | `category_events.webp` |
| Professional Services | `category_professional.webp` |
| Automotive | `category_automotive.webp` |
| More | `category_more.webp` (small image mosaic) |
| Delivery | `category_delivery.webp` (clean illustration cropped from the approved generated Delivery banner, with baked-in lettering excluded) |

A dedicated `category_water_transport.webp` thumbnail is cropped **only from the previously approved local water photograph**, excluding embedded title lettering and leaving the source untouched. Boat Hire and Water Transport use exactly that same picture.

The expanded Services grid now adds six existing-picture categories: Delivery (clean local Delivery artwork), Hotels (Home Services visual), Education & Training (Professional Services visual), Financial Services (existing category mosaic as a temporary neutral placeholder), Water Transport (approved local water image), and General Labour (Professional Services visual). No further images have been generated for the expansion. Replace the reused pictures with category-specific user-approved artwork later, keeping the same registry entries; do not mistake those visual placeholders for real providers. The More card is drawn with a pale circular three-dot icon, matching the reference, and does not depict a provider.

Production category artwork is **not sample/SMOKE data** and must remain when demo fixtures are removed.

## Single source of truth

Use `WantokCategoryStyles.bySlug(slug)` in `lib/src/home/wantok_category_ui.dart` to get the category style and asset path. The same `WantokCategoryPicture` powers large category cards and smaller `WantokCategoryBadge` in Home and service headers. This prevents divergence between Home, Services, listings, booking details and All Services. Existing navigation, provider IDs, booking endpoints and backend schemas are unchanged. Additional backend service families reuse contextual local images from the existing image bundle or the closest category photo, but still resolve through this single registry.

The Flutter `pubspec.yaml` registers `assets/images/categories/` explicitly. This is intentional because Flutter assets are not guaranteed to recurse into unlisted child folders. Pictures work offline and do not depend on CDN URLs, external image APIs or runtime generation.

## Visual safety and acceptance

- Keep the picture at the top of the rounded card and the text label beneath, not text baked into the image.
- Keep tap targets and saved/bookmark callbacks unchanged.
- Use fallback Material icons only if an image truly fails to load; the fallback icon must come from the same registry.
- Test the 320, 390 and 800 px responsive widths and larger system text scaling; no overflow.
- Verify the **same image file** resolves for a category from a Services tile, Home shortcut, All Services and each relevant detail-page badge.
- The temporary `s` markers apply **only to smoke/sample records**, not to permanent category illustrations.
- Before release: remove the optional `WANTOK_SMOKE_DATA` layer per `docs/SMOKE_DATA.md`. Retain these shared category pictures.

## Replacing or improving an illustration later

Replace one category image file (same filename and size/aspect ratio), verify the common style registry, run the full Flutter gate and Android emulator visual checks. The app should not require 3+ separate icon changes for the same category. Do not generate real-looking driver, supplier or business identities and treat them as approved records.
