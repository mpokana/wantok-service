-- International discovery defaults are user choices, not inferred identity.
CREATE TABLE IF NOT EXISTS public.client_discovery_preferences (
  user_id uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  country_code text NOT NULL CHECK (country_code ~ '^[A-Z]{2}$'),
  region text CHECK (char_length(region) <= 120),
  town text CHECK (char_length(town) <= 120),
  updated_at timestamptz NOT NULL DEFAULT now()
);
ALTER TABLE public.client_discovery_preferences ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.client_discovery_preferences FROM anon;
GRANT SELECT, INSERT, UPDATE ON public.client_discovery_preferences TO authenticated;
CREATE POLICY client_discovery_pref_read ON public.client_discovery_preferences
 FOR SELECT TO authenticated USING (user_id=auth.uid());
CREATE POLICY client_discovery_pref_create ON public.client_discovery_preferences
 FOR INSERT TO authenticated WITH CHECK (user_id=auth.uid());
CREATE POLICY client_discovery_pref_update ON public.client_discovery_preferences
 FOR UPDATE TO authenticated USING (user_id=auth.uid())
 WITH CHECK (user_id=auth.uid());
CREATE INDEX IF NOT EXISTS staged_provider_applications_country_idx
 ON public.staged_provider_applications(coverage_country_code,status);
COMMENT ON TABLE public.client_discovery_preferences IS
 'A user-selected discovery location. Browser locale may initialise country, but is not evidence of physical location.';
