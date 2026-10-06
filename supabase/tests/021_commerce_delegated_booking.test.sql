begin;

create extension if not exists pgtap with schema extensions;
select plan(24);

select has_column('public','commerce_orders','trusted_person_id','commerce orders include trusted-person source id');
select has_column('public','commerce_orders','beneficiary_name','commerce orders include beneficiary name');
select has_column('public','commerce_orders','beneficiary_relationship','commerce orders include beneficiary relationship');
select has_column('public','commerce_orders','beneficiary_phone','commerce orders include beneficiary phone');
select has_column('public','commerce_orders','beneficiary_email','commerce orders include beneficiary email');

insert into auth.users (
  id,aud,role,email,raw_user_meta_data,created_at,updated_at
) values
  ('f2100000-0000-0000-0000-000000000001','authenticated','authenticated','commerce-delegated-owner@wantok.local','{"full_name":"Commerce Booking Owner"}',now(),now()),
  ('f2100000-0000-0000-0000-000000000002','authenticated','authenticated','commerce-delegated-vendor@wantok.local','{"full_name":"Commerce Delegated Vendor"}',now(),now()),
  ('f2100000-0000-0000-0000-000000000003','authenticated','authenticated','commerce-delegated-other@wantok.local','{"full_name":"Other Commerce Account"}',now(),now());

update public.profiles
set is_provider=true
where id='f2100000-0000-0000-0000-000000000002'::uuid;

insert into public.provider_profiles(
  provider_id,provider_type,display_name,verification_status,is_active
) values (
  'f2100000-0000-0000-0000-000000000002','business',
  'Delegated Wantok Store','verified',true
);

insert into public.provider_services(
  id,provider_id,category_id,title,pricing_model,currency,status
)
select
  'f2100000-0000-0000-0000-000000000010'::uuid,
  'f2100000-0000-0000-0000-000000000002'::uuid,
  id,'Delegated Wantok Store','fixed','PGK','active'
from public.service_categories where slug='food';

insert into public.commerce_catalog_items(
  id,provider_service_id,provider_id,name,unit_label,price,currency,is_available
) values (
  'f2100000-0000-0000-0000-000000000011',
  'f2100000-0000-0000-0000-000000000010',
  'f2100000-0000-0000-0000-000000000002',
  'Delegated Lunch','plate',18,'PGK',true
);

insert into public.trusted_people(
  id,owner_id,display_name,relationship,phone,email,is_active
) values
  ('f2100000-0000-0000-0000-000000000021','f2100000-0000-0000-0000-000000000001','Aunty Order Recipient','Aunty','+67570002121','aunty.order@example.invalid',true),
  ('f2100000-0000-0000-0000-000000000022','f2100000-0000-0000-0000-000000000001','Inactive Order Recipient','Relative','+67570002122',null,false),
  ('f2100000-0000-0000-0000-000000000023','f2100000-0000-0000-0000-000000000003','Other Order Recipient','Sibling','+67570002123',null,true);

set local role authenticated;
select set_config('request.jwt.claim.sub','f2100000-0000-0000-0000-000000000001',true);

select lives_ok(
  $$select public.create_commerce_order(
    'f2100000-0000-0000-0000-000000000010',
    '[{"item_id":"f2100000-0000-0000-0000-000000000011","quantity":2}]'::jsonb,
    'delivery','Eriku, Lae',null,null,'Deliver to my aunty','cash',
    'f2100000-0000-0000-0000-000000000021'::uuid
  )$$,
  'customer can place delegated commerce order for own active trusted person'
);

select set_config(
  'wantok.delegated_commerce_order_id',
  (
    select id::text from public.commerce_orders
    where customer_id=auth.uid()
    order by created_at desc limit 1
  ),
  true
);

select is(
  (select customer_id from public.commerce_orders where id=current_setting('wantok.delegated_commerce_order_id')::uuid),
  'f2100000-0000-0000-0000-000000000001'::uuid,
  'delegated commerce order remains owned by booking account'
);

select is(
  (select trusted_person_id from public.commerce_orders where id=current_setting('wantok.delegated_commerce_order_id')::uuid),
  'f2100000-0000-0000-0000-000000000021'::uuid,
  'commerce order stores trusted-person source id'
);

select is(
  (select beneficiary_name from public.commerce_orders where id=current_setting('wantok.delegated_commerce_order_id')::uuid),
  'Aunty Order Recipient',
  'commerce order snapshots recipient name'
);

