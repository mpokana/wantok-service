BEGIN;
CREATE EXTENSION IF NOT EXISTS pgtap WITH SCHEMA extensions;
SELECT plan(18);
SELECT has_table('public','vendor_policy_drafts','Versioned policy candidates exist');
SELECT has_table('public','vendor_policy_events','Policy transitions have audit events');
SELECT has_function('public','create_vendor_policy_draft',
 ARRAY['text','text','text','text','text','text','text','integer','jsonb'],
 'Reviewer draft workflow exists');
SELECT has_function('public','submit_vendor_policy_draft',ARRAY['uuid'],
 'Draft submission endpoint exists');
SELECT has_function('public','review_vendor_policy_draft',
 ARRAY['uuid','text','text'],'Independent review endpoint exists');
SELECT ok(NOT has_table_privilege('authenticated','public.vendor_policy_drafts',
 'INSERT'),'Clients cannot directly forge drafts');
SELECT ok(NOT has_table_privilege('authenticated','public.vendor_policy_drafts',
 'UPDATE'),'Clients cannot silently edit reviewed policy');
SELECT ok(NOT has_table_privilege('anon','public.vendor_policy_drafts',
 'SELECT'),'Anonymous cannot read unpublished policy');
INSERT INTO auth.users(id,aud,role,email,created_at,updated_at)
 VALUES
 ('c4800000-0000-4000-8000-000000000001',
 'authenticated','authenticated','policy-writer@wantok.local',now(),now()),
 ('c4800000-0000-4000-8000-000000000002',
 'authenticated','authenticated','policy-reviewer@wantok.local',now(),now()),
 ('c4800000-0000-4000-8000-000000000003',
 'authenticated','authenticated','policy-outsider@wantok.local',now(),now());
UPDATE public.profiles SET is_admin=true WHERE id IN
 ('c4800000-0000-4000-8000-000000000001',
  'c4800000-0000-4000-8000-000000000002');
SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub',
 'c4800000-0000-4000-8000-000000000003',true);
SELECT throws_ok($$SELECT public.create_vendor_policy_draft(
 'PG','PG-MPL','transport','Draft transport evidence notice',
 repeat('Proposed internal privacy notice content. ',4),
 'Draft processing purpose for applicant records and service checks.',
 'Pending an independent legal review of the jurisdiction.',
 180,'["Proof of operating address","Licence category validation"]'::jsonb
)$$,'42501','Operations policy administrator required',
'Outsider cannot author proposed country policy');
SELECT set_config('request.jwt.claim.sub',
 'c4800000-0000-4000-8000-000000000001',true);
SELECT throws_ok($$SELECT public.create_vendor_policy_draft(
 'PG','AU-NSW','transport','Draft transport evidence notice',
 repeat('Proposed internal privacy notice content. ',4),
 'Draft processing purpose for applicant records and service checks.',
 'Pending an independent legal review of the jurisdiction.',
 180,'["Proof of operating address"]'::jsonb
)$$,'22023','Policy draft details are incomplete or invalid',
'Country-province mismatch refused');
SELECT lives_ok($$SELECT public.create_vendor_policy_draft(
 'PG','PG-MPL','transport','Draft transport evidence notice',
 repeat('Proposed internal privacy notice content. ',4),
 'Draft processing purpose for applicant records and service checks.',
 'Pending an independent legal review of the jurisdiction.',
 180,'["Proof of operating address","Licence category validation"]'::jsonb
)$$,'Writer can create a draft with region, scope and retention');
SELECT is((SELECT state FROM public.vendor_policy_drafts LIMIT 1),
 'draft','No policy is operational at creation');
SELECT lives_ok($$SELECT public.submit_vendor_policy_draft(
 (SELECT id FROM public.vendor_policy_drafts LIMIT 1))$$,
 'Writer submits the draft for independent review');
SELECT throws_ok($$SELECT public.review_vendor_policy_draft(
 (SELECT id FROM public.vendor_policy_drafts LIMIT 1),
 'internal_review_complete',
 'Writer cannot review their own proposed policy')$$,
 '42501','Independent reviewer required for submitted draft',
 'Self-review is denied in database');
SELECT set_config('request.jwt.claim.sub',
 'c4800000-0000-4000-8000-000000000002',true);
SELECT lives_ok($$SELECT public.review_vendor_policy_draft(
 (SELECT id FROM public.vendor_policy_drafts LIMIT 1),
 'internal_review_complete',
 'Independent administrative review only, legal assessment is pending')$$,
 'Independent administrator records review');
SELECT is((SELECT state FROM public.vendor_policy_drafts LIMIT 1),
 'internal_review_complete','Internal review never activates policy');
SELECT is((SELECT count(*)::integer FROM public.vendor_policy_events),3,
 'Creation, submission and second review have audit history');
SELECT set_config('request.jwt.claim.sub',
 'c4800000-0000-4000-8000-000000000003',true);
SELECT is((SELECT count(*)::integer FROM public.vendor_policy_drafts),0,
 'Other signed-in users cannot read unpublished policy');
SELECT * FROM finish();
ROLLBACK;
