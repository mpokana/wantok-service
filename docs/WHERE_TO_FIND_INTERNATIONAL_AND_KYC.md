# Finding international service settings and Operations KYC

Local EAGLT02 apps: Services `http://127.0.0.1:3000/`, Operations
`http://127.0.0.1:3200/`, Technical Control `http://127.0.0.1:3100/`.

## Customer search filters
In Wantok Services (client mode), open **Find Wantok providers**. The
**Filter providers** panel exposes Country, Category, State/Province/Region,
Town/City, Provider type, Minimum rating, Sort and Remote/Online. Country is
based on device locale or saved preference, not verified GPS; it is editable.

## Vendor country and currency
In Wantok Services, switch to **Vendor mode** using an authorised vendor
account. Open **Listings → My services**. Service cards always show their
country/region/town and currency (where stored). For a **draft or rejected**
service, select **Edit country, currency & service** to edit the service
country, coverage region/town, ISO currency and base price.

Approved/pending listings remain locked to preserve the review workflow.
A vendor without an attached service cannot edit one yet. This is not the
public **Find Wantok providers** page.

## Operations KYC
Sign in to **Wantok Operations** with the existing Operations admin role.
Select **Verification & KYC** from the left menu, or the explicit
Verification & KYC icon/link in the top bar. On tablet/mobile, the left
menu collapses into a drawer. The Overview metric also links to KYC.

Verification data is read from existing provider and preliminary onboarding
records. This is **not** a newly certified KYC service and does not override
the established applicant approval process. If access is unavailable,
the KYC page should show the permission/retry state.

## Current rendering and cache
Production PWA caching is preserved. On **localhost only**, Flutter
bootstrap releases the old development service worker to avoid stale bundles
persisting after a rebuild. After an upgrade, revisit the page and hard-refresh
once if an already-open tab still shows old content. Logout/session data are
not deleted by this code.

The sample Operations reference illustration has fabricated figures: live
Operations must use actual authorised records or show unavailable instead.
