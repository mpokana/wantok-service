begin;
create extension if not exists pgtap with schema extensions;
select plan(9);

select is(
 (select count(*)::int from public.service_categories
  where slug in ('shopping-retail','home-services','beauty-wellness',
  'health-medical','travel-flights','education-training','financial-services')),
 7, 'Seven new, independent catalogue categories exist');

select is(
 (select count(*)::int from public.service_categories
  where slug in ('shopping-retail','home-services','beauty-wellness',
  'health-medical','travel-flights','education-training','financial-services')
    and is_active and booking_mode='information'),
 7, 'New categories are discoverable but information-only');

select is(
 (select count(*)::int from public.service_categories
  where slug in ('shopping-retail','home-services','beauty-wellness',
  'health-medical','travel-flights','education-training','financial-services')
    and metadata->>'transactions_enabled' = 'false'
    and metadata->>'provider_onboarding_enabled' = 'false'
    and metadata->>'rollout_status'='catalogue_only'),
 7, 'No money, provider onboarding or booking workflows are unlocked');

select is((select count(*)::int from public.service_categories
 where slug in ('food','groceries','taxi-ride','delivery','events')
 and is_active),5,'Existing live marketplace categories retained');

select is((select count(*)::int from public.service_categories
 where slug = 'accommodation' and not is_active),1,
 'Existing unlaunched accommodation integration remains inactive');

select is((select count(*)::int from public.service_categories
 where slug = 'health-medical'
 and metadata->>'licensed_provider_verification_required'='true'),1,
 'Medical directory requires licensed provider verification');

select is((select count(*)::int from public.service_categories
 where slug = 'financial-services'
 and metadata->>'regulated_provider_verification_required'='true'),1,
 'Financial directory requires regulatory provider verification');

select is((select count(*)::int from public.provider_services ps
 join public.service_categories c on c.id=ps.category_id
 where c.slug in ('shopping-retail','home-services','beauty-wellness',
  'health-medical','travel-flights','education-training','financial-services')),
 0,'Category migration does not insert fictitious provider services');

select is((select count(*)::int from public.service_categories
 where slug in ('professional-services','specialist-services')),1,
 'Existing approved specialist-services routing stays canonical');

select * from finish();
rollback;
