begin;

create extension if not exists pgtap with schema extensions;

select plan(24);

select has_table('public', 'profiles', 'profiles table exists');
select has_table('public', 'service_categories', 'service_categories table exists');
select has_table('public', 'provider_services', 'provider_services table exists');
select has_table('public', 'service_bookings', 'service_bookings table exists');
select has_table('public', 'service_quotes', 'service_quotes table exists');
select has_table('public', 'payment_intents', 'payment_intents table exists');
select has_table('public', 'audit_events', 'audit_events table exists');
select has_table('public', 'notifications', 'notifications table exists');
select has_table('public', 'provider_availability_rules', 'availability rules table exists');
select has_table('public', 'provider_time_off', 'provider time-off table exists');

select is(
  (select count(*)::integer from public.service_categories),
  23,
  'service catalogue includes 15 original, seven expanded and Public Services categories'
);

select is(
  (select count(*)::integer from public.service_categories where is_active),
  20,
  '12 original, seven expanded and Public Services categories are active'
);

select is(
  (select count(*)::integer from public.app_roles),
  13,
  'enterprise RBAC contains 13 system roles including technical administration'
);

select ok(
  (
    select bool_and(c.relrowsecurity)
    from pg_class c
    join pg_namespace n on n.oid = c.relnamespace
    where n.nspname = 'public'
      and c.relname = any(array[
        'profiles','provider_applications','driver_profiles','driver_locations','rides',
        'service_categories','provider_profiles','provider_services','provider_resources',
        'service_bookings','service_quotes','service_reviews','app_roles','user_roles',
        'audit_events','notifications','notification_outbox','payment_intents',
        'payment_events','provider_settlements','provider_settlement_items','user_devices',
        'provider_availability_rules','provider_time_off'
      ])
  ),
  'RLS is enabled on every application table'
);

select has_function('public', 'request_ride', 'ride request RPC exists');
select has_function('public', 'review_provider_application', 'provider review RPC exists');
select has_function('public', 'submit_service_quote', 'quote submission RPC exists');
select has_function('public', 'has_role', 'RBAC role check RPC exists');
select has_function('public', 'is_resource_available', 'resource availability RPC exists');

select ok(
  exists(
    select 1 from pg_constraint
    where conname = 'service_bookings_no_resource_overlap'
  ),
  'resource reservations have a database overlap exclusion constraint'
);

select ok(
  not has_table_privilege('authenticated', 'public.payment_intents', 'INSERT'),
  'authenticated clients cannot directly create payment intents'
);

select ok(
  not has_table_privilege('authenticated', 'public.payment_events', 'INSERT'),
  'authenticated clients cannot directly create payment processor events'
);

select ok(
  not has_table_privilege('authenticated', 'public.audit_events', 'INSERT'),
  'authenticated clients cannot directly write audit events'
);

select ok(
  not has_table_privilege('authenticated', 'public.notification_outbox', 'INSERT'),
  'authenticated clients cannot directly enqueue outbound notifications'
);

select * from finish();
rollback;
