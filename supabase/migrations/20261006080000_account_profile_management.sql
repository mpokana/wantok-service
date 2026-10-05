-- Wantok Service account/profile management.
-- Personal profile/preferences are owner-scoped. Provider profile updates remain
-- descriptive only and cannot alter verification or activation authority.

ALTER TABLE public.profiles
  ADD COLUMN preferred_name text,
  ADD COLUMN address_text text;

CREATE TABLE public.account_preferences (
  user_id uuid PRIMARY KEY REFERENCES public.profiles(id) ON DELETE CASCADE,
  notify_booking_updates boolean NOT NULL DEFAULT true,
  notify_messages boolean NOT NULL DEFAULT true,
  notify_promotions boolean NOT NULL DEFAULT false,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TRIGGER account_preferences_set_updated_at
BEFORE UPDATE ON public.account_preferences
FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

ALTER TABLE public.account_preferences ENABLE ROW LEVEL SECURITY;

REVOKE ALL ON TABLE public.account_preferences FROM anon, authenticated;
GRANT SELECT, INSERT (
  user_id,
  notify_booking_updates,
  notify_messages,
  notify_promotions
), UPDATE (
  notify_booking_updates,
  notify_messages,
  notify_promotions
) ON TABLE public.account_preferences TO authenticated;

GRANT UPDATE (preferred_name, address_text)
  ON TABLE public.profiles TO authenticated;

CREATE POLICY account_preferences_own
ON public.account_preferences
FOR ALL
TO authenticated
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

CREATE OR REPLACE FUNCTION public.get_my_account_profile()
RETURNS TABLE (
  id uuid,
  full_name text,
  preferred_name text,
  phone text,
  address_text text,
  notify_booking_updates boolean,
  notify_messages boolean,
  notify_promotions boolean
)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public, auth
AS $$
  SELECT
    profile.id,
    profile.full_name,
    profile.preferred_name,
    profile.phone,
    profile.address_text,
    coalesce(preferences.notify_booking_updates, true),
    coalesce(preferences.notify_messages, true),
    coalesce(preferences.notify_promotions, false)
  FROM public.profiles profile
  LEFT JOIN public.account_preferences preferences
    ON preferences.user_id = profile.id
  WHERE profile.id = auth.uid();
$$;

CREATE OR REPLACE FUNCTION public.update_my_account_profile(
  p_full_name text,
  p_preferred_name text DEFAULT NULL,
  p_phone text DEFAULT NULL,
  p_address_text text DEFAULT NULL,
  p_notify_booking_updates boolean DEFAULT true,
  p_notify_messages boolean DEFAULT true,
  p_notify_promotions boolean DEFAULT false
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
  v_user_id uuid := auth.uid();
  v_full_name text := nullif(btrim(coalesce(p_full_name, '')), '');
BEGIN
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION USING ERRCODE = 'P0001', MESSAGE = 'Authentication required';
  END IF;

  IF v_full_name IS NULL THEN
    RAISE EXCEPTION USING ERRCODE = 'P0001', MESSAGE = 'Full name is required';
  END IF;

  IF char_length(v_full_name) > 160 THEN
    RAISE EXCEPTION USING ERRCODE = 'P0001', MESSAGE = 'Full name is too long';
  END IF;

  UPDATE public.profiles
  SET
    full_name = v_full_name,
    preferred_name = nullif(btrim(coalesce(p_preferred_name, '')), ''),
    phone = nullif(btrim(coalesce(p_phone, '')), ''),
    address_text = nullif(btrim(coalesce(p_address_text, '')), '')
  WHERE id = v_user_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION USING ERRCODE = 'P0001', MESSAGE = 'Profile not found';
  END IF;

  INSERT INTO public.account_preferences (
    user_id,
    notify_booking_updates,
    notify_messages,
    notify_promotions
  ) VALUES (
    v_user_id,
    coalesce(p_notify_booking_updates, true),
    coalesce(p_notify_messages, true),
    coalesce(p_notify_promotions, false)
  )
  ON CONFLICT (user_id) DO UPDATE
  SET
    notify_booking_updates = excluded.notify_booking_updates,
    notify_messages = excluded.notify_messages,
    notify_promotions = excluded.notify_promotions;
END;
$$;

CREATE OR REPLACE FUNCTION public.get_my_provider_profile()
RETURNS TABLE (
  provider_id uuid,
  display_name text,
  provider_type text,
  bio text,
  verification_status text,
  is_active boolean,
  base_address text,
  service_radius_km numeric
)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public, auth
AS $$
  SELECT
    provider.provider_id,
    provider.display_name,
    provider.provider_type,
    provider.bio,
    provider.verification_status,
    provider.is_active,
    provider.base_address,
    provider.service_radius_km
  FROM public.provider_profiles provider
  WHERE provider.provider_id = auth.uid();
$$;

CREATE OR REPLACE FUNCTION public.update_my_provider_profile(
  p_display_name text,
  p_provider_type text,
  p_bio text DEFAULT NULL,
  p_base_address text DEFAULT NULL,
  p_service_radius_km numeric DEFAULT NULL
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
  v_user_id uuid := auth.uid();
  v_display_name text := nullif(btrim(coalesce(p_display_name, '')), '');
  v_provider_type text := lower(btrim(coalesce(p_provider_type, '')));
BEGIN
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION USING ERRCODE = 'P0001', MESSAGE = 'Authentication required';
  END IF;

  IF v_display_name IS NULL THEN
    RAISE EXCEPTION USING ERRCODE = 'P0001', MESSAGE = 'Provider display name is required';
  END IF;

  IF v_provider_type NOT IN ('individual', 'business', 'organisation') THEN
    RAISE EXCEPTION USING ERRCODE = 'P0001', MESSAGE = 'Invalid provider type';
  END IF;

  IF p_service_radius_km IS NOT NULL AND p_service_radius_km < 0 THEN
    RAISE EXCEPTION USING ERRCODE = 'P0001', MESSAGE = 'Service radius cannot be negative';
  END IF;

  UPDATE public.provider_profiles
  SET
    display_name = v_display_name,
    provider_type = v_provider_type,
    bio = nullif(btrim(coalesce(p_bio, '')), ''),
    base_address = nullif(btrim(coalesce(p_base_address, '')), ''),
    service_radius_km = p_service_radius_km
  WHERE provider_id = v_user_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION USING ERRCODE = 'P0001', MESSAGE = 'Provider profile not found';
  END IF;
END;
$$;

REVOKE ALL ON FUNCTION public.get_my_account_profile() FROM PUBLIC;
REVOKE ALL ON FUNCTION public.update_my_account_profile(
  text, text, text, text, boolean, boolean, boolean
) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.get_my_provider_profile() FROM PUBLIC;
REVOKE ALL ON FUNCTION public.update_my_provider_profile(
  text, text, text, text, numeric
) FROM PUBLIC;

GRANT EXECUTE ON FUNCTION public.get_my_account_profile() TO authenticated;
GRANT EXECUTE ON FUNCTION public.update_my_account_profile(
  text, text, text, text, boolean, boolean, boolean
) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_my_provider_profile() TO authenticated;
GRANT EXECUTE ON FUNCTION public.update_my_provider_profile(
  text, text, text, text, numeric
) TO authenticated;
