BEGIN;
CREATE EXTENSION IF NOT EXISTS pgtap WITH SCHEMA extensions;
SELECT plan(36);
SELECT has_table('public','operations_duty_grants','Explicit staff jurisdiction grants exist');
SELECT has_table('public','operations_duty_events','Grant and revocation decisions have an audit log');
SELECT has_table('public','operations_policy_recusals','Policy conflicts of interest can be recorded');
SELECT has_function('public','has_operations_scope',
 ARRAY['text','text','text','text'],'Scoped authority resolves against caller JWT');
SELECT ok(NOT has_table_privilege('authenticated','public.operations_duty_grants','INSERT'),
 'Staff cannot grant themselves a duty');
SELECT ok(NOT has_table_privilege('authenticated','public.operations_duty_grants','UPDATE'),
 'Staff cannot extend or reactivate a duty');
SELECT ok(NOT has_table_privilege('authenticated','public.operations_duty_grants','DELETE'),
 'Staff cannot erase grants');
SELECT ok(NOT has_table_privilege('anon','public.operations_duty_grants','SELECT'),
 'Anonymous visitors cannot read staff grants');
SELECT ok(NOT has_function_privilege('authenticated',
 'public.provision_operations_duty(uuid,text,text,text,text,timestamptz,text)','EXECUTE'),
 'Staff cannot invoke provisioning RPC');
SELECT ok(NOT has_function_privilege('authenticated',
 'public.revoke_operations_duty(uuid,text)','EXECUTE'),
 'Staff cannot revoke assigned privileges via provisioning RPC');
SELECT ok(NOT has_function_privilege('authenticated',
 'public.record_policy_recusal(uuid,uuid,text)','EXECUTE'),
 'Staff cannot remove themselves from recusal controls');
SELECT ok(NOT has_table_privilege('authenticated','public.vendor_policy_drafts','UPDATE'),
 'Policy content cannot be modified directly');
INSERT INTO auth.users(id,aud,role,email,created_at,updated_at)
VALUES
('c5000000-0000-4000-8000-000000000001','authenticated','authenticated','e6-policy-author@wantok.local',now(),now()),
('c5000000-0000-4000-8000-000000000002','authenticated','authenticated','e6-policy-reviewer@wantok.local',now(),now()),
('c5000000-0000-4000-8000-000000000003','authenticated','authenticated','e6-au-administrator@wantok.local',now(),now()),
('c5000000-0000-4000-8000-000000000004','authenticated','authenticated','e6-food-reviewer@wantok.local',now(),now()),
('c5000000-0000-4000-8000-000000000005','authenticated','authenticated','e6-technical-admin@wantok.local',now(),now()),
('c5000000-0000-4000-8000-000000000006','authenticated','authenticated','e6-independent-reviewer@wantok.local',now(),now());
UPDATE public.profiles SET is_admin=true WHERE id IN
('c5000000-0000-4000-8000-000000000001',
 'c5000000-0000-4000-8000-000000000002',
 'c5000000-0000-4000-8000-000000000003');
INSERT INTO public.user_roles(user_id,role_code)
VALUES('c5000000-0000-4000-8000-000000000005','tech_platform_admin')
ON CONFLICT DO NOTHING;
INSERT INTO public.operations_duty_grants(
 staff_user_id,duty,country_code,region_code,category_scope,assignment_reason)
VALUES
('c5000000-0000-4000-8000-000000000001','policy_author','PG','PG-MPL','transport','Approved test jurisdiction for policy author'),
('c5000000-0000-4000-8000-000000000002','policy_reviewer','PG',NULL,'transport','Approved country-wide independent review test'),
('c5000000-0000-4000-8000-000000000003','policy_reviewer','AU','AU-NSW','transport','Foreign jurisdiction test does not include PNG'),
('c5000000-0000-4000-8000-000000000004','policy_reviewer','PG','PG-MPL','food','Wrong category should have no access'),
('c5000000-0000-4000-8000-000000000006','policy_reviewer','PG','PG-MPL','transport','Alternate independent reviewer for recusals');
SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub','c5000000-0000-4000-8000-000000000001',true);
SELECT ok(public.has_operations_scope('policy_author','PG','PG-MPL','transport'),
 'Scoped author can act in assigned PNG province and service');
SELECT ok(NOT public.has_operations_scope('policy_author','PG','PG-NCD','transport'),
 'Province mismatch denied');
SELECT ok(NOT public.has_operations_scope('policy_author','AU','AU-NSW','transport'),
 'Country mismatch denied');
SELECT ok(NOT public.has_operations_scope('policy_author','PG','PG-MPL','food'),
 'Category mismatch denied');
SELECT ok(NOT public.has_operations_scope('policy_author','PG',NULL,'transport'),
 'Provincial assignment is not an implicit country-wide grant');
SELECT ok(NOT public.has_operations_scope('policy_reviewer','PG','PG-MPL','transport'),
 'Policy author is not automatically a policy reviewer');
SELECT throws_ok($$SELECT public.create_vendor_policy_draft(
 'AU','AU-NSW','transport','AU draft for unauthorised author',
 repeat('Proposed evidence note and privacy draft. ',4),
 'Proposed processing purpose for internal screening of providers.',
 'Country legal basis pending research by appropriate local counsel.',
 90,'["Registered address proof"]'::jsonb)$$,
 '42501','Operations policy administrator required',
 'Author cannot create policy in a foreign country');
