# CX1 — Category photograph selection and save staging

**Date:** 11 October 2026 (PNG)
**Machine:** EAGLT02, branch `feature/flutter-platform-v1`
**Status:** source/widget/full isolated regression PASS; local Web deployment, authenticated browser image save, real media upload, and owner image approval OPEN.

## Scope and reason

Technical Control's `Service categories` editor previously called `BrandingRepository.upload` immediately after a file was selected. Pressing **Cancel** after selection could leave a new unused storage object even though no category update was saved.

The editor now holds newly selected bytes **locally while the dialog is open** and provides an in-dialog preview. Only **Save category** initiates the existing authorised upload and then the existing authorised `manage_service_category` RPC. Cancel discards the pending image without any storage or database calls. Current saved category image paths remain displayed; no images, existing records or published branding settings were changed.

Accepted file extensions: JPG/JPEG (normalised to jpg), PNG and WebP. The editor checks maximum three mebibytes (3 * 1024 * 1024 bytes), non-empty data and basic file signatures before staging. These lightweight client checks do **not** replace the server-side storage rules, role/RLS controls, malware protection or human licensing/editorial review.

## Files changed

- `apps/wantok_tech/lib/src/dashboard/technical_category_manager_page.dart`: draft photo staging, local preview, upload-on-save, read errors, image header/size/type checks, injectable test-only selection/upload/save functions; normal production repository and picker remain authoritative.
- `apps/wantok_tech/test/technical_category_photo_staging_test.dart`: four synthetic image tests with injected callbacks. Cancel makes zero writes; Save calls upload once and transfers the returned category-specific path to the inactive draft; unsupported extension and mismatched file signature do not access storage.

## Evidence

- Clean isolated worktree: `D:\Wantok_CX1_Image_Stage_QA_20261011` based on `6611556`.
- Four focused Technical widget tests PASS.
- Full `scripts/flutter/check.ps1` **PASS (exit 0)**, all seven Flutter analyses, **132 Client**, **34 Operations**, **16 Technical** tests. These tests ran against the isolated pre-existing Operations snapshot. Concurrent E6B work in the live checkout is separate and must not be overwritten.
- NEW independent integration worktree `D:\\Wantok_CX1_Image_E6B_Integration_QA_20261011` based on committed E6B `f620c7b`, containing only the two CX1 Technical files: full `scripts/flutter/check.ps1` **PASS, exit 0**, seven analyses, **132 Client, 37 Operations, 16 Technical** widget tests. The later E6B documentation commit does not alter these app sources.
- No Supabase SQL migration, database mutation, account write, real file upload, payment, booking, provider approval, service activation, Android update, local Web deployment or online VM interaction.

## Remaining limitations and next steps

- A category write may still fail **after** the authorised image upload succeeds, leaving an unused versioned storage object. The change removes the common Cancel orphan, not every possible storage transaction failure; storage rollback/garbage collection requires separately approved design and permissions. Do not present this as atomic upload + category save.
- Browser acceptance remains OPEN for actual image selection, save/replace, cancellation and cross-platform Client photo visibility; source widget tests do not prove those workflows in authenticated Chrome.
- The six new category drafts `it-electronics`, `automotive-repair`, `agriculture-farming`, `pets-animal-care`, `cleaning-maintenance` and `construction-trades` remain inactive and require six distinct, reviewed, licensed PNG/Pacific-appropriate photographs before activation.
- Prior CX1 labelled Saved/Inbox/Track buttons await stable-focus real authenticated Chrome click acceptance. Signed-in Android/physical HONOR remain OPEN; T2.4 Diagnostics, Logs and Jobs remains DEFERRED.
- Previously deployed Web static bundles and emulator build 4010 remain the rollback/visual baseline. This milestone is **source/test-only** until an independently approved staging release.
