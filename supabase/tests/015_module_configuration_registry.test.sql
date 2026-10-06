begin;

create extension if not exists pgtap with schema extensions;
select plan(42);

insert into auth.users (
  id, aud, role, email, raw_user_meta_data, created_at, updated_at
) values
  ('f1000000-0000-0000-0000-000000000001', 'authenticated', 'authenticated',
   't22-platform@wantok.local', '{"full_name":"T22 Platform Admin"}'::jsonb, now(), now()),
  ('f1000000-0000-0000-0000-000000000002', 'authenticated', 'authenticated',
   't22-module-admin@wantok.local', '{"full_name":"T22 Module Admin"}'::jsonb, now(), now()),
  ('f1000000-0000-0000-0000-000000000003', 'authenticated', 'authenticated',
   't22-auditor@wantok.local', '{"full_name":"T22 Auditor"}'::jsonb, now(), now()),
  ('f1000000-0000-0000-0000-000000000004', 'authenticated', 'authenticated',
   't22-support@wantok.local', '{"full_name":"T22 Support"}'::jsonb, now(), now()),
  ('f1000000-0000-0000-0000-000000000005', 'authenticated', 'authenticated',
   't22-operations@wantok.local', '{"full_name":"T22 Operations"}'::jsonb, now(), now()),
  ('f1000000-0000-0000-0000-000000000006', 'authenticated', 'authenticated',
   't22-user@wantok.local', '{"full_name":"T22 Ordinary User"}'::jsonb, now(), now());

update public.profiles
set is_admin = true
where id = 'f1000000-0000-0000-0000-000000000005'::uuid;

-- Keep this rollback-only test deterministic even when a developer already
-- has local Technical Platform Administrator access.
delete from public.user_roles
where role_code = 'tech_platform_admin';

insert into public.user_roles (
  user_id, role_code, granted_by
) values (
  'f1000000-0000-0000-0000-000000000001',
  'tech_platform_admin',
  null
);

select has_table(
  'public',
  'technical_module_config_schema_versions',
  'versioned technical configuration schema registry exists'
);

select has_table(
  'public',
  'technical_module_config_fields',
  'typed technical configuration field registry exists'
);

select has_table(
  'public',
  'technical_module_config_values',
  'technical configuration value store exists'
);

select is(
  (
    select count(*)::integer
    from public.technical_module_config_schema_versions
    where status = 'active'
  ),
  7,
  'seven initial modules have active configuration schemas'
);

select is(
  (
    select count(*)::integer
    from public.technical_module_config_fields
  ),
  20,
  'initial schemas contain twenty typed configuration fields'
);

select ok(
  public.validate_technical_config_value(
    'url',
    '"https://wantokservices.com/path"'::jsonb,
    '{}'::jsonb,
    true
  ),
  'URL validator accepts https URLs'
);

select ok(
  not public.validate_technical_config_value(
    'secret_reference',
    '"actual-secret-value"'::jsonb,
    '{}'::jsonb,
    false
  ),
  'secret-reference validator rejects raw secret-like values'
);

set local role authenticated;
select set_config(
  'request.jwt.claim.sub',
  'f1000000-0000-0000-0000-000000000001',
  true
);

select is(
  (
    select count(*)::integer
    from public.list_technical_module_configuration('mobility.taxi')
  ),
  4,
  'platform administrator can read four Taxi configuration fields'
);

select is(
  (
    select effective_value #>> '{}'
    from public.list_technical_module_configuration('mobility.taxi')
    where field_key = 'dispatch.radius_km'
  ),
  '8',
  'Taxi radius resolves to its schema default before override'
);

select ok(
  (
    select can_configure
    from public.list_technical_module_configuration('mobility.taxi')
    limit 1
  ),
  'platform administrator receives configure capability'
);

select lives_ok(
  $$select public.grant_technical_module_access(
    'f1000000-0000-0000-0000-000000000002'::uuid,
    'mobility.taxi',
    'tech_module_admin',
    null,
    'T2.2 Taxi module administrator'
  )$$,
  'platform administrator assigns a Taxi Module Administrator'
);

