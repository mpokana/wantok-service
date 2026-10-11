# CX1F — Authenticated Client Web category-first acceptance

**Date:** 11 October 2026 (PNG time)
**System:** authorised EAGLT02, live local Client Web at `http://127.0.0.1:3000/`
**Outcome:** **PASS for category-first discovery and provider detail only**. Other CX1 gates are open.

## Actual sequence observed on EAGLT02

1. Chrome Client Web **Home → Services** displays the updated photographic services marketplace.
2. **Browse providers → Explore providers** opens `Find Wantok providers`.
3. **Leave free-text search completely EMPTY**; Country displays `PG`.
4. Select **Category = Specialist Services**. The existing verified QA provider appears; **5.0 (1)** sourced rating. This is **not** a plumbing-only category.
5. Select **State / Province / Region = Morobe**.
6. Select **Town / City = Lae**. All three filters remain selected, keyword field still blank. The returned real existing provider is **Wantok QA Plumbing Services**, already verified.
7. Open provider result. The genuine detail page displays **Wantok QA Plumbing Services**, verified **Business**, **Morobe**, rating **5.0 (1)**, and approved listing **QA Plumber & Maintenance** with `Specialist Services · Lae, Morobe · Quote`.

**Read-only:** Never clicked bookmark (existing filled green icon is NOT itself proof of end-to-end Saved persistence). Did not submit a service/job request, booking, review, rating, payment, provider application, handoff, or account update. Did not access browser tokens, cookies, passwords or request messages. Screenshots remain private under the existing Git-ignored `.wantok/` directory and are **not** committed.

## Local private screenshot evidence

- `.wantok/cx1-web-auth-home-new-20261011.png`
- `.wantok/cx1-web-services-step1.png`
- `.wantok/cx1-web-browse-providers-new.png`
- `.wantok/cx1-web-provider-directory-blank.png`
- `.wantok/cx1-web-specialist-selected.png`
- `.wantok/cx1-web-province-morobe.png`
- `.wantok/cx1-web-category-morobe-lae-pass.png` **primary acceptance**
- `.wantok/cx1-web-provider-detail-pass.png` **detail acceptance**

Later browser control correctly refused another click after Windows focus moved away. Multiple Wantok Chrome windows were minimised. A subsequently restored matching window showed the same provider-detail page, but the foreground changed to Operations before the next intended click. No unsafe input was sent. User's active desktop context was preserved.

## Supplemental Saved regression

The existing `SavedItemsPage` now accepts an **optional read-only loader** only for test injection; its default production loader still uses the authenticated `ClientExperienceRepository` and current RLS. Tests cover saved provider rendering at **390 px and 1240 px**, empty state, and Retry after a simulated failed read. The tests perform **zero remove/save mutations** and never claim that the live user's Saved collection was opened.

## Remaining work / stop condition

- **OPEN:** Actual signed-in Web **Account → Saved** read-only display and persistence, no destructive toggles. Prior provider-list bookmark icon was visible but not changed.
- **OPEN:** Actual Web Account, Inbox/Support, Track, Wallet-preview and Wantok Agent read-only navigation and the separate physical HONOR acceptance.
- **OPEN:** Final Pacific/PNG-realistic pictures for the six new inactive draft service categories, individual approval and browser media upload lifecycle.
- **T2.4 DEFERRED. CX1 IN PROGRESS.** No database migrations, service activation, Operations Admin writes or currency movement authorised in this step.
