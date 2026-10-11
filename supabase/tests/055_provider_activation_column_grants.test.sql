BEGIN;
CREATE EXTENSION IF NOT EXISTS pgtap WITH SCHEMA extensions;
SELECT plan(19);
SELECT ok(NOT has_column_privilege('authenticated','public.profiles','is_admin','UPDATE'),
 'Account owner cannot assign global administrator flag');
SELECT ok(NOT has_column_privilege('authenticated','public.profiles','is_provider','UPDATE'),
 'Account owner cannot grant self provider role');
SELECT ok(NOT has_column_privilege('authenticated','public.profiles','is_driver','UPDATE'),
 'Account owner cannot assign driver role');
SELECT ok(NOT has_column_privilege('authenticated','public.profiles','is_driver_approved','UPDATE'),
 'Account owner cannot approve their own driver status');
SELECT ok(NOT has_column_privilege('authenticated',
 'public.provider_profiles','verification_status','UPDATE'),
 'Provider cannot directly verify themselves');
SELECT ok(NOT has_column_privilege('authenticated',
 'public.provider_profiles','is_active','UPDATE'),
 'Provider cannot turn on a suspended profile');
SELECT ok(NOT has_column_privilege('authenticated',
 'public.provider_profiles','verification_status','INSERT'),
 'Provider cannot choose verified state on profile creation');
SELECT ok(NOT has_column_privilege('authenticated',
 'public.provider_profiles','is_active','INSERT'),
 'Provider cannot choose active state on profile creation');
SELECT ok(NOT has_column_privilege('authenticated',
 'public.provider_services','status','UPDATE'),
 'Provider cannot directly activate own service listing');
SELECT ok(NOT has_column_privilege('authenticated',
 'public.provider_services','status','INSERT'),
 'Provider cannot create an initially active service');
SELECT ok(NOT has_column_privilege('authenticated',
 'public.provider_resources','status','UPDATE'),
 'Provider cannot directly activate own resource listing');
SELECT ok(NOT has_column_privilege('authenticated',
 'public.provider_resources','status','INSERT'),
 'Provider cannot create initially active equipment');
SELECT ok(has_column_privilege('authenticated',
 'public.provider_services','title','UPDATE'),
 'Harmless provider listing edits remain permitted');
SELECT ok(has_column_privilege('authenticated',
 'public.provider_resources','name','UPDATE'),
 'Harmless resource name edits remain permitted');

INSERT INTO auth.users(id,aud,role,email,created_at,updated_at)
VALUES ('b6500000-0000-4000-8000-000000000001',
 'authenticated','authenticated','e6-legacy-permissions@wantok.local',now(),now());
UPDATE public.profiles SET is_provider=true
 WHERE id='b6500000-0000-4000-8000-000000000001';
INSERT INTO public.provider_profiles(provider_id,display_name)
VALUES ('b6500000-0000-4000-8000-000000000001','Synthetic legacy provider');
INSERT INTO public.provider_services(provider_id,category_id,title,status)
SELECT 'b6500000-0000-4000-8000-000000000001',
 id,'Draft review service','draft' FROM public.service_categories
 WHERE slug='home-services';
SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub',
 'b6500000-0000-4000-8000-000000000001',true);
SELECT throws_ok($$UPDATE public.provider_services SET status='active'
 WHERE provider_id='b6500000-0000-4000-8000-000000000001'$$,
 '42501','permission denied for table provider_services',
 'Direct client activation update is denied at the SQL privilege layer');
SELECT throws_ok($$UPDATE public.provider_profiles SET verification_status='verified'
 WHERE provider_id='b6500000-0000-4000-8000-000000000001'$$,
 '42501','permission denied for table provider_profiles',
 'Direct provider identity verification update is denied');
SELECT throws_ok($$SELECT public.admin_set_provider_service_status(
 (SELECT id FROM public.provider_services WHERE provider_id=auth.uid()),
 'active')$$,
 '42501','New service activation disabled pending independent release',
 'Legacy privileged service-status API also refuses activation');
SELECT throws_ok($$SELECT public.admin_set_provider_resource_status(
 NULL,'active')$$,
 '42501','Legacy resource moderation disabled pending independent release',
 'Legacy privileged resource-status API refuses activation');
SELECT throws_ok($$SELECT public.review_provider_application(NULL,'approved')$$,
 '42501','Legacy provider approval disabled pending scoped review',
 'Legacy user verification cannot confer provider role');
SELECT * FROM finish();
ROLLBACK;
