begin;

create extension if not exists pgtap with schema extensions;
select plan(22);

insert into auth.users (
  id, aud, role, email, raw_user_meta_data, created_at, updated_at
) values
  ('a1000000-0000-0000-0000-000000000001', 'authenticated', 'authenticated', 'commerce-client@wantok.local', '{"full_name":"Commerce Client"}'::jsonb, now(), now()),
  ('a2000000-0000-0000-0000-000000000002', 'authenticated', 'authenticated', 'commerce-vendor@wantok.local', '{"full_name":"Commerce Vendor"}'::jsonb, now(), now()),
  ('a3000000-0000-0000-0000-000000000003', 'authenticated', 'authenticated', 'commerce-outsider@wantok.local', '{"full_name":"Commerce Outsider"}'::jsonb, now(), now());

update public.profiles
set is_provider = true
where id = 'a2000000-0000-0000-0000-000000000002'::uuid;

insert into public.provider_profiles (
  provider_id, provider_type, display_name, verification_status, is_active
) values (
  'a2000000-0000-0000-0000-000000000002',
  'business',
  'Wantok Test Kitchen',
  'verified',
  true
)
on conflict (provider_id) do update
set verification_status = excluded.verification_status,
    is_active = excluded.is_active,
    display_name = excluded.display_name;

insert into public.provider_services (
  id, provider_id, category_id, title, description, pricing_model,
  currency, status
)
select
  'a2100000-0000-0000-0000-000000000010'::uuid,
  'a2000000-0000-0000-0000-000000000002'::uuid,
  id,
  'Wantok Test Kitchen',
  'Test food storefront',
  'fixed',
  'PGK',
  'active'
from public.service_categories
where slug = 'food';

insert into public.commerce_catalog_items (
  id, provider_service_id, provider_id, name, unit_label, price, currency,
  is_available, sort_order
) values
  (
    'a2200000-0000-0000-0000-000000000011',
    'a2100000-0000-0000-0000-000000000010',
    'a2000000-0000-0000-0000-000000000002',
    'Chicken Meal',
    'plate',
    10.00,
    'PGK',
    true,
    10
  ),
  (
    'a2200000-0000-0000-0000-000000000012',
    'a2100000-0000-0000-0000-000000000010',
    'a2000000-0000-0000-0000-000000000002',
    'Fresh Juice',
    'cup',
    5.00,
    'PGK',
    true,
    20
  );

select ok(
  public.has_role(
    'provider',
    'a2000000-0000-0000-0000-000000000002'::uuid
  ),
  'commerce vendor has provider role'
);

set local role authenticated;
select set_config(
  'request.jwt.claim.sub',
  'a1000000-0000-0000-0000-000000000001',
  true
);

select is(
  (
    select count(*)::integer
    from public.commerce_catalog_items
    where provider_service_id = 'a2100000-0000-0000-0000-000000000010'
  ),
  2,
  'customer can read available catalogue items'
);

select lives_ok(
  $$select public.create_commerce_order(
    'a2100000-0000-0000-0000-000000000010',
    '[
      {"item_id":"a2200000-0000-0000-0000-000000000011","quantity":2},
      {"item_id":"a2200000-0000-0000-0000-000000000012","quantity":1}
    ]'::jsonb,
    'delivery',
    'Eriku, Lae',
    null,
    null,
    'Please call on arrival',
    'cash'
  )$$,
  'customer can place a food order'
);

select set_config(
  'wantok.commerce_order_id',
  (
    select id::text
    from public.commerce_orders
    where customer_id = auth.uid()
    order by created_at desc
    limit 1
  ),
  true
);

select is(
  (
    select status
    from public.commerce_orders
    where id = current_setting('wantok.commerce_order_id')::uuid
  ),
  'placed',
  'new commerce order starts placed'
);

select is(
  (
    select subtotal
    from public.commerce_orders
    where id = current_setting('wantok.commerce_order_id')::uuid
  ),
  25.00::numeric,
  'server calculates order subtotal'
);

select is(
  (
    select total_amount
    from public.commerce_orders
    where id = current_setting('wantok.commerce_order_id')::uuid
  ),
  25.00::numeric,
  'server calculates total amount'
);

select is(
  (
    select count(*)::integer
    from public.commerce_order_items
    where order_id = current_setting('wantok.commerce_order_id')::uuid
  ),
  2,
  'server snapshots two order items'
);

