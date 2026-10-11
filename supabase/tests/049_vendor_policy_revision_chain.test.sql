BEGIN;
CREATE EXTENSION IF NOT EXISTS pgtap WITH SCHEMA extensions;
SELECT plan(12);
SELECT has_column('public','vendor_policy_drafts','replaces_policy_id',
 'Revisions preserve predecessor reference');
SELECT has_function('public','revise_vendor_policy_draft',
 ARRAY['uuid','text','text','text','text','integer','jsonb'],
 'Separate immutable revision endpoint exists');
INSERT INTO auth.users(id,aud,role,email,created_at,updated_at)
VALUES('c4900000-0000-4000-8000-000000000001','authenticated','authenticated',
 'policy-revision-author@wantok.local',now(),now()),
 ('c4900000-0000-4000-8000-000000000002','authenticated','authenticated',
 'policy-revision-reviewer@wantok.local',now(),now());
UPDATE public.profiles SET is_admin=true WHERE id IN(
 'c4900000-0000-4000-8000-000000000001',
 'c4900000-0000-4000-8000-000000000002');
INSERT INTO public.operations_duty_grants (staff_user_id,duty,country_code,region_code,category_scope,assignment_reason)
VALUES ('c4900000-0000-4000-8000-000000000001','policy_author','PG',NULL,'trades','Test-only explicitly authorised policy author'),
 ('c4900000-0000-4000-8000-000000000002','policy_reviewer','PG',NULL,'trades','Test-only explicitly authorised independent reviewer');
SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub',
 'c4900000-0000-4000-8000-000000000001',true);
SELECT lives_ok($$SELECT public.create_vendor_policy_draft(
 'PG','PG-MPL','trades','Draft professional service notice',
 repeat('Preliminary documentation and privacy notice. ',3),
 'Purpose is to assess supplier identity and service qualifications.',
 'Country-specific legal basis still requires independent evaluation.',
 365,'["Proof of registered address","Professional competence"]'::jsonb)$$,
 'Original policy draft created');
SELECT lives_ok($$SELECT public.submit_vendor_policy_draft(
 (SELECT id FROM public.vendor_policy_drafts WHERE revision=1 LIMIT 1))$$,
 'Policy submitted');
SELECT set_config('request.jwt.claim.sub',
 'c4900000-0000-4000-8000-000000000002',true);
SELECT lives_ok($$SELECT public.review_vendor_policy_draft(
 (SELECT id FROM public.vendor_policy_drafts WHERE revision=1 LIMIT 1),
 'revision_requested',
 'Add missing data retention justification before any legal review')$$,
 'Different reviewer returns draft for revision');
SELECT set_config('request.jwt.claim.sub',
 'c4900000-0000-4000-8000-000000000001',true);
SELECT lives_ok($$SELECT public.revise_vendor_policy_draft(
 (SELECT id FROM public.vendor_policy_drafts WHERE revision=1 LIMIT 1),
 'Revised professional service notice',
 repeat('Preliminary privacy notice with revised retention proposal. ',3),
 'Purpose is to assess supplier identity and service qualifications.',
 'Country-specific legal basis still requires independent evaluation.',
 90,'["Proof of registered address","Professional competence"]'::jsonb)$$,
 'Author creates a replacement with a new ID');
SELECT is((SELECT count(*)::integer FROM public.vendor_policy_drafts),2,
 'Both versions retained');
SELECT is((SELECT revision FROM public.vendor_policy_drafts
 WHERE revision=2),2,'Revised draft has revision 2');
SELECT is((SELECT replaces_policy_id FROM public.vendor_policy_drafts
 WHERE revision=2),
 (SELECT id FROM public.vendor_policy_drafts WHERE revision=1),
 'New draft points back to reviewed predecessor');
SELECT is((SELECT state FROM public.vendor_policy_drafts WHERE revision=1),
 'revision_requested','Original review decision preserved');
SELECT is((SELECT state FROM public.vendor_policy_drafts WHERE revision=2),
 'draft','Revision does not inherit approval');
SELECT throws_ok($$SELECT public.revise_vendor_policy_draft(
 (SELECT id FROM public.vendor_policy_drafts WHERE revision=1),
 'Unauthorized duplicate revised service notice',
 repeat('Preliminary privacy notice with revised retention proposal. ',3),
 'Purpose is to assess supplier identity and service qualifications.',
 'Country-specific legal basis still requires independent evaluation.',
 90,'["Proof of registered address"]'::jsonb)$$,
 '23505','Policy has already been revised',
 'Second revision of the same predecessor is refused');
SELECT * FROM finish();
ROLLBACK;
