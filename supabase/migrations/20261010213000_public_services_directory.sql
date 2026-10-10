-- Public Services is an informational module, not a provider marketplace.
-- The existing service_categories.is_active flag is its operational switch:
-- false hides the tile on Home, Services and the active services catalogue.
-- No payment, booking, emergency dispatch or government affiliation is implied.

INSERT INTO public.service_categories
  (slug, name, description, vertical, booking_mode, icon_key,
   is_active, sort_order, metadata)
VALUES (
  'public-services', 'Public Services',
  'Directory of emergency, health, government and community services in Papua New Guinea.',
  'other', 'information', 'account-balance',
  true, 132,
  '{"rollout_status":"directory","transactions_enabled":false,"provider_onboarding_enabled":false,"official_contacts_verified":false}'::jsonb
)
ON CONFLICT (slug) DO NOTHING;
