BEGIN;
CREATE EXTENSION IF NOT EXISTS pgtap WITH SCHEMA extensions;
SELECT plan(30);
SELECT has_table('public','operations_provisioning_authorities',
 'Independent provisioning authority register exists');
SELECT has_table('public','operations_duty_change_requests',
 'Duty grant and revocation requests are durable');
SELECT has_table('public','operations_duty_change_events',
 'Every staff change request and approval is audited');
SELECT ok(NOT has_table_privilege('authenticated',
 'public.operations_provisioning_authorities','INSERT'),
 'Staff may not authorise themselves');
SELECT ok(NOT has_table_privilege('authenticated',
 'public.operations_duty_change_requests','UPDATE'),
 'Staff cannot directly alter approval decisions');
SELECT ok(NOT has_function_privilege('authenticated',
 'public.configure_operations_provisioner(uuid,text,text,uuid,text,boolean)','EXECUTE'),
 'Provisioning bootstrap is trusted-server only');
SELECT ok(has_function_privilege('authenticated',
 'public.request_operations_duty_change(text,uuid,text,text,text,text,timestamptz,uuid,text)','EXECUTE'),
 'Authenticated staff may request only after scope check');
SELECT ok(has_function_privilege('authenticated',
 'public.decide_operations_duty_change(uuid,boolean,text)','EXECUTE'),
 'Second approver endpoint enforces independent scope');

INSERT INTO auth.users(id,aud,role,email,created_at,updated_at)
SELECT ('b6300000-0000-4000-8000-'||lpad(n::text,12,'0'))::uuid,
 'authenticated','authenticated','e6d-operator-'||n||'@wantok.local',
 now(),now() FROM generate_series(1,5) n;
SELECT public.configure_operations_provisioner(
 'b6300000-0000-4000-8000-000000000001','PG','requester',
 'b6300000-0000-4000-8000-000000000005',
 'Independent synthetic staff authorisation for test only',true);
SELECT public.configure_operations_provisioner(
 'b6300000-0000-4000-8000-000000000002','PG','approver',
 'b6300000-0000-4000-8000-000000000005',
 'Independent synthetic approval verification for test only',true);
SELECT public.register_operations_region('PG-MPL','Morobe',
 'b6300000-0000-4000-8000-000000000005',
 'Synthetic ISO subdivision checked in rollback-only unit test');
SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub',
 'b6300000-0000-4000-8000-000000000004',true);
SELECT throws_ok($$SELECT public.request_operations_duty_change(
 'grant','b6300000-0000-4000-8000-000000000003',
 'case_reviewer','PG','PG-MPL','trades',now()+interval '30 days',
 NULL,'Unauthorised user cannot create their own duty assignments')$$,
 '42501','Independent authorised requester required',
 'Ordinary user may not request scope grants');
SELECT set_config('request.jwt.claim.sub',
 'b6300000-0000-4000-8000-000000000001',true);
SELECT throws_ok($$SELECT public.request_operations_duty_change(
 'grant','b6300000-0000-4000-8000-000000000001',
 'case_reviewer','PG','PG-MPL','trades',now()+interval '30 days',
 NULL,'Requester cannot authorise their own target duty grant')$$,
 '42501','Independent authorised requester required',
 'Requester cannot nominate themselves');
SELECT throws_ok($$SELECT public.request_operations_duty_change(
 'grant','b6300000-0000-4000-8000-000000000003',
 'case_reviewer','PG','PG-FAKE','trades',now()+interval '30 days',
 NULL,'A syntactically plausible but unverified province code')$$,
 '22023','Verified assignment scope and purpose required',
 'Uncertified subdivision fails closed');
SELECT throws_ok($$SELECT public.request_operations_duty_change(
 'grant','b6300000-0000-4000-8000-000000000003',
 'case_reviewer','AU',NULL,'trades',now()+interval '30 days',
 NULL,'Wrong country is outside requester authorisation boundary')$$,
 '42501','Independent authorised requester required',
 'Country-wide authority cannot be inherited');
SELECT throws_ok($$SELECT public.request_operations_duty_change(
 'grant','b6300000-0000-4000-8000-000000000003',
 'case_reviewer','PG','PG-MPL','trades',now()+interval '400 days',
 NULL,'Long duration cannot bypass bounded grant expiry')$$,
 '22023','Bounded grant expiry required',
 'A long-lived indefinite staff assignment is rejected');
SELECT lives_ok($$SELECT set_config('test.e6d_grant_request',
 public.request_operations_duty_change(
 'grant','b6300000-0000-4000-8000-000000000003',
 'case_reviewer','PG','PG-MPL','trades',now()+interval '30 days',
 NULL,'Independent reviewer access for the staged test jurisdiction')::text,true)$$,
 'Authorised requester creates a bounded proposal');
SELECT is((SELECT count(*)::integer FROM public.operations_duty_grants
 WHERE staff_user_id='b6300000-0000-4000-8000-000000000003'),0,
 'Proposal alone cannot grant privileges');
