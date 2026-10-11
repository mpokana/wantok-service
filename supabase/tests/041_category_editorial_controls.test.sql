BEGIN;
CREATE EXTENSION IF NOT EXISTS pgtap WITH SCHEMA extensions;
SELECT plan(11);

SELECT throws_ok(
  $$ SELECT count(*) FROM public.list_managed_service_categories() $$,
  'P0001','Technical Platform Administrator required',
  'Unauthenticated user cannot list inactive categories'
);
SELECT is((SELECT count(*)::int FROM public.service_categories
  WHERE slug IN ('it-electronics','automotive-repair','agriculture-farming',
    'pets-animal-care','cleaning-maintenance','construction-trades')),6,
  'Six missing service families seeded without duplicates');
SELECT is((SELECT count(*)::int FROM public.service_categories
  WHERE slug IN ('it-electronics','automotive-repair','agriculture-farming',
    'pets-animal-care','cleaning-maintenance','construction-trades')
    AND is_active = false AND show_on_home = false AND show_in_services = false),6,
  'New categories are inactive and invisible in app/Web');

INSERT INTO auth.users(id,aud,role,email,created_at,updated_at)
VALUES('e9000000-0000-0000-0000-000000000001',
  'authenticated','authenticated','category-editor-test@wantok.local',
  now(),now());
INSERT INTO public.user_roles(user_id,role_code)
VALUES('e9000000-0000-0000-0000-000000000001','tech_platform_admin');
SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub',
  'e9000000-0000-0000-0000-000000000001',true);

SELECT ok((SELECT count(*) FROM public.list_managed_service_categories()) >= 29,
  'Admin can list active and inactive categories');
SELECT ok(public.manage_service_category('create',
  '{"slug":"cx1-test-draft","name":"CX1 Test Draft","vertical":"people",
    "booking_mode":"information","sort_order":995,
    "is_active":false,"show_on_home":false,"show_in_services":false}'::jsonb)
  ? 'id', 'Admin creates inactive category draft');
SELECT is((public.manage_service_category('update',
  '{"name":"CX1 Updated Draft"}'::jsonb,
  (SELECT id FROM public.list_managed_service_categories() WHERE slug='cx1-test-draft'))
  ->>'name'), 'CX1 Updated Draft', 'Admin edits category details');
SELECT throws_ok($$ SELECT public.manage_service_category('update',
  '{"is_active":true,"show_on_home":true}'::jsonb,
  (SELECT id FROM public.list_managed_service_categories() WHERE slug='it-electronics')) $$,
  'P0001','New category requires an approved picture before activation',
  'Seeded draft cannot activate without a photo');
SELECT throws_ok($$ SELECT public.manage_service_category('update',
  '{"image_path":"https://untrusted.example/unsafe.jpg"}'::jsonb,
  (SELECT id FROM public.list_managed_service_categories() WHERE slug='cx1-test-draft')) $$,
  'P0001','Image must be a category-scoped uploaded image',
  'Remote arbitrary image URLs rejected');
SELECT ok((public.manage_service_category('archive','{}'::jsonb,
  (SELECT id FROM public.list_managed_service_categories() WHERE slug='cx1-test-draft'))
  ->>'is_active')::boolean = false,'Archive keeps category inactive');
SELECT ok(public.manage_service_category('remove','{}'::jsonb,
  (SELECT id FROM public.list_managed_service_categories() WHERE slug='cx1-test-draft'))
  ->>'removed' = 'true','Unused inactive drafts may be removed');
SELECT is((SELECT count(*)::int FROM public.list_managed_service_categories() WHERE slug='cx1-test-draft'),
  0,'Removal does not leave duplicate temporary records');
SELECT * FROM finish();
ROLLBACK;
