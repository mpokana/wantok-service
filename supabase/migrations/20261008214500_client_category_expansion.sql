-- Wantok Services category expansion: additive, catalogue-only classifications.
-- Existing provider verification, bookings, payment tables and service rows
-- are unchanged. No fictitious providers or example transactions are inserted.
--
-- Active means discoverable in the category catalogue, NOT bookable.
-- The information-only category route must not call booking or payment RPCs.

INSERT INTO public.service_categories
  (slug, name, description, vertical, booking_mode, icon_key, is_active,
   sort_order, metadata)
VALUES
 ('shopping-retail', 'Shopping & Retail',
  'Discover approved local shops and retail providers as onboarding becomes available.',
  'shopping', 'information', 'shopping', true, 125,
  '{"rollout_status":"catalogue_only","transactions_enabled":false,"provider_onboarding_enabled":false}'::jsonb),
 ('home-services', 'Home Services',
  'Find household repairs and maintenance services. Direct bookings are not yet enabled.',
  'people', 'information', 'home-services', true, 126,
  '{"rollout_status":"catalogue_only","transactions_enabled":false,"provider_onboarding_enabled":false}'::jsonb),
 ('beauty-wellness', 'Beauty & Wellness',
  'Explore hair, grooming, beauty and wellness services when verified providers join.',
  'people', 'information', 'beauty-wellness', true, 127,
  '{"rollout_status":"catalogue_only","transactions_enabled":false,"provider_onboarding_enabled":false}'::jsonb),
 ('health-medical', 'Health & Medical',
  'Future discovery of licensed healthcare providers and wellbeing services; no diagnosis or treatment booking is enabled.',
  'people', 'information', 'health-medical', true, 128,
  '{"rollout_status":"catalogue_only","transactions_enabled":false,"provider_onboarding_enabled":false,"licensed_provider_verification_required":true}'::jsonb),
 ('travel-flights', 'Travel & Flights',
  'Future travel planning and flights discovery; no live airline fares, seats or ticketing available.',
  'travel', 'information', 'travel-flights', true, 129,
  '{"rollout_status":"catalogue_only","transactions_enabled":false,"provider_onboarding_enabled":false}'::jsonb),
 ('education-training', 'Education & Training',
  'Future verified tutors, courses and practical skills training discovery.',
  'people', 'information', 'education-training', true, 130,
  '{"rollout_status":"catalogue_only","transactions_enabled":false,"provider_onboarding_enabled":false}'::jsonb),
 ('financial-services', 'Financial Services',
  'Future directory of authorised financial service providers; no loans, remittances, investments or money transfers are available.',
  'other', 'information', 'financial-services', true, 131,
  '{"rollout_status":"catalogue_only","transactions_enabled":false,"provider_onboarding_enabled":false,"regulated_provider_verification_required":true}'::jsonb)
ON CONFLICT (slug) DO NOTHING;
