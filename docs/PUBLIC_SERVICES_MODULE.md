# Public Services module — 11 October 2026

## Scope
The owner-approved **Public Services** directory was added without replacing
Taxi / Transport, Hire Car, Food, Groceries, Delivery, Travel & Flights,
Specialists or any existing request and booking workflows.

Home uses the screenshot-approved icon tiles, and Services uses the screenshot-
approved photo + icon cards. Other categories are still reachable by scrolling
or browsing the full service catalogue. The attached October 10 screenshots
were the sole source for the additional cropped visual assets:
`apps/wantok_app/assets/images/reference/`.
These are *crops* of owner-supplied screenshots; **no images were generated**.
`scripts/extract_reference_artwork.py` documents how to reproduce the crops
from files with their original names in the current user's Downloads directory.

## Public directory
Tapping Public Services from either Home or Services opens
`PublicServicesPage`, an informational directory with:
- Emergency & Safety
- Health Services
- Government Services
- Community Services

Each area has an informational second-level page. Local police numbers,
government office links and other external references are **not invented**.
There is no live emergency dispatch, booking, government transaction or payment
integration. Official contacts must be verified before publication.

## Activation and deactivation
The single source of truth is `public.service_categories` where
`slug='public-services'`. An active row appears in client catalogues;
an inactive row is filtered from Home and Services (and from their reference
landing tiles). Existing app sessions should refresh to pick up a change.

Authorised operations staff can go to **Operations → Modules → Public Services**
and use the switch. It requests confirmation, then calls the secured
`public.admin_set_public_services_enabled(boolean)` RPC.

The server checks the authenticated user's actual RBAC admin membership and
writes an audit event for state changes. Direct anonymous/client writes are not
granted. This is independent of the company's separate technical-control-plane
modules and does not change existing modules.

## Verification
- Flutter client: 100 widget tests passed; analyser clean.
- Flutter admin: 17 widget tests passed; analyser clean.
- Local Supabase: 36 pgTAP files / 776 tests passed.
- Additive migrations: `20261010213000` and `20261011023000` applied locally.
- No local database reset and no production deployment performed.
- Production release, live-device visual approval and official-contact data
  ingestion remain separate sign-offs.
