begin;
create extension if not exists pgtap with schema extensions;
select plan(9);

select ok(
  (select is_active from public.service_categories where slug='public-services'),
  'public services installed as enabled catalogue-only module'
);

select throws_ok(
  $$select public.admin_set_public_services_enabled(false)$$,
  'P0001', 'Admin access required',
  'anonymous callers cannot change module visibility'
);

insert into auth.users(id, aud, role, email, raw_user_meta_data, created_at, updated_at)
values (
  '90000000-0000-0000-0000-000000000009',
  'authenticated', 'authenticated',
  'public-module-admin@wantok.local',
  '{"full_name":"Module RBAC Test Admin"}'::jsonb, now(), now()
);
update public.profiles set is_admin=true
where id='90000000-0000-0000-0000-000000000009'::uuid;

set local role authenticated;
select set_config('request.jwt.claim.sub',
  '90000000-0000-0000-0000-000000000009', true);

select is(public.admin_set_public_services_enabled(false), false,
  'authenticated RBAC admin can disable public module');
select ok(not (select is_active from public.service_categories where slug='public-services'),
  'disabled module persisted in catalogue');
select is(
  (select count(*)::integer from public.audit_events
   where action='public_services_visibility_changed'
     and actor_user_id='90000000-0000-0000-0000-000000000009'::uuid),
  1, 'disable operation audited'
);
select is(public.admin_set_public_services_enabled(false), false,
  'idempotent disable succeeds');
select is(public.admin_set_public_services_enabled(true), true,
  'authenticated admin can restore public module');
select ok((select is_active from public.service_categories where slug='public-services'),
  'enabled module persisted in catalogue');
select is(
  (select count(*)::integer from public.audit_events
   where action='public_services_visibility_changed'
     and actor_user_id='90000000-0000-0000-0000-000000000009'::uuid),
  2, 'only real state transitions produce audit records'
);

select * from finish();
rollback;
