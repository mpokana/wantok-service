# Wantok Services — International Discovery & Operations (11 October 2026)

## Separation of duties
- Public client: Wantok Services, Flutter shared across Android and responsive web.
- Business administration: **Wantok Operations** (existing `apps/wantok_admin` package kept for API/build compatibility).
- Platform engineering: **Wantok Technical Control** (separate RBAC, modules, themes, media, preview/publish).

## Implemented in this change
- Provider search filters: country (ISO alpha-2), region/state/province, town/city,
  category, individual/business/organisation, minimum rating, and remote/online
  services. Sorting uses the returned ranking, rating, review count or name.
- Country starts as a browser/device-locale *suggestion*. It is NOT GPS or verified
  physical location; the user can select another country or all countries.
  Signed-in user's country/region/town preference persists through a per-user RLS
  table. Region/town options come only from verified active service listings.
- Provider preliminary intake explicitly selects a service country (no automatic
  verification). Vendor service editors allow a service country and ISO currency,
  preserving their existing approval/review workflow.
- Operations: visually separated green/gold dashboard and sidebar, compact
  desktop/tablet/mobile presentation, an explicit Verification & KYC workspace.
  KYC screen draws from real provider verification status and preliminary
  applicant checks; it does not grant approval or accept sensitive documents.
  Statistics are loaded under existing RLS, never invented fixture numbers.
- Technical Control: green brand presentation, still separate from business
  Operations permissions. Existing Theme & Media preview/publish is preserved.

## Important production caveats
1. **Precise geographic default is not implemented.** Production-grade
   country+state detection needs user-approved location permission and a
   contracted reverse-geocoding provider, with manual override and privacy
   handling. Browser language/locale is not reliable geographic evidence.
2. New provider profiles still require controlled country-specific verification;
   a staged registration is not official KYC or business approval.
3. Multi-country financial processing is **not enabled**. Currency labels and
   service currencies are stored, but FX, regional taxes/VAT/GST, local payment
   providers, payout compliance, refunds, sanctions checks and chargeback
   handling require country-scoped integration and legal review.
4. Region/town are plain text for now. Before large-scale rollout, create
   ISO 3166-2 subnational references, normalised locality IDs, timezone data,
   international address formats, phone country codes, and translations.
5. Country coverage, service availability, marketing permissions, tax/KYC
   document retention, and privacy/data-residency rules differ by jurisdiction.
6. The Operations reference artwork contains illustrative counts. Only actual
   authorised records appear in the implemented dashboard.
7. Web endpoints are local development previews; this task does **not** deploy
   to a public production domain or change payment/booking activation.

## Validation / release
- Run Flutter analyse and unit/widget tests in client, Operations and Technical.
- Run `npm run db:migrate` then `npm run db:test` against **local** Supabase.
- Build each web app with the locally controlled dart-define file.
- Confirm ports for client, Technical, Operations independently; hard-refresh
  browser after publishing.
- Git commit the explicit changed source/migrations/tests and push the feature
  branch only; do not stage unrelated local `supabase/snippets`.