SELECT throws_ok($$SELECT public.decide_operations_duty_change(
 current_setting('test.e6d_grant_request')::uuid,true,
 'The requester may not approve their own submitted proposal')$$,
 '42501','Different current independent approver required',
 'Request author cannot approve themselves');
SELECT set_config('request.jwt.claim.sub',
 'b6300000-0000-4000-8000-000000000003',true);
SELECT throws_ok($$SELECT public.decide_operations_duty_change(
 current_setting('test.e6d_grant_request')::uuid,true,
 'Target staff member must not approve their own assignment')$$,
 '42501','Different current independent approver required',
 'Target staff cannot approve their own duty');
SELECT set_config('request.jwt.claim.sub',
 'b6300000-0000-4000-8000-000000000002',true);
SELECT lives_ok($$SELECT public.decide_operations_duty_change(
 current_setting('test.e6d_grant_request')::uuid,true,
 'Independent approver confirmed a bounded and verified work duty')$$,
 'Different approved officer grants scoped duty once');
SELECT is((SELECT count(*)::integer FROM public.operations_duty_grants
 WHERE staff_user_id='b6300000-0000-4000-8000-000000000003'
 AND duty='case_reviewer' AND revoked_at IS NULL),0,
 'Approver cannot enumerate another employee duty grants under RLS');
SELECT throws_ok($$SELECT public.decide_operations_duty_change(
 current_setting('test.e6d_grant_request')::uuid,true,
 'Repeated grant approval should never issue a second grant')$$,
 '22023','Open change request required',
 'An approved request cannot be replayed');
SELECT set_config('request.jwt.claim.sub',
 'b6300000-0000-4000-8000-000000000003',true);
SELECT ok(public.has_operations_scope('case_reviewer','PG','PG-MPL','trades'),
 'Issued duty is usable only in its verified scope');
SELECT ok(NOT public.has_operations_scope('case_reviewer','AU','AU-NSW','trades'),
 'Approved country scope does not imply access abroad');
SELECT set_config('test.e6d_grant_id',
 (SELECT id::text FROM public.operations_duty_grants
 WHERE staff_user_id=auth.uid() AND duty='case_reviewer' AND revoked_at IS NULL),
 true);

SELECT set_config('request.jwt.claim.sub',
 'b6300000-0000-4000-8000-000000000001',true);
SELECT throws_ok($$SELECT public.request_operations_duty_change(
 'grant','b6300000-0000-4000-8000-000000000003',
 'case_reviewer','PG','PG-MPL','trades',now()+interval '30 days',
 NULL,'An already assigned work scope may not receive duplicate grants')$$,
 '23505','Active equivalent duty already exists',
 'Duplicate active scope grant is blocked');
SELECT lives_ok($$SELECT set_config('test.e6d_revoke_request',
 public.request_operations_duty_change(
 'revoke','b6300000-0000-4000-8000-000000000003',
 'case_reviewer','PG','PG-MPL','trades',NULL,
 current_setting('test.e6d_grant_id')::uuid,
 'The original duty is no longer required for this work')::text,true)$$,
 'Original requester can propose independently approved revocation');
SELECT set_config('request.jwt.claim.sub',
 'b6300000-0000-4000-8000-000000000003',true);
SELECT throws_ok($$SELECT public.decide_operations_duty_change(
 current_setting('test.e6d_revoke_request')::uuid,true,
 'Target person cannot approve their own revoked assignment')$$,
 '42501','Different current independent approver required',
 'Target cannot overrule their own proposed offboarding');
SELECT set_config('request.jwt.claim.sub',
 'b6300000-0000-4000-8000-000000000002',true);
SELECT lives_ok($$SELECT public.decide_operations_duty_change(
 current_setting('test.e6d_revoke_request')::uuid,true,
 'Independent decision confirmed the duty is no longer necessary')$$,
 'Independent approver completes staff offboarding');
SELECT set_config('request.jwt.claim.sub',
 'b6300000-0000-4000-8000-000000000003',true);
SELECT ok(NOT public.has_operations_scope('case_reviewer','PG','PG-MPL','trades'),
 'Offboarded staff immediately loses PostgreSQL duty');
RESET ROLE;
SELECT is((SELECT count(*)::integer FROM public.operations_duty_events
 WHERE grant_id IN(SELECT id FROM public.operations_duty_grants
 WHERE staff_user_id='b6300000-0000-4000-8000-000000000003')
 AND event_type='revoked'),1,
 'Revocation appends one durable duty event');
SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub',
 'b6300000-0000-4000-8000-000000000002',true);
SELECT throws_ok($$SELECT public.decide_operations_duty_change(
 current_setting('test.e6d_revoke_request')::uuid,true,
 'A previously decided revocation may not be applied again')$$,
 '22023','Open change request required',
 'Duplicate offboarding decision is rejected');
SELECT throws_ok($$SELECT public.admin_set_provider_resource_status(
 NULL,'active')$$,
 '42501','Legacy resource moderation disabled pending independent release',
 'Legacy resource activation remains sealed');
SELECT * FROM finish();
ROLLBACK;