select lives_ok(
  $$select public.grant_technical_module_access(
    'f1000000-0000-0000-0000-000000000003'::uuid,
    'mobility.taxi',
    'tech_auditor',
    null,
    'T2.2 Taxi auditor'
  )$$,
  'platform administrator assigns a Taxi Technical Auditor'
);

select lives_ok(
  $$select public.grant_technical_module_access(
    'f1000000-0000-0000-0000-000000000004'::uuid,
    'mobility.taxi',
    'tech_support',
    null,
    'T2.2 Taxi support'
  )$$,
  'platform administrator assigns Taxi Technical Support'
);

select lives_ok(
  $$select public.update_technical_module_configuration(
    'mobility.taxi',
    1,
    '{"dispatch.radius_km":12.5}'::jsonb
  )$$,
  'platform administrator can update typed Taxi configuration'
);

select is(
  (
    select effective_value #>> '{}'
    from public.list_technical_module_configuration('mobility.taxi')
    where field_key = 'dispatch.radius_km'
  ),
  '12.5',
  'updated Taxi radius is returned as the effective value'
);

select ok(
  (
    select is_overridden
    from public.list_technical_module_configuration('mobility.taxi')
    where field_key = 'dispatch.radius_km'
  ),
  'updated Taxi radius is marked as overridden'
);

select ok(
  exists (
    select 1
    from public.audit_events
    where action = 'technical_module_configuration_changed'
      and metadata ->> 'module_key' = 'mobility.taxi'
      and metadata -> 'changed_fields' ? 'dispatch.radius_km'
  ),
  'configuration changes produce technical audit events'
);

select throws_ok(
  $$select public.update_technical_module_configuration(
    'mobility.taxi',
    1,
    '{"dispatch.radius_km":100}'::jsonb
  )$$,
  'P0001',
  'Invalid value for configuration field: dispatch.radius_km',
  'numeric max validation rejects an excessive Taxi radius'
);

select throws_ok(
  $$select public.update_technical_module_configuration(
    'mobility.taxi',
    1,
    '{"dispatch.radius_km":"twelve"}'::jsonb
  )$$,
  'P0001',
  'Invalid value for configuration field: dispatch.radius_km',
  'typed decimal field rejects a string'
);

select throws_ok(
  $$select public.update_technical_module_configuration(
    'mobility.taxi',
    1,
    '{"dispatch.max_offer_drivers":3.5}'::jsonb
  )$$,
  'P0001',
  'Invalid value for configuration field: dispatch.max_offer_drivers',
  'integer field rejects a fractional number'
);

select throws_ok(
  $$select public.update_technical_module_configuration(
    'mobility.taxi',
    1,
    '{"dispatch.offer_timeout_seconds":-1}'::jsonb
  )$$,
  'P0001',
  'Invalid value for configuration field: dispatch.offer_timeout_seconds',
  'duration field rejects a negative duration'
);

select lives_ok(
  $$select public.update_technical_module_configuration(
    'notifications',
    1,
    '{"delivery.default_channel":"push"}'::jsonb
  )$$,
  'enum field accepts an allowed value'
);

select throws_ok(
  $$select public.update_technical_module_configuration(
    'notifications',
    1,
    '{"delivery.default_channel":"sms"}'::jsonb
  )$$,
  'P0001',
  'Invalid value for configuration field: delivery.default_channel',
  'enum field rejects a value outside its allowed list'
);

select lives_ok(
  $$select public.update_technical_module_configuration(
    'core.messaging',
    1,
    '{"moderation.blocked_terms":["spam","scam"]}'::jsonb
  )$$,
  'string-list field accepts an array of strings'
);

select throws_ok(
  $$select public.update_technical_module_configuration(
    'core.messaging',
    1,
    '{"moderation.blocked_terms":["spam",42]}'::jsonb
  )$$,
  'P0001',
  'Invalid value for configuration field: moderation.blocked_terms',
  'string-list field rejects non-string items'
);

select throws_ok(
  $$select public.update_technical_module_configuration(
    'mobility.taxi',
    1,
    '{"integrations.maps_secret_ref":"my-real-secret"}'::jsonb
  )$$,
  'P0001',
  'Invalid value for configuration field: integrations.maps_secret_ref',
  'secret-reference field rejects raw secret text'
);

