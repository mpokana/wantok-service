begin;

create extension if not exists pgtap with schema extensions;
select plan(16);

insert into auth.users (
  id, aud, role, email, raw_user_meta_data, created_at, updated_at
) values
  ('91000000-0000-0000-0000-000000000001', 'authenticated', 'authenticated',
   'message-customer@wantok.local', '{"full_name":"Message Customer"}'::jsonb, now(), now()),
  ('91000000-0000-0000-0000-000000000002', 'authenticated', 'authenticated',
   'message-provider@wantok.local', '{"full_name":"Message Provider"}'::jsonb, now(), now()),
  ('91000000-0000-0000-0000-000000000003', 'authenticated', 'authenticated',
   'message-outsider@wantok.local', '{"full_name":"Message Outsider"}'::jsonb, now(), now());

update public.profiles
set is_provider = true
where id = '91000000-0000-0000-0000-000000000002'::uuid;

insert into public.provider_profiles (
  provider_id, display_name, provider_type, verification_status, is_active
) values (
  '91000000-0000-0000-0000-000000000002',
  'Trusted Message Provider',
  'individual',
  'verified',
  true
);

insert into public.service_bookings (
  id,
  customer_id,
  category_id,
  provider_id,
  status,
  service_address,
  notes
)
select
  '92000000-0000-0000-0000-000000000001'::uuid,
  '91000000-0000-0000-0000-000000000001'::uuid,
  category.id,
  '91000000-0000-0000-0000-000000000002'::uuid,
  'confirmed',
  'Lae',
  'Messaging workflow test'
from public.service_categories category
where category.slug = 'specialist-services';

set local role authenticated;
select set_config(
  'request.jwt.claim.sub',
  '91000000-0000-0000-0000-000000000001',
  true
);

select lives_ok(
  $$select public.ensure_booking_conversation(
    '92000000-0000-0000-0000-000000000001'::uuid
  )$$,
  'booking customer can open conversation for assigned provider'
);

select set_config(
  'wantok.message_thread_id',
  (
    select id::text
    from public.conversation_threads
    where booking_id = '92000000-0000-0000-0000-000000000001'::uuid
  ),
  true
);

select is(
  (
    select count(*)::integer
    from public.conversation_threads
    where booking_id = '92000000-0000-0000-0000-000000000001'::uuid
  ),
  1,
  'one booking conversation is created'
);

select lives_ok(
  $$select public.ensure_booking_conversation(
    '92000000-0000-0000-0000-000000000001'::uuid
  )$$,
  'ensuring a conversation is idempotent'
);

select is(
  (
    select count(*)::integer
    from public.conversation_threads
    where booking_id = '92000000-0000-0000-0000-000000000001'::uuid
  ),
  1,
  'repeated ensure does not duplicate the conversation'
);

select lives_ok(
  $$select public.send_conversation_message(
    current_setting('wantok.message_thread_id')::uuid,
    'Hello provider'
  )$$,
  'customer can send a message'
);

select is(
  (
    select body
    from public.conversation_messages
    where thread_id = current_setting('wantok.message_thread_id')::uuid
    order by created_at
    limit 1
  ),
  'Hello provider',
  'customer message is stored'
);

select throws_ok(
  $$select public.send_conversation_message(
    current_setting('wantok.message_thread_id')::uuid,
    '   '
  )$$,
  'P0001',
  'Message cannot be empty',
  'blank messages are rejected'
);

select set_config(
  'request.jwt.claim.sub',
  '91000000-0000-0000-0000-000000000003',
  true
);

select throws_ok(
  $$select public.ensure_booking_conversation(
    '92000000-0000-0000-0000-000000000001'::uuid
  )$$,
  'P0001',
  'You are not a participant in this booking',
  'outsider cannot open another users booking conversation'
);

select is(
  (
    select count(*)::integer
    from public.conversation_threads
    where id = current_setting('wantok.message_thread_id')::uuid
  ),
  0,
  'thread RLS hides conversation from outsider'
);

select is(
  (
    select count(*)::integer
    from public.conversation_messages
    where thread_id = current_setting('wantok.message_thread_id')::uuid
  ),
  0,
  'message RLS hides conversation content from outsider'
);

select set_config(
  'request.jwt.claim.sub',
  '91000000-0000-0000-0000-000000000002',
  true
);

select is(
  (
    select count(*)::integer
    from public.conversation_threads
    where id = current_setting('wantok.message_thread_id')::uuid
  ),
  1,
  'assigned provider can read the thread'
);

select lives_ok(
  $$select public.send_conversation_message(
    current_setting('wantok.message_thread_id')::uuid,
    'Hello customer'
  )$$,
  'assigned provider can reply'
);

select set_config(
  'request.jwt.claim.sub',
  '91000000-0000-0000-0000-000000000001',
  true
);

select is(
  (
    select unread_count::bigint
    from public.list_my_booking_conversations()
    where thread_id = current_setting('wantok.message_thread_id')::uuid
  ),
  1::bigint,
  'provider reply is unread for customer'
);

select lives_ok(
  $$select public.mark_conversation_read(
    current_setting('wantok.message_thread_id')::uuid
  )$$,
  'customer can mark provider messages read'
);

select is(
  (
    select unread_count::bigint
    from public.list_my_booking_conversations()
    where thread_id = current_setting('wantok.message_thread_id')::uuid
  ),
  0::bigint,
  'mark read clears unread count'
);

select throws_ok(
  $$insert into public.conversation_messages (
      thread_id, sender_id, body
    ) values (
      current_setting('wantok.message_thread_id')::uuid,
      '91000000-0000-0000-0000-000000000001'::uuid,
      'bypass'
    )$$,
  '42501',
  null,
  'authenticated clients cannot bypass messaging RPC with direct inserts'
);

reset role;
select * from finish();
rollback;