select is(
  (
    select item_name
    from public.commerce_order_items
    where order_id = current_setting('wantok.commerce_order_id')::uuid
      and catalog_item_id = 'a2200000-0000-0000-0000-000000000011'
  ),
  'Chicken Meal',
  'order item stores catalogue name snapshot'
);

select throws_ok(
  $$insert into public.commerce_orders (
    customer_id, provider_id, provider_service_id, category_id,
    fulfillment_type, delivery_address, subtotal, total_amount
  )
  select
    auth.uid(),
    'a2000000-0000-0000-0000-000000000002',
    'a2100000-0000-0000-0000-000000000010',
    id,
    'delivery',
    'Invalid direct insert',
    1,
    1
  from public.service_categories where slug = 'food'$$,
  '42501',
  null,
  'customer cannot insert commerce order directly'
);

select throws_ok(
  $$select public.vendor_update_commerce_order_status(
    current_setting('wantok.commerce_order_id')::uuid,
    'accepted'
  )$$,
  'P0001',
  'Commerce order not found',
  'customer cannot run vendor order transition'
);

select set_config(
  'request.jwt.claim.sub',
  'a3000000-0000-0000-0000-000000000003',
  true
);

select is(
  (
    select count(*)::integer
    from public.commerce_orders
    where id = current_setting('wantok.commerce_order_id')::uuid
  ),
  0,
  'outsider cannot read another customer order'
);

select set_config(
  'request.jwt.claim.sub',
  'a2000000-0000-0000-0000-000000000002',
  true
);

select is(
  (
    select count(*)::integer
    from public.commerce_orders
    where id = current_setting('wantok.commerce_order_id')::uuid
  ),
  1,
  'vendor can read own store order'
);

select lives_ok(
  $$select public.vendor_update_commerce_order_status(
    current_setting('wantok.commerce_order_id')::uuid,
    'accepted'
  )$$,
  'vendor can accept order'
);

select is(
  (
    select status from public.commerce_orders
    where id = current_setting('wantok.commerce_order_id')::uuid
  ),
  'accepted',
  'accepted status is stored'
);

select lives_ok(
  $$select public.vendor_update_commerce_order_status(
    current_setting('wantok.commerce_order_id')::uuid,
    'preparing'
  )$$,
  'vendor can start preparation'
);

select lives_ok(
  $$select public.vendor_update_commerce_order_status(
    current_setting('wantok.commerce_order_id')::uuid,
    'ready'
  )$$,
  'vendor can mark order ready'
);

select lives_ok(
  $$select public.vendor_update_commerce_order_status(
    current_setting('wantok.commerce_order_id')::uuid,
    'out_for_delivery'
  )$$,
  'delivery order can move out for delivery'
);

select lives_ok(
  $$select public.vendor_update_commerce_order_status(
    current_setting('wantok.commerce_order_id')::uuid,
    'completed'
  )$$,
  'vendor can complete delivered order'
);

select is(
  (
    select status from public.commerce_orders
    where id = current_setting('wantok.commerce_order_id')::uuid
  ),
  'completed',
  'commerce order completes through valid lifecycle'
);

select set_config(
  'request.jwt.claim.sub',
  'a1000000-0000-0000-0000-000000000001',
  true
);

select lives_ok(
  $$select public.create_commerce_order(
    'a2100000-0000-0000-0000-000000000010',
    '[{"item_id":"a2200000-0000-0000-0000-000000000012","quantity":2}]'::jsonb,
    'pickup',
    null,
    null,
    null,
    null,
    'cash'
  )$$,
  'customer can place a pickup order'
);

select set_config(
  'wantok.cancel_order_id',
  (
    select id::text
    from public.commerce_orders
    where customer_id = auth.uid()
      and status = 'placed'
    order by created_at desc
    limit 1
  ),
  true
);

select lives_ok(
  $$select public.cancel_commerce_order(
    current_setting('wantok.cancel_order_id')::uuid,
    'Changed my mind'
  )$$,
  'customer can cancel newly placed order'
);

select is(
  (
    select status from public.commerce_orders
    where id = current_setting('wantok.cancel_order_id')::uuid
  ),
  'cancelled',
  'customer cancellation is stored'
);

reset role;
select * from finish();
rollback;
