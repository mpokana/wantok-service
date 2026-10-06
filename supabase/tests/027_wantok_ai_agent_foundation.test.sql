begin;

create extension if not exists pgtap with schema extensions;
select plan(15);

insert into auth.users (
  id, aud, role, email, raw_user_meta_data, created_at, updated_at
) values
  ('f2700000-0000-0000-0000-000000000001', 'authenticated', 'authenticated',
   'ai-owner@wantok.local', '{"full_name":"AI Owner"}'::jsonb, now(), now()),
  ('f2700000-0000-0000-0000-000000000002', 'authenticated', 'authenticated',
   'ai-other@wantok.local', '{"full_name":"AI Other"}'::jsonb, now(), now()),
  ('f2700000-0000-0000-0000-000000000003', 'authenticated', 'authenticated',
   'ai-support@wantok.local', '{"full_name":"AI Support"}'::jsonb, now(), now());

insert into public.user_roles (user_id, role_code, granted_by)
values (
  'f2700000-0000-0000-0000-000000000003',
  'support',
  null
);

select has_table(
  'public',
  'ai_agent_handoff_requests',
  'AI handoff queue exists'
);

select has_function(
  'public',
  'get_wantok_ai_agent_capabilities',
  array[]::text[],
  'AI capability RPC exists'
);

select has_function(
  'public',
  'request_wantok_ai_handoff',
  array['text', 'jsonb'],
  'AI handoff RPC exists'
);

select is(
  has_function_privilege(
    'anon',
    'public.get_wantok_ai_agent_capabilities()',
    'EXECUTE'
  ),
  false,
  'anonymous users cannot read AI capabilities'
);

select is(
  has_function_privilege(
    'anon',
    'public.request_wantok_ai_handoff(text,jsonb)',
    'EXECUTE'
  ),
  false,
  'anonymous users cannot create AI handoff requests'
);

set local role authenticated;
select set_config(
  'request.jwt.claim.sub',
  'f2700000-0000-0000-0000-000000000001',
  true
);

select is(
  (public.get_wantok_ai_agent_capabilities() ->> 'enabled')::boolean,
  false,
  'AI model chat is disabled by default'
);

select is(
  (public.get_wantok_ai_agent_capabilities() ->> 'chat_enabled')::boolean,
  false,
  'AI chat capability is disabled by default'
);

select is(
  (
    public.get_wantok_ai_agent_capabilities()
      ->> 'handoff_capture_enabled'
  )::boolean,
  true,
  'human help request capture is enabled'
);

select lives_ok(
  $$select public.request_wantok_ai_handoff(
    'I cannot find a plumber in Lae.',
    '{"source":"wantok_ai_agent","intent":"provider_search"}'::jsonb
  )$$,
  'signed-in user can request human help'
);

select is(
  (
    select count(*)::integer
    from public.ai_agent_handoff_requests
  ),
  1,
  'owner can read own AI handoff request'
);

select throws_ok(
  $$select public.request_wantok_ai_handoff(
    '   ',
    '{}'::jsonb
  )$$,
  'P0001',
  'Help request must contain 1 to 4000 characters',
  'blank handoff request is rejected'
);

select throws_ok(
  $$select public.request_wantok_ai_handoff(
    'Need help',
    '[]'::jsonb
  )$$,
  'P0001',
  'AI handoff context must be a JSON object',
  'non-object handoff context is rejected'
);

select set_config(
  'request.jwt.claim.sub',
  'f2700000-0000-0000-0000-000000000002',
  true
);

select is(
  (
    select count(*)::integer
    from public.ai_agent_handoff_requests
  ),
  0,
  'another user cannot read the owner handoff request'
);

select set_config(
  'request.jwt.claim.sub',
  'f2700000-0000-0000-0000-000000000003',
  true
);

select is(
  (
    select count(*)::integer
    from public.ai_agent_handoff_requests
    where status = 'open'
  ),
  1,
  'support staff can read open handoff requests'
);

update public.ai_agent_handoff_requests
set status = 'assigned',
    assigned_to = auth.uid()
where status = 'open';

select is(
  (
    select status
    from public.ai_agent_handoff_requests
    limit 1
  ),
  'assigned',
  'support staff can assign a handoff request'
);

select * from finish();
rollback;
