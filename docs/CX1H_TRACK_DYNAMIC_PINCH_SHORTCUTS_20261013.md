# CX1H — Adaptive Track shortcut cards, shared pinch density, and navigation-overlay triage

**Owner decision:** 13 October 2026 (Papua New Guinea). Scope: Wantok Services **Client UX** on authorised EAGLT02 only. Baseline CX1G GitHub commit `6851f366110e2c9d4cb59108dc9a88a0f983763b`. Distinct, detached `D:\Wantok_CX1H_Track_Adaptive_Cards_20261013` worktree, **not** the active shared feature checkout.

## Reason / user preference

The actual user-provided Chrome mobile before/after Track screenshots at **Responsive 320 × 811** show pull refresh with stable Completed (1), provider Wantok QA Plumbing Services and no visible Refresh button. The four navigation shortcuts were *left-aligned unequal-width pills on four stacked rows*. The owner approved a two-column equal-sized card layout and requested **dynamic two/three columns using the same pinch/spread interaction as the Home page**, rather than a fixed two-column solution.

## Engineering solution

- Reused existing `AdaptiveCategoryGrid` from `apps/wantok_app/lib/src/home/adaptive_category_grid.dart`; it already supports native two-finger *pinch in* to **three smaller cards** and *spread out* to **two larger cards**, without competing with the parent's one-finger pull/scroll recogniser. The grid shares the session's `AdaptiveGridDensityScope` with the Home catalogue: preference may follow across Client pages, but **not persisted to disk**.
- The existing `_TrackJourneyLinks` shortcuts in `apps/wantok_app/lib/src/home/activity_page.dart` use equal-height, bordered Material/InkWell cards on narrower viewports. Labels remain centred, with visible icons and up to three lines. Default responsive columns: **two below 420 logical px; three at wider phone/tablet widths**; pinch may intentionally choose either two or three at any mobile/tablet width.
- At **desktop viewport widths >=1200 logical px**, preserve the previous compact `OutlinedButton.icon` Wrap row, destinations and actions.
- All four original routes retained: **Taxi rides, Food & shop orders, Event registrations, Water trips**. No booking status, backend, Supabase migration, payment, provider access, notifications or Technical/Operations app changes. The CX1G *mobile/tablet pull-to-refresh* policy remains intact.
- Bottom Wallet overlap investigation: the Flutter `HomeShell` `_WantokBottomBar` draws five evenly expanded navigation hit targets, with no floating assistant widget or overlay in the bottom bar. The multicoloured bubble in the user's Chrome screenshots is likely an external/injected browser assistant overlay. **No unsupported source change made to Wallet navigation.** A separate user/browser extension check is needed to establish exact overlay provenance; do not claim it fixed by changing Track cards.

## Test and human acceptance plan

`apps/wantok_app/test/cx1h_track_adaptive_shortcuts_test.dart` is a new Flutter widget suite:
- 320 / 390 logical px -> two columns and four equal-height 94px targets; 540 / 800 / 1024px -> three columns.
- Two touch pointers simulate actual **pinch in** and **spread out** at 320px; assert shared density switches from 2 to 3 and back without changing destination labels or leaving Track.
- 1440px desktop still shows four original `OutlinedButton` shortcuts, without an adaptive grid.
- Existing Home shared-density pinch and CX1 Track pull refresh tests run alongside.
- Source unit/widget passing is **not** a signed-in Chrome touch/zoom acceptance. After successful safe local rollout, user should hard refresh `http://127.0.0.1:3000`, keep Responsive at 320×811, check equal two-column cards and after pull Refresh, then pinch in/out on the Track shortcut area using real touch or Chrome DevTools touch emulation (mouse alone does not natively simulate two simultaneous touches). User may also inspect wider phone/tablet layouts. Saved Mobile refresh still requires independent browser witness.

## Safety

The main feature checkout has *other session's staged + unstaged* business-plan/commission documents and untracked `supabase/snippets/`; do not stash, reset, merge or overwrite. Only CX1H paths may be committed. Share on a separate `feature/cx1h-track-dynamic-shortcuts` branch until the parallel owner consolidates sources. Build only a **local source Web binary**, back up verified current port-3000 Client files, and switch only the verified loopback Python server with rollback. Keep port 3300 and shared local Supabase database unchanged, no production release. CX1 formal acceptance remains open, E6 human G1–G10 0/10, G7 cases unexecuted, Technical T2.4 paused, `productionApproved:false`.

## Exact QA and local testing build checkpoint

**13 October CX1H PASS (engineering only):** Isolated Flutter focused shortcut/Home-pinch/Track-pull suite **14/14**, and full Flutter runner: **seven clean analyses; Client 167/167, Operations 43/43, Technical 38/38 widget tests PASS (248 total, process exit 0)**. A new signed-in-backend-configured **96-file** local Flutter Web build uses only the previously established private publishable Supabase URL `127.0.0.1:54321`. The original CX1G local Web artifact was verified SHA-256 `40071C243E2F3E88A55F4A7611AA4C95EFC6AE95FE067C9455D932F1D13A6558` and fully backed up (**96/96 files**) to `D:\Wantok_Project_Backups\wantok-client-3000-pre-cx1h-20261013`; only the loopback port **3000** Python static server (previous PID **36028**) was briefly stopped/restarted. New PID at activation **2484**; HTTP HTML **200**, downloaded `main.dart.js` SHA-256 `F9BEB609B42A581437B19D20C3915CD42F3FCCEB665F79A4420BDBE34FA0F62F` exactly matches built file; Supabase Auth health **200**. Port 3300 untouched. No shared persistent database changes, security, production or T2.4 actions. **Do not declare human pinch acceptance from this.**