select lives_ok(
  $$select public.update_technical_module_configuration(
    'mobility.taxi',
    1,
    '{"integrations.maps_secret_ref":"env://MAPS_API_KEY"}'::jsonb
  )$$,
  'secret-reference field accepts a safe environment reference'
);

select is(
  (
    select effective_value #>> '{}'
    from public.list_technical_module_configuration('mobility.taxi')
    where field_key = 'integrations.maps_secret_ref'
  ),
  'env://MAPS_API_KEY',
  'configuration API returns the reference identifier but never a secret value'
);

select ok(
  not exists (
    select 1
    from public.audit_events
    where action = 'technical_module_configuration_changed'
      and metadata::text like '%MAPS_API_KEY%'
  ),
  'configuration audit metadata redacts secret reference identifiers'
);

select lives_ok(
  $$select public.update_technical_module_configuration(
    'mobility.taxi',
    1,
    '{"integrations.maps_secret_ref":null}'::jsonb
  )$$,
  'optional secret reference can be reset'
);

select ok(
  not (
    select is_overridden
    from public.list_technical_module_configuration('mobility.taxi')
    where field_key = 'integrations.maps_secret_ref'
  ),
  'reset secret reference no longer has an override'
);

select lives_ok(
  $$select public.update_technical_module_configuration(
    'mobility.taxi',
    1,
    '{"dispatch.radius_km":null}'::jsonb
  )$$,
  'required field with a schema default can be reset to default'
);

select is(
  (
    select effective_value #>> '{}'
    from public.list_technical_module_configuration('mobility.taxi')
    where field_key = 'dispatch.radius_km'
  ),
  '8',
  'reset required field falls back to the schema default'
);

select throws_ok(
  $$select public.update_technical_module_configuration(
    'mobility.taxi',
    1,
    '{"unknown.setting":true}'::jsonb
  )$$,
  'P0001',
  'Unknown configuration field: unknown.setting',
  'unknown configuration fields are rejected'
);

select throws_ok(
  $$select public.update_technical_module_configuration(
    'mobility.taxi',
    99,
    '{"dispatch.radius_km":8}'::jsonb
  )$$,
  'P0001',
  'Active module configuration schema version mismatch',
  'stale or unknown schema versions are rejected'
);

select throws_ok(
  $$select public.update_technical_module_configuration(
    'mobility.taxi',
    1,
    '[]'::jsonb
  )$$,
  'P0001',
  'Configuration update must be a JSON object',
  'configuration update payload must be an object'
);

select is(
  (
    select count(*)::integer
    from public.list_technical_module_configuration('events')
  ),
  0,
  'module without an active schema returns an empty configuration list'
);

select set_config(
  'request.jwt.claim.sub',
  'f1000000-0000-0000-0000-000000000003',
  true
);

select ok(
  not (
    select can_configure
    from public.list_technical_module_configuration('mobility.taxi')
    limit 1
  ),
  'Technical Auditor receives read-only configuration'
);

select throws_ok(
  $$select public.update_technical_module_configuration(
    'mobility.taxi',
    1,
    '{"dispatch.radius_km":9}'::jsonb
  )$$,
  'P0001',
  'Technical module configuration permission required',
  'Technical Auditor cannot change configuration'
);

select set_config(
  'request.jwt.claim.sub',
  'f1000000-0000-0000-0000-000000000005',
  true
);

select throws_ok(
  $$select * from public.list_technical_module_configuration('mobility.taxi')$$,
  'P0001',
  'Technical module view permission required',
  'Operations Administrator cannot read Technical module configuration'
);

select set_config(
  'request.jwt.claim.sub',
  'f1000000-0000-0000-0000-000000000006',
  true
);

select throws_ok(
  $$select * from public.list_technical_module_configuration('mobility.taxi')$$,
  'P0001',
  'Technical module view permission required',
  'ordinary user cannot read Technical module configuration'
);

select throws_ok(
  $$insert into public.technical_module_config_values (
    module_key, schema_version, field_key, value, updated_by
  ) values (
    'mobility.taxi', 1, 'dispatch.radius_km', '9'::jsonb,
    'f1000000-0000-0000-0000-000000000006'::uuid
  )$$,
  '42501',
  null,
  'authenticated users cannot directly write configuration tables'
);

select * from finish();
rollback;
