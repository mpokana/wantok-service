-- CX1C hardening: bind managed media references to their owning account.
-- The prior client-media migration is already applied locally; keep it immutable
-- and add ownership enforcement here.

CREATE OR REPLACE FUNCTION public.client_media_reference_is_owned(
  p_reference text,
  p_owner uuid
)
RETURNS boolean
LANGUAGE sql
IMMUTABLE
SET search_path = public
AS $$
  SELECT CASE
    WHEN p_reference IS NULL OR btrim(p_reference) = '' THEN true
    WHEN btrim(p_reference) NOT LIKE 'storage://client-media/%' THEN true
    WHEN p_owner IS NULL THEN false
    ELSE btrim(p_reference) LIKE
      'storage://client-media/' || p_owner::text || '/%'
  END;
$$;

CREATE OR REPLACE FUNCTION public.client_media_references_are_owned(
  p_references text[],
  p_owner uuid
)
RETURNS boolean
LANGUAGE plpgsql
IMMUTABLE
SET search_path = public
AS $$
DECLARE
  v_reference text;
BEGIN
  FOREACH v_reference IN ARRAY coalesce(p_references, '{}'::text[])
  LOOP
    IF NOT public.client_media_reference_is_owned(v_reference, p_owner) THEN
      RETURN false;
    END IF;
  END LOOP;
  RETURN true;
END;
$$;

ALTER TABLE public.profiles
  DROP CONSTRAINT IF EXISTS profiles_avatar_client_media_owner_check;
ALTER TABLE public.profiles
  ADD CONSTRAINT profiles_avatar_client_media_owner_check
  CHECK (public.client_media_reference_is_owned(avatar_url, id));

ALTER TABLE public.service_reviews
  DROP CONSTRAINT IF EXISTS service_reviews_client_media_owner_check;
ALTER TABLE public.service_reviews
  ADD CONSTRAINT service_reviews_client_media_owner_check
  CHECK (
    public.client_media_references_are_owned(photo_urls, reviewer_id)
  );

CREATE OR REPLACE FUNCTION public.client_media_can_read(
  p_name text,
  p_actor uuid DEFAULT auth.uid()
)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public, auth, storage
AS $$
  SELECT
    p_name IS NOT NULL
    AND (
      (p_actor IS NOT NULL AND (storage.foldername(p_name))[1] = p_actor::text)
      OR EXISTS (
        SELECT 1
        FROM public.profiles profile
        LEFT JOIN public.account_preferences preferences
          ON preferences.user_id = profile.id
        WHERE profile.avatar_url = 'storage://client-media/' || p_name
          AND (storage.foldername(p_name))[1] = profile.id::text
          AND (
            coalesce(preferences.profile_visibility, 'private') = 'public'
            OR (
              p_actor IS NOT NULL
              AND coalesce(preferences.profile_visibility, 'private')
                    = 'registered'
            )
          )
      )
      OR EXISTS (
        SELECT 1
        FROM public.service_reviews review
        WHERE ('storage://client-media/' || p_name) = ANY(review.photo_urls)
          AND (storage.foldername(p_name))[1] = review.reviewer_id::text
          AND (
            review.visibility = 'public'
            OR (
              p_actor IS NOT NULL
              AND review.visibility = 'registered'
            )
          )
      )
    );
$$;

REVOKE ALL ON FUNCTION public.client_media_can_read(text, uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.client_media_can_read(text, uuid)
  TO anon, authenticated;

COMMENT ON FUNCTION public.client_media_reference_is_owned(text, uuid) IS
  'Allows legacy/external media URLs but requires client-media references to remain inside the owning account folder.';
COMMENT ON FUNCTION public.client_media_references_are_owned(text[], uuid) IS
  'Validates that every managed client-media reference belongs to the row owner.';
COMMENT ON FUNCTION public.client_media_can_read(text, uuid) IS
  'Authorises reads of private client-media objects using owner, profile visibility, or review visibility with row-owner path binding.';
