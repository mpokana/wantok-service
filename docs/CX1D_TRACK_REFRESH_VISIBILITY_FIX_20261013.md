# CX1D — Track Refresh Visibility Defect and Regression

**13 October 2026 PNG | Authorised laptop EAGLT02 | Source-only Client visual fix**

## User-witnessed defect

During the live signed-in CX1 desktop browser walkthrough on `127.0.0.1:3000`, the owner successfully completed the Saved and Inbox desktop Refresh screenshots. On Track, the reported `Refresh` button was effectively invisible. Inspection of the user-provided desktop screenshot shows very faint white `Refresh` above the Completed section at the right of the content while the green Track hero occupies only the left portion.

Source root cause in `apps/wantok_app/lib/src/home/activity_page.dart`: `_TrackRefreshHeader` positions a `TextButton.icon` at the far right of a `Stack`, beyond the compact green `_TrackHeader`. The button had `foregroundColor: Colors.white` and `backgroundColor: Colors.white.withValues(alpha: .12)`. White on nearly white/light-grey surroundings gave extremely poor practical visibility, although existing widget tests could locate and tap the invisible control.

## Minimal Client-only change

Change **only** the Track Refresh button's `backgroundColor` to opaque green `Color(0xFF096B4B)`, preserving white foreground, tooltip `Refresh activity`, key `cx1-track-refresh`, 48px minimum touch height and the existing reload callback. Do not alter the E6 Enterprise area, Technical T2.4, database privileges, saved content, bookings, chat or user accounts.

The new test `apps/wantok_app/test/cx1_track_refresh_visibility_test.dart` validates accessible contrast at 320, 390 and 1440px: white text, solid green background, WCAG contrast ratio at least 4.5:1, 44px tap height and one read-only extra load on centre-tap. Existing `cx1_inbox_track_refresh_test.dart` retains navigation/recovery checks. **Focused Flutter result: 11/11 PASS** across both test files, process exit 0.

## Acceptance state

- **Saved Desktop:** Owner sent before/after signed-in screenshots; remained on Saved with one QA provider and no unsolicited Vendor Onboarding. User-witnessed visual PASS, distinct from formal CX1 human signoff.
- **Inbox Desktop:** Owner sent before/after signed-in screenshots; services count 0 and help count 1 unchanged, no unexpected navigation. User-witnessed visual PASS.
- **Track Desktop:** **BLOCKED BY VISIBILITY DEFECT** on originally served 11 October static build `127.0.0.1:3000`. User supplied *before* screenshot only; no successful centre-click/after screenshot. The source fix does not by itself close this live gate.
- **Saved/Inbox/Track mobile 320px:** All three real browser cases remain NOT EXECUTED.
- **Known vendor-onboarding misnavigation:** Prior cause unknown. New Saved Desktop user screenshots show normal entry and Refresh, but do not independently establish root cause of earlier incident.

**Local preview built and verified (13 October):** An isolated Flutter Web release was compiled from the corrected CX1D source using the existing local *publishable* Supabase build configuration, **without changing either established Client server**. Served read-only on **http://127.0.0.1:3301** (EAGLT02 loopback only), static process PID **38840** at verification time. HTML GET **200**, served `main.dart.js` bytes exactly match local build SHA-256 `219C9C2D5D81D8098230C95D6C94D4C45FE7CEE56F815451F2F7CA66BCC2FE4B` (4,099,077 bytes). Original old bundle at :3000/:3300 had different SHA `2207D8BBCCC5BE261B7C7A77498F4E801829E0D7B13378F56B61A06F3E3B2E66`. Preview is **not** production or a signed-in Chrome witness; different origin may require manual sign-in, and no tokens/passwords are exported.

The original local Client static processes on ports 3000 and 3300 must remain unchanged until separately authorised controlled preview/update. Source-only QA or a different preview origin must not be confused with live acceptance of the currently served build. After validated source integration and a **fresh controlled local Client build**, request actual Track desktop before/after Refresh screenshots before marking Test 3 PASS; then mobile width cases. No production deployment or E6/T2.4 gate change is authorised.

**Final eligible regression PASS:** focused Client 11/11; full Flutter 7 clean analyses and Client **135/135**, Operations **43/43**, Technical **38/38** widgets (216 total). Non-destructive cross-stream suites PASS: pending migrations SQL **301/301** over 16 disposable suites, rolled back/container removed; synthetic HTTP auth **23/23**, independence **106/106**, evidence scanner **101/101**, privacy source/local checks PASS. The persistent shared Supabase database remains unchanged; combined persistent `npm run db:test` is not asserted green because proposed migrations remain unapplied.

**Programme:** CX1 signed-in acceptance remains OPEN, E6 G1–G10 0/10, G7 31/31 unexecuted, privacy D1–D5 unsupplied, Technical T2.4 PAUSED, productionApproved:false.
