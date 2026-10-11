begin;

create extension if not exists pgtap with schema extensions;
select plan(13);

insert into auth.users (
  id, aud, role, email, raw_user_meta_data, created_at, updated_at
) values
 ('b2410000-0000-0000-0000-000000000001', 'authenticated',
  'authenticated','queue-owner@wantok.local',
  '{"full_name":"Queue observer"}'::jsonb, now(), now()),
 ('b2410000-0000-0000-0000-000000000002', 'authenticated',
  'authenticated','queue-outsider@wantok.local',
  '{"full_name":"Other module observer"}'::jsonb, now(), now());

insert into public.technical_user_module_access (
  user_id, module_key, access_level_code
) values
 ('b2410000-0000-0000-0000-000000000001', 'core.messaging', 'tech_support'),
 ('b2410000-0000-0000-0000-000000000002', 'core.catalog', 'tech_support');

insert into public.notification_outbox (
  recipient_id, channel, template_key, status, payload
) values
 ('b2410000-0000-0000-0000-000000000001','in_app','queue_test_a',
  'pending', '{"private_token":"DO_NOT_DISCLOSE","body":"PERSONAL"}'::jsonb),
 ('b2410000-0000-0000-0000-000000000001','email','queue_test_b',
  'failed', '{"recipient_email":"secret@example.invalid"}'::jsonb);

select has_function(
  'public','get_technical_messaging_queue_snapshot', array['text'],
  'messaging queue snapshot RPC exists'
);

select throws_ok(
  $$select public.get_technical_messaging_queue_snapshot('core.messaging')$$,
  'P0001','Authentication required',
  'unauthenticated call refused'
);

select ok(
  not has_function_privilege(
    'anon','public.get_technical_messaging_queue_snapshot(text)','EXECUTE'
  ),'anon cannot invoke queue RPC'
);

set local role authenticated;
select set_config(
  'request.jwt.claim.sub','b2410000-0000-0000-0000-000000000001',true
);

select is(
  (public.get_technical_messaging_queue_snapshot('core.messaging')->>'module_key'),
  'core.messaging','response is bound to Messaging module'
);

select is(
  (public.get_technical_messaging_queue_snapshot('core.messaging')->>'adapter_key'),
  'notification_outbox_status','response identifies the actual source adapter'
);

select ok(
  (public.get_technical_messaging_queue_snapshot('core.messaging')->>'pending')::bigint >= 1
  and (public.get_technical_messaging_queue_snapshot('core.messaging')->>'failed')::bigint >= 1,
  'status aggregation observes inserted local queue records'
);

select ok(
  (select s->>'total' from (
    select public.get_technical_messaging_queue_snapshot('core.messaging') s
  ) v)::bigint >= 2,
  'real observed row total is not a fabricated zero'
);

select ok(
  (
    select not exists (
      select 1 from jsonb_object_keys(
        public.get_technical_messaging_queue_snapshot('core.messaging')
      ) k
      where k not in (
        'module_key','adapter_key','observed_at','last_activity_at',
        'total','pending','processing','sent','failed','cancelled'
      )
    )
  ),
  'response has only aggregate status and freshness fields'
);

select ok(
  position('DO_NOT_DISCLOSE' in
    public.get_technical_messaging_queue_snapshot('core.messaging')::text) = 0
  and position('secret@example.invalid' in
    public.get_technical_messaging_queue_snapshot('core.messaging')::text) = 0,
  'payload/recipient values never appear in JSON result'
);

select throws_ok(
  $$select public.get_technical_messaging_queue_snapshot('core.catalog')$$,
  'P0001','Queue adapter not available for this module',
  'unregistered module cannot inspect messaging queue'
);

select ok(
  (public.get_technical_messaging_queue_snapshot('core.messaging')->>'observed_at') is not null,
  'snapshot explicitly has an observation time'
);

reset role;
delete from public.technical_access_level_permissions
where access_level_code='tech_support' and permission_code='module.jobs';

set local role authenticated;
select set_config(
  'request.jwt.claim.sub','b2410000-0000-0000-0000-000000000001',true
);
select throws_ok(
  $$select public.get_technical_messaging_queue_snapshot('core.messaging')$$,
  'P0001','Technical module jobs permission required',
  'view-only cannot read queue metrics without jobs capability'
);

select set_config(
  'request.jwt.claim.sub','b2410000-0000-0000-0000-000000000002',true
);
select throws_ok(
  $$select public.get_technical_messaging_queue_snapshot('core.messaging')$$,
  'P0001','Technical module jobs permission required',
  'other-module staff cannot read Messaging queue'
);

select * from finish();
rollback;
