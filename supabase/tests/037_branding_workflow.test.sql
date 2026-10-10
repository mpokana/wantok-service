BEGIN;
create extension if not exists pgtap with schema extensions;
SELECT plan(13);
SELECT ok((public.get_published_wantok_branding()->'theme'->>'primary')='#006747',
  'published theme readable');
SELECT throws_ok($$ SELECT public.save_wantok_branding_draft('{}'::jsonb,1) $$,
  'P0001','Technical platform administrator required','anonymous cannot save');
INSERT INTO auth.users (id,aud,role,email,created_at,updated_at)
VALUES ('d9000000-0000-0000-0000-000000000001','authenticated','authenticated',
  'branding-test@wantok.local',now(),now());
INSERT INTO public.user_roles(user_id,role_code)
VALUES ('d9000000-0000-0000-0000-000000000001','tech_platform_admin');
SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub','d9000000-0000-0000-0000-000000000001',true);
SELECT ok(public.get_wantok_branding_workspace() ? 'draft','admin reads draft');
SELECT ok(public.validate_wantok_branding((public.get_wantok_branding_workspace()->'draft')),
  'default validates');
SELECT is(public.save_wantok_branding_draft(
  jsonb_build_object('theme',jsonb_build_object('mode','dark','primary','#004422',
  'secondary','#F3C846','cardRadius',20),'media','{}'::jsonb),1),2,'admin saves a draft');
SELECT ok(public.get_published_wantok_branding()->'theme'->>'mode'='light',
  'saving draft does not affect public');
SELECT is(public.publish_wantok_branding_draft(1,2),2,'admin publishes');
SELECT is(public.get_published_wantok_branding()->'theme'->>'mode','dark',
  'new version visible');
SELECT is(public.restore_wantok_branding_version(1,2),3,'admin can rollback');
SELECT is(public.get_published_wantok_branding()->'theme'->>'mode','light',
  'rollback restores prior values');
SELECT throws_ok($$ SELECT public.publish_wantok_branding_draft(1,1) $$,
  'P0001','Branding was changed by another admin; reload first','stale writes rejected');
SELECT ok(NOT public.validate_wantok_branding(
  jsonb_build_object('theme',public.get_published_wantok_branding()->'theme',
    'media',jsonb_build_object('education-training',
      jsonb_build_object('cardImage','https://malicious.example/image.png')))),
  'external arbitrary URLs cannot be published');
SELECT ok(NOT public.validate_wantok_branding(
  jsonb_build_object('theme',public.get_published_wantok_branding()->'theme',
    'media',jsonb_build_object('general-labour',
      jsonb_build_object('cardImage',
        'categories/education-training/cardImage/00000000-0000-0000-0000-000000000000.png')))),
  'image path must belong to its category and placement');
SELECT * FROM finish();
ROLLBACK;