# CX1E — Track Refresh mobile layout, 320px

**Date:** 13 October 2026 PNG · **Authorised machine:** EAGLT02 · **Source checkout:** isolated detached worktree from `e83f3280cae940981cbd295836e1e5276f34e26f`

**Scope:** A Client-only UI fix. E6 G1–G10 remains 0/10 approved, Technical T2.4 paused, CX1 formal acceptance OPEN, production false.

## User-witnessed defect

In Chrome Responsive device mode set to **320 × 811**, the actual signed-in Track page displayed the green `Refresh` button over the green Track hero, overlapping the heading **“Track your Wantok”**. Both before and after the user's Refresh showed the **same Completed (1)** Specialist Services QA record, Wantok QA Plumbing Services, Lae, Morobe Province. This supports a **functional, user-witnessed route/count consistency observation**, but **mobile visual acceptance FAIL** because Refresh obscures the title. The previous Desktop Saved, Inbox and Track screenshot pairs passed visual checks and remain separate evidence.

Root cause: `_TrackRefreshHeader` in `apps/wantok_app/lib/src/home/activity_page.dart` used a single `Stack` with the action `Positioned(top: 14, right: 14)` over the hero for **all viewport widths**. At 320px, the hero occupies the available width; that absolute action overlaps the heading.

## Corrective layout

- Below **600px of available width**, render the green `_TrackHeader` first, then a right-aligned, separate `Refresh` action **below** the hero. Do not overlay the heading, status count or body.
- On **wide desktop layouts**, retain the previous right-aligned action in the Stack.
- Preserve the existing green/white high-contrast button, `cx1-track-refresh` key, `Refresh activity` tooltip, at least 48px intended tap target, and read-only refresh callback.
- No Supabase source, API schema, permissions, bookings, messages, saved records, Operations or Technical code changes.

## QA and acceptance

`apps/wantok_app/test/cx1_track_refresh_visibility_test.dart` now checks 320, 390 and 1440 logical px, white label/opaque-green high contrast, minimum touch size, one additional load after centre-tap, and, at mobile widths, the action **starts below the hero and stays within the viewport**. Existing Inbox/Track no-navigation widget checks also remain. **Fresh focused Flutter verification: 11/11 PASS** (3 contrast/layout tests and 8 existing read-only reload/navigation tests), process exit 0. Full Flutter check runs separately and does not grant live CX1 acceptance.

**13 October engineering verification PASS:** Focused Flutter **11/11**, full Flutter **7 clean analyses / 216 widget tests** (Client 135, Operations 43, Technical 38), process exit 0. New 96-file Flutter Web bundle built using the same ignored private **loopback Supabase** configuration (`127.0.0.1:54321`), SHA-256 `E937F771AF21E9A60109C02D129B93383496D99ED809263CBEE979B0DB94D63B`. Prior `:3000` bundle SHA `C7EA377A8B5B540D18311B20F3D44B8645728DB3F1B314614DA5519A1D4B47B0` copied **96/96** files to `D:\\Wantok_Project_Backups\\wantok-client-3000-pre-cx1e-20261013`, checksum confirmed. Only the verified local Python static server on loopback `:3000` was briefly restarted (new PID **49776**); HTTP HTML **200**, served JavaScript SHA matches compiled file, Supabase health HTTP **200**. Original local backup retained; other services, port 3300, database, code for Operations/Technical, and production untouched.

**Important:** Passing Flutter tests and serving a corrected local build are not proof that the user's Chrome at `127.0.0.1:3000` has reloaded or that the user clicked the corrected action. An actual **mobile Track before/after Refresh pair** must still be witnessed before closing the UX issue. Saved Mobile and Inbox Mobile remain open. Keep rollback of prior local `:3000` Web bundle; no production deployment.