select is(
  (select beneficiary_relationship from public.commerce_orders where id=current_setting('wantok.delegated_commerce_order_id')::uuid),
  'Aunty',
  'commerce order snapshots recipient relationship'
);

select is(
  (select beneficiary_phone from public.commerce_orders where id=current_setting('wantok.delegated_commerce_order_id')::uuid),
  '+67570002121',
  'commerce order snapshots recipient phone'
);

select is(
  (select beneficiary_email from public.commerce_orders where id=current_setting('wantok.delegated_commerce_order_id')::uuid),
  'aunty.order@example.invalid',
  'commerce order snapshots recipient email'
);

select is(
  (select metadata->>'booked_for' from public.commerce_orders where id=current_setting('wantok.delegated_commerce_order_id')::uuid),
  'trusted_person',
  'commerce metadata records trusted-person beneficiary'
);

select set_config('request.jwt.claim.sub','f2100000-0000-0000-0000-000000000002',true);

select is(
  (select beneficiary_name from public.commerce_orders where id=current_setting('wantok.delegated_commerce_order_id')::uuid),
  'Aunty Order Recipient',
  'vendor can read delegated order recipient'
);

select set_config('request.jwt.claim.sub','f2100000-0000-0000-0000-000000000001',true);

select throws_ok(
  $$select public.create_commerce_order(
    'f2100000-0000-0000-0000-000000000010',
    '[{"item_id":"f2100000-0000-0000-0000-000000000011","quantity":1}]'::jsonb,
    'pickup',null,null,null,null,'cash',
    'f2100000-0000-0000-0000-000000000023'::uuid
  )$$,
  'P0001','Trusted person is not available',
  'commerce order cannot use another account trusted person'
);

select throws_ok(
  $$select public.create_commerce_order(
    'f2100000-0000-0000-0000-000000000010',
    '[{"item_id":"f2100000-0000-0000-0000-000000000011","quantity":1}]'::jsonb,
    'pickup',null,null,null,null,'cash',
    'f2100000-0000-0000-0000-000000000022'::uuid
  )$$,
  'P0001','Trusted person is not available',
  'commerce order cannot use inactive trusted person'
);

update public.trusted_people
set display_name='Aunty Order Recipient Updated',
    relationship='Relative',
    phone='+67579992121'
where id='f2100000-0000-0000-0000-000000000021'::uuid;

select is(
  (select beneficiary_name from public.commerce_orders where id=current_setting('wantok.delegated_commerce_order_id')::uuid),
  'Aunty Order Recipient',
  'commerce beneficiary snapshot is unchanged after trusted-person edit'
);

delete from public.trusted_people
where id='f2100000-0000-0000-0000-000000000021'::uuid;

select is(
  (select trusted_person_id from public.commerce_orders where id=current_setting('wantok.delegated_commerce_order_id')::uuid),
  null::uuid,
  'deleting trusted person clears commerce source foreign key'
);

select is(
  (select beneficiary_name from public.commerce_orders where id=current_setting('wantok.delegated_commerce_order_id')::uuid),
  'Aunty Order Recipient',
  'historical commerce beneficiary snapshot survives source deletion'
);

select lives_ok(
  $$select public.cancel_commerce_order(
    current_setting('wantok.delegated_commerce_order_id')::uuid,
    'Finish delegated commerce test'
  )$$,
  'booking account retains cancellation authority'
);

select lives_ok(
  $$select public.create_commerce_order(
    'f2100000-0000-0000-0000-000000000010',
    '[{"item_id":"f2100000-0000-0000-0000-000000000011","quantity":1}]'::jsonb,
    'pickup',null,null,null,'Self pickup','cash',null
  )$$,
  'customer can still place order for themselves'
);

select set_config(
  'wantok.self_commerce_order_id',
  (
    select id::text from public.commerce_orders
    where customer_id=auth.uid() and status='placed'
    order by created_at desc limit 1
  ),
  true
);

select is(
  (select trusted_person_id from public.commerce_orders where id=current_setting('wantok.self_commerce_order_id')::uuid),
  null::uuid,
  'self commerce order has no trusted-person source'
);

select is(
  (select beneficiary_name from public.commerce_orders where id=current_setting('wantok.self_commerce_order_id')::uuid),
  null::text,
  'self commerce order has no beneficiary snapshot'
);

select is(
  (select metadata->>'booked_for' from public.commerce_orders where id=current_setting('wantok.self_commerce_order_id')::uuid),
  'self',
  'self commerce metadata records self beneficiary'
);

reset role;
select * from finish();
rollback;
