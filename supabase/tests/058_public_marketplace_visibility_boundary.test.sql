-- E6K: read-only proof of marketplace RLS boundaries and explicit broad
-- metadata exposure risk. All records are synthetic and rolled back.
-- A PASS does NOT approve public access to arbitrary metadata/address fields.
BEGIN;
CREATE EXTENSION IF NOT EXISTS pgtap WITH SCHEMA extensions;
SELECT plan(17);

SELECT ok((SELECT relrowsecurity FROM pg_class
  WHERE oid='public.provider_profiles'::regclass),
  'Provider profiles RLS remains enabled');
SELECT ok((SELECT relrowsecurity FROM pg_class
  WHERE oid='public.provider_services'::regclass),
  'Provider services RLS remains enabled');
SELECT ok(has_column_privilege('anon',
  'public.provider_profiles','metadata','SELECT'),
  'Risk inventory: anonymous users currently can read verified profile metadata');
SELECT ok(has_column_privilege('anon',
  'public.provider_services','metadata','SELECT'),
  'Risk inventory: anonymous users currently can read active service metadata');
SELECT ok(NOT has_table_privilege('anon',
  'public.provider_profiles','UPDATE'),
  'Anonymous users cannot modify provider profiles');
SELECT ok(NOT has_table_privilege('anon',
  'public.provider_services','UPDATE'),
  'Anonymous users cannot modify provider services');

INSERT INTO auth.users(id,aud,role,email,created_at,updated_at) VALUES
 ('b6580000-0000-4000-8000-000000000001','authenticated','authenticated',
  'public-verified-fixture@wantok.invalid',now(),now()),
 ('b6580000-0000-4000-8000-000000000002','authenticated','authenticated',
  'public-draft-fixture@wantok.invalid',now(),now()),
 ('b6580000-0000-4000-8000-000000000003','authenticated','authenticated',
  'public-inactive-fixture@wantok.invalid',now(),now()),
 ('b6580000-0000-4000-8000-000000000004','authenticated','authenticated',
  'public-other-user@wantok.invalid',now(),now());
INSERT INTO public.provider_profiles
 (provider_id,display_name,verification_status,is_active,metadata)
VALUES
 ('b6580000-0000-4000-8000-000000000001','Fixture Verified','verified',true,
   '{"internal_marker":"SYNTHETIC_NOT_APPROVED_FOR_PUBLIC"}'::jsonb),
 ('b6580000-0000-4000-8000-000000000002','Fixture Pending','pending',true,
   '{"internal_marker":"PENDING_PRIVATE"}'::jsonb),
 ('b6580000-0000-4000-8000-000000000003','Fixture Inactive','verified',false,
   '{"internal_marker":"INACTIVE_PRIVATE"}'::jsonb);
INSERT INTO public.provider_services
 (provider_id,category_id,title,status,metadata)
VALUES
 ('b6580000-0000-4000-8000-000000000001',
   (SELECT id FROM public.service_categories ORDER BY slug LIMIT 1),
   'Fixture Visible Service','active',
   '{"internal_marker":"SYNTHETIC_SERVICE_METADATA"}'::jsonb),
 ('b6580000-0000-4000-8000-000000000001',
   (SELECT id FROM public.service_categories ORDER BY slug LIMIT 1),
   'Fixture Draft Service','draft','{"internal_marker":"HIDDEN_DRAFT"}'::jsonb),
 ('b6580000-0000-4000-8000-000000000002',
   (SELECT id FROM public.service_categories ORDER BY slug LIMIT 1),
   'Fixture Unverified Service','active','{"internal_marker":"HIDDEN_UNVERIFIED"}'::jsonb);

SET LOCAL ROLE anon;
SELECT is((SELECT count(*)::int FROM public.provider_profiles
  WHERE provider_id::text LIKE 'b6580000-%'),1,
  'Anonymous profile listing contains verified active profile only');
SELECT is((SELECT count(*)::int FROM public.provider_services
  WHERE title LIKE 'Fixture %'),1,
  'Anonymous service listing contains only active verified-provider service');
SELECT is((SELECT metadata->>'internal_marker' FROM public.provider_profiles
  WHERE provider_id='b6580000-0000-4000-8000-000000000001'),
 'SYNTHETIC_NOT_APPROVED_FOR_PUBLIC',
 'Exposure witness: eligible profile exposes unrestricted metadata');
SELECT is((SELECT metadata->>'internal_marker' FROM public.provider_services
  WHERE title='Fixture Visible Service'),'SYNTHETIC_SERVICE_METADATA',
 'Exposure witness: eligible active service exposes unrestricted metadata');
SELECT is((SELECT count(*)::int FROM public.provider_services
  WHERE title='Fixture Draft Service'),0,
 'Anonymous user cannot read a draft service even from verified provider');
SELECT is((SELECT count(*)::int FROM public.provider_services
  WHERE title='Fixture Unverified Service'),0,
 'Anonymous user cannot read active service from unverified provider');

SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub',
 'b6580000-0000-4000-8000-000000000002',true);
SELECT is((SELECT count(*)::int FROM public.provider_profiles
  WHERE provider_id='b6580000-0000-4000-8000-000000000002'),1,
 'Authenticated applicant can see own pending provider draft');
SELECT is((SELECT count(*)::int FROM public.provider_profiles
  WHERE provider_id='b6580000-0000-4000-8000-000000000003'),0,
 'Applicant cannot inspect another unlisted verified but inactive provider');
SELECT is((SELECT count(*)::int FROM public.provider_services
  WHERE title='Fixture Draft Service'),0,
 'Unrelated authenticated applicant cannot see others draft service');
SELECT is((SELECT count(*)::int FROM public.provider_services
  WHERE title='Fixture Visible Service'),1,
 'Authenticated user can discover active service of a verified provider');
SELECT is((SELECT count(*)::int FROM public.provider_services
  WHERE title='Fixture Unverified Service'),1,
 'Service author can read own active service pending provider verification');

RESET ROLE;
SELECT * FROM finish();
ROLLBACK;
