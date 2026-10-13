# CX1F — Inbox mobile Refresh placement correction

**Date:** 13 October 2026 (PNG). **Machine:** EAGLT02 only. **Baseline:** `b330ba99b81d3c442cf466e900c2bddeb91be5db`, detached `D:\Wantok_CX1F_Inbox_Mobile_Refresh_20261013`. **Scope:** Client-only UX for CX1, local test build; not a production or security gate.

## Owner-reported issue and acceptance state

The owner supplied an actual Chrome Responsive **320 × 811** Inbox screenshot at `127.0.0.1:3000`. Its green translucent **Refresh** action obscured the hero eyebrow **“CONVERSATIONS & SUPPORT”**. The screenshot shows **Services (0)**, **Help & support (1)**, and the empty-service conversation state. The screenshot was captured **before any demonstrated Inbox Mobile Refresh**; do not claim a user-witnessed centre-tap or after-state.

Prior signed-in screenshot pairs demonstrate **Saved Desktop, Inbox Desktop, Track Desktop and Track Mobile 320px** visibly stable after Refresh (**4/6 user-witnessed visual passes**). Inbox Mobile is **UI FAIL / live retest pending**; Saved Mobile **NOT EXECUTED**. Earlier Saved-to-Vendor-Onboarding navigation remains historically unexplained and is not automatically closed by this fix.

## Source cause and fix

`apps/wantok_app/lib/src/home/messages_page.dart` had an unconditionally `Positioned(top: 14, right: 14)` Inbox Refresh action inside a `Stack` over the green hero. Narrow screens lack horizontal space for that overlay.

A scoped `LayoutBuilder` now checks **available width under 600px**. At phone widths the hero renders first, then a standalone **right-aligned green/white Refresh** below it. At wider widths the previous overlay position and styling stay intact. The update preserves key `cx1-inbox-refresh`, tooltip `Refresh Inbox`, the 48px minimum touch height, `_reload`, selection state, error recovery, and existing loading callbacks. A presentation-only `cx1-inbox-hero` key supports geometry QA; no data repositories, accounts, privileges, migrations, payment code, Operations or Technical source changes.

Extended `apps/wantok_app/test/cx1_inbox_track_refresh_test.dart` at **320/390/1440px** to verify visible Refresh, touch target, 320/390 no-overlap and viewport bounds, foreground/background contrast at least 4.5:1, desktop overlay position unchanged, and actual read-only loads for both Inbox categories. Existing saved/track route-safety tests also run. **Focused suite 14/14 PASS** (process exit 0). **Full Flutter validation: seven clean analyses; Client 135/135, Operations 43/43 and Technical 38/38 widget tests PASS (216/216 total, process exit 0).** A source/widget pass cannot stand in for signed-in user acceptance.

## Deployment controls

Only after full Flutter QA: build a separate 96-file release Web directory using ignored private local Supabase configuration with loopback `http://127.0.0.1:54321`; verify expected SHA-256 and HTTP Auth health; preserve verified complete backup of currently working `:3000`; temporarily stop/restart **only** its confirmed loopback Python static HTTP server; verify served JS hash and HTTP 200; automatically roll back on failure. Keep port 3300 and any Technical/Operations services unchanged. Never export credentials, apply SQL migrations, or claim production authorisation.

**Local EAGLT02 activation PASS (13 October):** Compiled corrected 96-file Web release in isolated detached worktree against the existing ignored loopback Supabase configuration. New JS SHA-256 `E1537C931423DFF62AC6AF7EEAD078CE44586C99FA33D049FC69945F5F461A82`. Original working 96-file port 3000 bundle SHA `E937F771AF21E9A60109C02D129B93383496D99ED809263CBEE979B0DB94D63B` backed up and independently verified at `D:\\Wantok_Project_Backups\\wantok-client-3000-pre-cx1f-20261013`. Restarted only the verified loopback Python Client static service, old PID 40060, new PID 28044 at verification. Served `http://127.0.0.1:3000/` HTML **200**, JS SHA matched on-disk new build, local Supabase Auth health **200**, previous local build retained for rollback. Port 3300, database, Operations/Technical services and production untouched. No live Inbox centre-click observed after this correction yet.

**Last human step:** owner keeps Chrome at **Responsive 320 × 811** on `http://127.0.0.1:3000/`, hard-refreshes, visits Inbox, captures screenshot with the action *below* hero, taps the centre of Refresh once, then sends after-screenshot. Verify Services (0), Help & support (1), same Inbox route and no overlay/navigation. Then perform Saved Mobile. Formal CX1 signoff and other external E6 security gates remain open; G1–G10 0/10, G7 31/31 pending; T2.4 paused, production false.