SELECT throws_ok($$SELECT public.create_vendor_policy_draft(
 'PG','PG-NCD','transport','NCD draft for unauthorised author',
 repeat('Proposed evidence note and privacy draft. ',4),
 'Proposed processing purpose for internal screening of providers.',
 'Country legal basis pending research by appropriate local counsel.',
 90,'["Registered address proof"]'::jsonb)$$,
 '42501','Operations policy administrator required',
 'Author cannot create policy in unassigned PNG province');
SELECT lives_ok($$SELECT public.create_vendor_policy_draft(
 'PG','PG-MPL','transport','PNG transport draft for review',
 repeat('Proposed evidence note and privacy draft. ',4),
 'Proposed processing purpose for internal screening of providers.',
 'Country legal basis pending research by appropriate local counsel.',
 90,'["Registered address proof"]'::jsonb)$$,
 'Assigned policy author can create a permitted internal draft');
SELECT lives_ok($$SELECT public.submit_vendor_policy_draft(
 (SELECT id FROM public.vendor_policy_drafts LIMIT 1))$$,
 'Author can submit permitted draft');
SELECT throws_ok($$SELECT public.review_vendor_policy_draft(
 (SELECT id FROM public.vendor_policy_drafts LIMIT 1),
 'internal_review_complete','Attempted self-review by policy author is not permitted')$$,
 '42501','Independent reviewer required for submitted draft',
 'Author cannot review own draft');
SELECT set_config('request.jwt.claim.sub','c5000000-0000-4000-8000-000000000003',true);
SELECT is((SELECT count(*)::integer FROM public.vendor_policy_drafts),0,
 'Admin and reviewer of a foreign country sees zero PNG drafts');
SELECT set_config('request.jwt.claim.sub','c5000000-0000-4000-8000-000000000004',true);
SELECT is((SELECT count(*)::integer FROM public.vendor_policy_drafts),0,
 'Reviewer with wrong category cannot see transport draft');
SELECT set_config('request.jwt.claim.sub','c5000000-0000-4000-8000-000000000005',true);
SELECT is((SELECT count(*)::integer FROM public.vendor_policy_drafts),0,
 'Technical platform administrator cannot see Operations policy drafts');
SELECT set_config('request.jwt.claim.sub','c5000000-0000-4000-8000-000000000002',true);
SELECT is((SELECT count(*)::integer FROM public.vendor_policy_drafts),1,
 'Country-wide matching reviewer can see an assigned draft');
RESET ROLE;
INSERT INTO public.operations_policy_recusals(policy_id,staff_user_id,reason)
 SELECT id,'c5000000-0000-4000-8000-000000000002',
 'Independent reviewer declared conflict of interest and withdrew'
 FROM public.vendor_policy_drafts LIMIT 1;
SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub','c5000000-0000-4000-8000-000000000002',true);
SELECT throws_ok($$SELECT public.review_vendor_policy_draft(
 (SELECT id FROM public.vendor_policy_drafts LIMIT 1),
 'internal_review_complete','Reviewer declared conflict and cannot decide policy')$$,
 '42501','Independent reviewer required for submitted draft',
 'A recusant cannot record a policy decision');
SELECT set_config('request.jwt.claim.sub','c5000000-0000-4000-8000-000000000006',true);
SELECT is((SELECT count(*)::integer FROM public.operations_duty_grants),1,
 'Scoped reviewer can only read their own duty grant');
SELECT throws_ok($$SELECT public.grant_user_role(
 'c5000000-0000-4000-8000-000000000006'::uuid,'admin',NULL)$$,
 'P0001','Operations admin access required',
 'Scoped reviewer cannot self-escalate into an Operations administrator');
SELECT throws_ok($$SELECT public.revoke_user_role(
 'c5000000-0000-4000-8000-000000000001'::uuid,'admin')$$,
 'P0001','Operations admin access required',
 'Scoped reviewer cannot strip another administrator role');
SELECT lives_ok($$SELECT public.review_vendor_policy_draft(
 (SELECT id FROM public.vendor_policy_drafts LIMIT 1),
 'internal_review_complete','Another reviewer completes internal administrative review only')$$,
 'Different authorised non-conflicted reviewer can decide');
SELECT is((SELECT state FROM public.vendor_policy_drafts LIMIT 1),
 'internal_review_complete','Review remains non-operative and cannot authorise uploads');
SELECT is((SELECT count(*)::integer FROM public.vendor_policy_events),3,
 'Creation submission and review are audited');
SELECT set_config('request.jwt.claim.sub','c5000000-0000-4000-8000-000000000003',true);
SELECT is((SELECT count(*)::integer FROM public.vendor_policy_events),0,
 'Foreign administrator cannot read policy audit events');
RESET ROLE;
UPDATE public.operations_duty_grants
SET revoked_at=clock_timestamp(),revoke_reason='Test revocation of scoped policy author duty'
WHERE staff_user_id='c5000000-0000-4000-8000-000000000001';
SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub','c5000000-0000-4000-8000-000000000001',true);
SELECT ok(NOT public.has_operations_scope('policy_author','PG','PG-MPL','transport'),
 'Revoking a duty immediately removes effective access');
SELECT * FROM finish();
ROLLBACK;
