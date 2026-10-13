# CX1I — Services cards: text-only captions and one category photograph

**Date:** 13 October 2026 (Papua New Guinea). **Project:** Wantok Services Client Flutter, authorised laptop **EAGLT02**. **Source baseline:** CX1H commit `3ea3549bb0c82258acb4409323e7d23170390866`; separate source worktree `D:\Wantok_CX1I_Services_Single_Image_20261013`.

## Owner screenshot and requested correction

The owner supplied a real signed-in Chrome Responsive **320 × 811** Services tab screenshot at `http://127.0.0.1:3000/`. Each pictured service-category card displayed the **same category photograph twice**—a small image beside the title/subtitle in the top half, then a larger image in the lower half. The requested change was explicit: **make the top caption text-only**, eliminating the repeated small image while retaining the larger category photograph.

## Implemented in Client source

- `apps/wantok_app/lib/src/home/screenshot_service_tiles.dart`: `ScreenshotServicesCard` no longer renders the **46 × 48px `ScreenshotServiceArt.visual(..., icon: true)`** thumbnail above the main image. It instead shows only **title, subtitle and disclosure chevron** across the full caption width.
- Keep exactly **one category photograph** below the caption, via `ScreenshotServiceArt.visual(..., icon: false)` / `WantokCategoryPicture` (`mediaSlot: cardImage`). Adjust original caption/photo allocation from 7:5 to **6:6** at regular scale; when text scale exceeds 125%, use **8:4** caption/photo to avoid overflowing at 150% text scale. The original 169px normal mobile card height remains unchanged.
- The same single-photo visual rule applies to every `ScreenshotServiceArt.items` photo-backed Services card (Taxi / Transport, Hire Car, Food, Groceries, Delivery, Travel & Flights, Specialists, Public Services).
- Do **not** remove category names/descriptions, duplicate underlying backend categories, invent providers, change routes, prices, authentication, bookings or payments. Do not alter `ScreenshotHomeTile`, which has a deliberately distinct Home icon layout; other media modules remain unchanged.
- `apps/wantok_app/lib/src/home/reference_services_gallery.dart` already routes the **phone Services landing** through `ScreenshotServicesCard` and keeps two columns; no global card refactor is necessary. Enterprise/desktop Services presentation remains unchanged.
- Keep the existing mobile/tablet pull-to-refresh policy and CX1H dynamic Track card/pinch behaviour.

## Regression and acceptance contract

New `apps/wantok_app/test/cx1i_services_single_photo_test.dart` checks each of the eight photo-backed categories at **320, 390 and 700 logical px**, asserting exactly **one `WantokCategoryPicture` with `cardImage` slot**, visible caption/subtitle, no Flutter exception and exactly one tap callback. It also exercises the actual 320px `ReferenceServicesLanding` and verifies the previous Home tile photo identity (`homeIcon`) is unaffected.

**Focused QA:** four Flutter test source files (`cx1i_services_single_photo_test.dart`, `phone_preview_test.dart`, `wantok_category_ui_test.dart`, `backend_category_media_test.dart`) **24/24 tests PASS**. The first focused run had one test lookup error (catalogue internal title differs from display caption); corrected to use `ReferenceServiceCategories.items` and reran. Full Flutter originally caught an actual 150% enlarged-text overflow on 320/390px; corrected caption flex and added two more dedicated enlarged-font regression cases. **All 24/24 focused checks now PASS**. **Full Flutter: seven clean analyses; Client 174/174, Operations 43/43, Technical 38/38 widget tests = 255/255 PASS**.

**Browser acceptance remains open:** After a verified local source/Web deployment, owner hard refreshes **http://127.0.0.1:3000/** in the signed-in 320 × 811 Chrome emulator and sends a screenshot of the Services tab. The desired result is **plain text caption and one lower photograph per photo-backed card**, without changed navigation or overflow. Do not call the visual acceptance passed from tests or compilation alone.

## Safety, Git and release

The shared feature checkout `D:\Project-M.2\wantok-service-recovery` contains another session's staged/unstaged `docs/BUSINESS_PLAN_V1_20261013.md`, `docs/COMMISSION_POLICY_V1_20261013.md`, and user-pre-existing untracked `supabase/snippets/`. Preserve **all** of them. Do not stash, reset or merge into that checkout during the concurrent session. Commit only owned CX1I source, tests and documentation on a separate named branch, push that branch to GitHub, create and independently verify a local **Git bundle** backup, and build/verify a source-only release archive. Only the Client loopback Web port **3000** may be restarted to serve the new build, and only with the previous 96-file Web build backed up; leave port 3300, Supabase data, Operations, Technical and production untouched.

**Gate status:** CX1 signed-in new visual witness pending; E6 human G1–G10 0/10, G7 31/31 unexecuted, T2.4 paused. `productionApproved:false`.

## Verified local Web delivery

**Local CX1I Web delivery PASS:** EAGLT02 released 96-file Client Web, HTML HTTP 200, served `main.dart.js` SHA-256 `00105FA7B7002D48C7E2E2F729A47E49C123A1DD1D50C6EED184817543814BC2`, local Supabase Auth health HTTP 200, Python loopback :3000 PID **32132** at verification. Old working 96-file CX1H build SHA `F9BEB609B42A581437B19D20C3915CD42F3FCCEB665F79A4420BDBE34FA0F62F` fully backed up to `D:\Wantok_Project_Backups\wantok-client-3000-pre-cx1i-20261013` (96/96 verified, rollback retained); :3300 untouched. No DB write, Technical/Operations deployment or production approval. Chrome owner hard reload/new signed-in photo visual witness still OPEN.

## Verified portable source backups

**Verified source-code backup checkpoint (commit `592934059a4de7fa43592500b3de7f95c0f1c830`):** GitHub `feature/cx1i-services-single-photo-captions` successfully pushed; independently `git bundle verify` confirmed **complete branch history** in `D:\Wantok_Project_Backups\Git\wantok-service-cx1i-5929340-20261013.bundle` (13,526,956 bytes, SHA-256 `E3FA97D830140D2DC58A4901EEF3924956ECA7124BF1D897090AA213002019C2`). Source-only archive `D:\Wantok_CX1I_Release_5929340_20261013\.wantok\releases\wantok-vps-592934059a4d.tar.gz` verified for the same source commit (SHA-256 `DB18056457F5405BEF15B4F0EE3CDE40F7D0B6740C4871478F4BD8142E693BC3`, 77 checked-in migrations, `productionApproved:false`). These backups contain tracked source, not local auth credentials or untracked snippets.
