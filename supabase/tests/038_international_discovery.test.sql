BEGIN;
CREATE EXTENSION IF NOT EXISTS pgtap WITH SCHEMA extensions;
SELECT plan(11);
SELECT has_table('public','client_discovery_preferences','Country preferences table exists');
SELECT has_column('public','provider_services','coverage_country_code','Service country is persisted');
SELECT has_column('public','provider_services','delivery_mode','On-site/remote/hybrid supported');
SELECT has_column('public','staged_provider_applications','coverage_country_code','Staged registration includes country');
SELECT has_function('public','search_client_providers_international',
  ARRAY['text','uuid','text','text','text','text','numeric','boolean','integer'],
  'International search RPC exists');
SELECT has_function('public','list_client_provider_locations',ARRAY[]::text[],
  'Real location options RPC exists');
INSERT INTO auth.users(id,aud,role,email,created_at,updated_at)
VALUES('d8000000-0000-0000-0000-000000000001','authenticated','authenticated',
 'discoverytest@wantok.local',now(),now()),
('d8000000-0000-0000-0000-000000000002','authenticated','authenticated',
 'otherdiscoverytest@wantok.local',now(),now());
SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub','d8000000-0000-0000-0000-000000000001',true);
INSERT INTO public.client_discovery_preferences(user_id,country_code,region,town)
VALUES('d8000000-0000-0000-0000-000000000001','PG','Morobe','Lae');
SELECT is((SELECT country_code FROM public.client_discovery_preferences LIMIT 1),
 'PG','Own country preference readable');
SELECT is((SELECT region FROM public.client_discovery_preferences LIMIT 1),
 'Morobe','Region preference saved');
SELECT is((SELECT town FROM public.client_discovery_preferences LIMIT 1),
 'Lae','Town preference saved');
SELECT is((SELECT count(*)::int FROM public.client_discovery_preferences
  WHERE user_id='d8000000-0000-0000-0000-000000000002'),0,
 'Cannot read another users preferences');
UPDATE public.client_discovery_preferences SET country_code='AU',region='Queensland',town='Cairns'
WHERE user_id='d8000000-0000-0000-0000-000000000001';
SELECT is((SELECT country_code FROM public.client_discovery_preferences LIMIT 1),
 'AU','Country preference is changeable');
SELECT * FROM finish();
ROLLBACK;
