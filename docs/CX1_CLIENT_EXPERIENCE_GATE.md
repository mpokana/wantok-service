# CX1 — Client Experience Completion Gate

**Status:** queued after T2.3 checkpoint, before T2.4.
**Environment:** EAGLT02 local development; existing accounts/data must be preserved.

## Acceptance and evidence

| Area | Required evidence | Status |
| --- | --- | --- |
| Client shell | Five tabs, Home profile entry, back navigation, Client/Vendor boundary | Pending |
| Discovery | Home search reaches Services; search and family filters work together | Pending |
| Service journeys | Taxi, reservations, requests, commerce, events and water transport entry/back | Pending |
| State handling | Loading, retryable errors, empty catalogue and no matches are distinct | Pending |
| Layout/accessibility | Narrow phone, enlarged text, labelled controls and selected-tab semantics | Pending |
| Wallet | Kina (K), clear preview, no enabled payment movement | Pending |
| Regression | Focused Flutter tests plus live client QA; full checkpoint checks | Pending |

## Initial source review

- Home search is read-only with no navigation action; QR icon has no action.
- Services family chips and tune icon are decorative rather than working filters.
- Home has no explicit empty-catalogue state; Services conflates empty catalogue and no matches.
- Services displays raw backend errors and has no clear inline retry action.
- Home profile opens AccountPage without its own scaffold/app bar/back affordance.
- Track currently queries service bookings; its wording also promises specialised journeys. Verify coverage rather than assuming all transaction types appear there.
- Fixed-height scenic headers/grids need narrow-screen/enlarged-text regression checks.

## Completion rule

Keep CX1 open until evidence is recorded for every required area. Do not start T2.4 based only on analysis/smoke tests. Use transactional database tests; never reset/reseed Supabase, replace local accounts or enable Wantok Pay movement.
