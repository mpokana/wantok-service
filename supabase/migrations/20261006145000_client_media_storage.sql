-- CX1C: managed client media.
-- Private storage for profile avatars and review photos. Database fields keep
-- stable storage://client-media/<object> references instead of expiring URLs.

INSERT INTO storage.buckets (
  id,
  name,
  public,
  file_size_limit,
  allowed_mime_types
)
VALUES (
  'client-media',
  'client-media',
  false,
  5242880,
  ARRAY['image/jpeg', 'image/png', 'image/webp']::text[]
)
ON CONFLICT (id) DO UPDATE
SET
  public = EXCLUDED.public,
  file_size_limit = EXCLUDED.file_size_limit,
  allowed_mime_types = EXCLUDED.allowed_mime_types;

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

DROP POLICY IF EXISTS client_media_select ON storage.objects;
DROP POLICY IF EXISTS client_media_insert ON storage.objects;
DROP POLICY IF EXISTS client_media_update ON storage.objects;
DROP POLICY IF EXISTS client_media_delete ON storage.objects;

CREATE POLICY client_media_select
ON storage.objects
FOR SELECT
TO anon, authenticated
USING (
  bucket_id = 'client-media'
  AND public.client_media_can_read(name, auth.uid())
);

CREATE POLICY client_media_insert
ON storage.objects
FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'client-media'
  AND (storage.foldername(name))[1] = auth.uid()::text
);

CREATE POLICY client_media_update
ON storage.objects
FOR UPDATE
TO authenticated
USING (
  bucket_id = 'client-media'
  AND (storage.foldername(name))[1] = auth.uid()::text
)
WITH CHECK (
  bucket_id = 'client-media'
  AND (storage.foldername(name))[1] = auth.uid()::text
);

CREATE POLICY client_media_delete
ON storage.objects
FOR DELETE
TO authenticated
USING (
  bucket_id = 'client-media'
  AND (storage.foldername(name))[1] = auth.uid()::text
);

COMMENT ON FUNCTION public.client_media_can_read(text, uuid) IS
  'Authorises reads of private client-media objects using owner, profile visibility, or review visibility.';
