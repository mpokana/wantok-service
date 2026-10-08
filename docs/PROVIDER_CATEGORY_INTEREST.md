# Provider discovery and pre-onboarding interest — 8 October 2026

## Customer path

The existing verified-provider search RPC remains authoritative: only active verified providers with approved services can be displayed. Services → an information-only category now offers **Browse verified providers** with that category pre-selected, followed by **Register provider interest** for a signed-in account. There is no promise of a response or notification, and no identity, licence, medical or financial data is requested. Repeated interest submissions are safely idempotent.

The interest action appears only if the connected backend has a matching category ID. A build talking to a backend without the new migration still shows the truthful non-bookable information page without a fake working opt-in.

## Backend security

Migration 20261008223000_provider_category_interest.sql adds public.provider_category_interests with authenticated user ID, catalogue category ID, created timestamp, and fixed received status. RLS permits users to read only their own row; platform administrators can read the queue. Ordinary authenticated users have no direct table INSERT/UPDATE/DELETE permissions. The only submission entry point is the register_provider_category_interest(text) security-definer RPC, which validates login, active catalogue-only category, information booking mode and onboarding-disabled metadata.

The RPC inserts neither a provider application nor a provider profile, approved service, role, booking or payment. It rejects existing live transactional categories. Migration 20261008214500_client_category_expansion.sql must already be present.

## Operations control

Wantok Operations Admin → Providers → Interest queue opens a separate read-only list of category interests, with date and abbreviated account ID. It offers no approval/activation button. The pre-existing formal Provider Applications workflow remains unchanged. Regulated medical and financial provider requirements need dedicated policies and authorisation before any formal onboarding route can be enabled.

## Tests and deployment

Database test 029_provider_category_interest.test.sql validates category restriction, RLS, no direct INSERT grants, registration idempotency and isolation from another account. Flutter widget tests validate opt-in and a disabled re-submission state. Complete release gate: scripts/flutter/check.ps1, npm run db:test, git diff --check, in-place emulator install, local Git bundle and verified GitHub feature-branch push.

**Production was not modified.** Both the category-expansion and interest migrations were applied only to the EAGLT02 local Supabase development database. Production rollout will require approval, database backup, compatible mobile build and a planned cutover. Smoke QA records stay separate and identified by their little s badge.
