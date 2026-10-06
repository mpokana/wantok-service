begin;

create extension if not exists pgtap with schema extensions;
select plan(14);

insert into auth.users (
  id, aud, role, email, raw_user_meta_data, created_at, updated_at
) values
  ('c2300000-0000-0000-0000-000000000001', 'authenticated', 'authenticated',
   'media-owner@wantok.local', '{"full_name":"Media Owner"}'::jsonb, now(), now()),
  ('c2300000-0000-0000-0000-000000000002', 'authenticated', 'authenticated',
   'media-other@wantok.local', '{"full_name":"Media Other"}'::jsonb, now(), now()),
  ('c2300000-0000-0000-0000-000000000003', 'authenticated', 'authenticated',
   'media-provider@wantok.local', '{"full_name":"Media Provider"}'::jsonb, now(), now());

update public.profiles
set is_provider = true
where id = 'c2300000-0000-0000-0000-000000000003'::uuid;

insert into public.provider_profiles (
  provider_id, display_name, provider_type, verification_status, is_active
) values (
  'c2300000-0000-0000-0000-000000000003',
  'Media Test Provider',
  'business',
  'verified',
  true
);

insert into public.service_categories (
  id, slug, name, vertical, booking_mode, is_active, sort_order
) values (
  'c2300000-0000-0000-0000-000000000010',
  'media-test-service',
  'Media Test Service',
  'other',
  'reservation',
  true,
  9980
);

insert into public.service_bookings (
  id, customer_id, category_id, provider_id, status, currency, completed_at
) values (
  'c2300000-0000-0000-0000-000000000011',
  'c2300000-0000-0000-0000-000000000001',
  'c2300000-0000-0000-0000-000000000010',
  'c2300000-0000-0000-0000-000000000003',
  'completed',
  'PGK',
  now()
);

select ok(
  exists (
    select 1
    from storage.buckets
    where id = 'client-media'
      and public = false
      and file_size_limit = 5242880
  ),
  'client-media bucket exists and is private with a 5 MiB limit'
);

select is(
  (
    select array_agg(value order by value)
    from (
      select unnest(allowed_mime_types) as value
      from storage.buckets
      where id = 'client-media'
    ) mime
  ),
  array['image/jpeg', 'image/png', 'image/webp']::text[],
  'client-media accepts only supported image MIME types'
);

select is(
  (
    select count(*)::integer
    from pg_policies
    where schemaname = 'storage'
      and tablename = 'objects'
      and policyname like 'client_media_%'
  ),
  4,
  'client-media has select/insert/update/delete policies'
);

select ok(
  public.client_media_can_read(
    'c2300000-0000-0000-0000-000000000001/avatar/profile.jpg',
    'c2300000-0000-0000-0000-000000000001'::uuid
  ),
  'owner may read own media path even before it is attached'
);

update public.profiles
set avatar_url =
  'storage://client-media/c2300000-0000-0000-0000-000000000001/avatar/profile.jpg'
where id = 'c2300000-0000-0000-0000-000000000001'::uuid;

insert into public.account_preferences (
  user_id, profile_visibility
) values (
  'c2300000-0000-0000-0000-000000000001',
  'private'
)
on conflict (user_id) do update
set profile_visibility = excluded.profile_visibility;

select ok(
  not public.client_media_can_read(
    'c2300000-0000-0000-0000-000000000001/avatar/profile.jpg',
    'c2300000-0000-0000-0000-000000000002'::uuid
  ),
  'private avatar is hidden from another signed-in account'
);

update public.account_preferences
set profile_visibility = 'registered'
where user_id = 'c2300000-0000-0000-0000-000000000001'::uuid;

select ok(
  public.client_media_can_read(
    'c2300000-0000-0000-0000-000000000001/avatar/profile.jpg',
    'c2300000-0000-0000-0000-000000000002'::uuid
  ),
  'registered avatar is readable by another signed-in account'
);

select ok(
  not public.client_media_can_read(
    'c2300000-0000-0000-0000-000000000001/avatar/profile.jpg',
    null
  ),
  'registered avatar is hidden from anonymous users'
);

update public.account_preferences
set profile_visibility = 'public'
where user_id = 'c2300000-0000-0000-0000-000000000001'::uuid;

select ok(
  public.client_media_can_read(
    'c2300000-0000-0000-0000-000000000001/avatar/profile.jpg',
    null
  ),
  'public avatar is readable anonymously'
);

insert into public.service_reviews (
  booking_id,
  reviewer_id,
  provider_id,
  rating,
  photo_urls,
  visibility
) values (
  'c2300000-0000-0000-0000-000000000011',
  'c2300000-0000-0000-0000-000000000001',
  'c2300000-0000-0000-0000-000000000003',
  5,
  array[
    'storage://client-media/c2300000-0000-0000-0000-000000000001/reviews/c2300000-0000-0000-0000-000000000011/photo-1.jpg'
  ],
  'registered'
);

select ok(
  public.client_media_can_read(
    'c2300000-0000-0000-0000-000000000001/reviews/c2300000-0000-0000-0000-000000000011/photo-1.jpg',
    'c2300000-0000-0000-0000-000000000002'::uuid
  ),
  'registered review photo is readable by another signed-in account'
);

select ok(
  not public.client_media_can_read(
    'c2300000-0000-0000-0000-000000000001/reviews/c2300000-0000-0000-0000-000000000011/photo-1.jpg',
    null
  ),
  'registered review photo is hidden from anonymous users'
);

update public.service_reviews
set visibility = 'public'
where booking_id = 'c2300000-0000-0000-0000-000000000011'::uuid;

select ok(
  public.client_media_can_read(
    'c2300000-0000-0000-0000-000000000001/reviews/c2300000-0000-0000-0000-000000000011/photo-1.jpg',
    null
  ),
  'public review photo is readable anonymously'
);

select ok(
  not public.client_media_can_read(
    'c2300000-0000-0000-0000-000000000002/unknown/photo.jpg',
    'c2300000-0000-0000-0000-000000000001'::uuid
  ),
  'unattached media owned by another account is not readable'
);

select set_config(
  'request.jwt.claim.sub',
  'c2300000-0000-0000-0000-000000000001',
  true
);

select throws_ok(
  $$select public.update_my_account_profile_v2(
    'Media Owner',
    null,
    null,
    null,
    'storage://client-media/c2300000-0000-0000-0000-000000000002/avatar/private.jpg',
    null,
    true,
    true,
    false,
    'public',
    'public',
    true,
    true,
    true
  )$$,
  '23514',
  null,
  'profile cannot attach another account client-media object'
);

select throws_ok(
  $$select public.submit_service_review(
    'c2300000-0000-0000-0000-000000000011',
    5,
    'Attempted foreign media reference',
    'Ownership check',
    array[
      'storage://client-media/c2300000-0000-0000-0000-000000000002/reviews/private.jpg'
    ],
    'public'
  )$$,
  '23514',
  null,
  'review cannot publish another account client-media object'
);

select * from finish();
rollback;
