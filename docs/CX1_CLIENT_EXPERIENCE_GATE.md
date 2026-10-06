# CX1 — Client Experience Completion Gate

**Status:** IN PROGRESS; implementation checkpoint, gate open before T2.4.
**Environment:** EAGLT02 local development; existing accounts/data preserved.
**T2.3 checkpoint:** `46d6208`.

## Acceptance and evidence

| Area | Evidence at this checkpoint | Status |
| --- | --- | --- |
| Client shell | Five tabs, Home search/profile/back; selected-tab labels/tap actions | Automated PASS; live QA pending |
| Discovery | Search/family filters combine; clearing restores catalogue | Automated PASS |
| Service entry/back | 11 categories from Services plus Home Food route | Automated PASS; successful live data journeys pending |
| State handling | Delayed catalogue, repeated retry failures, empty/no-match distinction; record errors do not look empty | Automated PASS |
| Layout/accessibility | 320/390/800 logical pixels at 1.5x text; discovery scroll and five tabs | Automated PASS; native visual QA pending |
| Wallet | Kina (K), explicit preview/planned copy, no transaction controls/backend changes | Automated PASS |
| Role boundary | Customer can switch modes without gaining provider or technical authority | Automated PASS; pgTAP baseline retained |
| Checkpoint | Full Flutter checks: 32 app tests, Admin/Tech smoke tests and seven analysis targets; 16 files / 364 pgTAP tests; diff check | PASS |

## Implemented fixes

- Home search opens Services; decorative QR/tune controls removed.
- Service families are working filters, with search clearing and clear-filters recovery.
- Empty catalogue differs from unmatched search; errors use connection/retry guidance.
- Home profile route has its own scaffold/app bar/back button.
- Scenic headers grow with content; discovery grids, spotlights and Wallet action cards fit enlarged text.
- Narrow client mode selection uses a compact menu; tab semantics include labels, selection and tap actions.
- Track opens existing specialised records; generic requests/reservations are labelled accurately.
- Retry callbacks no longer return Futures from setState or let failed refreshes escape.
- Events, departures, orders, registrations and water trips distinguish errors from no records.
- Wallet remains a preview; no payment adapters, database migrations, local config or account changes.

## Coverage limits and next work

The widget tests use injected in-memory catalogue rows or an unconfigured backend. They verify navigation/layout/recovery, not successful authenticated bookings, real Realtime delivery, device location or map tiles. The Taxi route is preserved and source-reviewed, but excluded from offline route tests because it uses external map tiles and device location.

1. Build and visually verify the updated client in a development Android/Web session while preserving existing sign-in/account data.
2. Verify Taxi entry/back, map/location permission handling and existing ride history without submitting a new ride.
3. Inspect existing populated/empty Track, orders, events, water bookings, Inbox and Account records without modifying them; verify service-specific return paths.
4. Check offline/recovery behaviour and enlarged text on the real client.
5. Record evidence, resolve any remaining client defects, run checkpoint checks and close CX1 before T2.4.

The running app/admin servers and local Supabase stack were not replaced. Existing auth users/profiles remain two and the local technical-admin grant remains one. Database test fixtures are transactional and roll back.

## Completion rule

Keep CX1 open until live evidence is recorded for the remaining areas. Do not start T2.4 based only on analysis/widget tests. Never reset/reseed Supabase, replace local accounts or enable Wantok Pay movement.
