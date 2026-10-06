-- CX1A: client experience foundations.
-- Adds richer personal privacy/profile controls, saved items, trusted people,
-- linked-review presentation fields, and secured client-facing RPCs.

ALTER TABLE public.profiles
  ADD COLUMN avatar_url text,
  ADD COLUMN bio text;

ALTER TABLE public.account_preferences
  ADD COLUMN profile_visibility text NOT NULL DEFAULT 'private'
    CHECK (profile_visibility IN ('private', 'registered', 'public')),
  ADD COLUMN review_visibility text NOT NULL DEFAULT 'public'
    CHECK (review_visibility IN ('private', 'registered', 'public')),
  ADD COLUMN saved_items_private boolean NOT NULL DEFAULT true,
  ADD COLUMN allow_recommendations boolean NOT NULL DEFAULT true,
  ADD COLUMN allow_profile_sharing boolean NOT NULL DEFAULT true;

ALTER TABLE public.service_reviews
  ADD COLUMN title text,
  ADD COLUMN photo_urls text[] NOT NULL DEFAULT '{}'::text[],
  ADD COLUMN visibility text NOT NULL DEFAULT 'public'
    CHECK (visibility IN ('private', 'registered', 'public'));

DROP POLICY IF EXISTS service_reviews_public_read
  ON public.service_reviews;

CREATE POLICY service_reviews_public_read
ON public.service_reviews
FOR SELECT
TO anon
USING (visibility = 'public');

CREATE POLICY service_reviews_authenticated_read
ON public.service_reviews
FOR SELECT
TO authenticated
USING (
  reviewer_id = auth.uid()
  OR public.is_admin(auth.uid())
  OR visibility IN ('public', 'registered')
);

REVOKE INSERT ON TABLE public.service_reviews FROM authenticated;

CREATE TABLE public.client_saved_items (
  user_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  item_type text NOT NULL
    CHECK (item_type IN ('provider', 'service', 'resource', 'event', 'category')),
  entity_id uuid NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (user_id, item_type, entity_id)
);

CREATE INDEX client_saved_items_user_created_idx
  ON public.client_saved_items (user_id, created_at DESC);

ALTER TABLE public.client_saved_items ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON TABLE public.client_saved_items FROM anon, authenticated;

CREATE POLICY client_saved_items_own
ON public.client_saved_items
FOR ALL
TO authenticated
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

CREATE TABLE public.trusted_people (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  owner_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  display_name text NOT NULL CHECK (char_length(btrim(display_name)) BETWEEN 1 AND 160),
  relationship text CHECK (
    relationship IS NULL OR char_length(btrim(relationship)) <= 80
  ),
  phone text CHECK (phone IS NULL OR char_length(btrim(phone)) <= 40),
  email text CHECK (email IS NULL OR char_length(btrim(email)) <= 320),
  notes text CHECK (notes IS NULL OR char_length(notes) <= 1000),
  is_active boolean NOT NULL DEFAULT true,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX trusted_people_owner_active_idx
  ON public.trusted_people (owner_id, is_active, display_name);

CREATE TRIGGER trusted_people_set_updated_at
BEFORE UPDATE ON public.trusted_people
FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

ALTER TABLE public.trusted_people ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON TABLE public.trusted_people FROM anon, authenticated;

GRANT SELECT ON TABLE public.trusted_people TO authenticated;
GRANT INSERT (
  owner_id, display_name, relationship, phone, email, notes, is_active
) ON TABLE public.trusted_people TO authenticated;
GRANT UPDATE (
  display_name, relationship, phone, email, notes, is_active
) ON TABLE public.trusted_people TO authenticated;
GRANT DELETE ON TABLE public.trusted_people TO authenticated;

CREATE POLICY trusted_people_own
ON public.trusted_people
FOR ALL
TO authenticated
USING (owner_id = auth.uid())
WITH CHECK (owner_id = auth.uid());

CREATE OR REPLACE FUNCTION public.cx1_saved_entity_exists(
  p_item_type text,
  p_entity_id uuid
)
RETURNS boolean
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  RETURN CASE p_item_type
    WHEN 'provider' THEN EXISTS (
      SELECT 1
      FROM public.provider_profiles provider
      WHERE provider.provider_id = p_entity_id
        AND provider.is_active
        AND provider.verification_status = 'verified'
    )
    WHEN 'service' THEN EXISTS (
      SELECT 1
      FROM public.provider_services service
      JOIN public.provider_profiles provider
        ON provider.provider_id = service.provider_id
      WHERE service.id = p_entity_id
        AND service.status = 'active'
        AND provider.is_active
        AND provider.verification_status = 'verified'
    )
    WHEN 'resource' THEN EXISTS (
      SELECT 1
      FROM public.provider_resources resource
      JOIN public.provider_profiles provider
        ON provider.provider_id = resource.provider_id
      WHERE resource.id = p_entity_id
        AND resource.status = 'active'
        AND provider.is_active
        AND provider.verification_status = 'verified'
    )
    WHEN 'event' THEN EXISTS (
      SELECT 1
      FROM public.events event
      WHERE event.id = p_entity_id
        AND event.status = 'published'
    )
    WHEN 'category' THEN EXISTS (
      SELECT 1
      FROM public.service_categories category
      WHERE category.id = p_entity_id
        AND category.is_active
    )
    ELSE false
  END;
END;
$$;

CREATE OR REPLACE FUNCTION public.set_client_saved_item(
  p_item_type text,
  p_entity_id uuid,
  p_saved boolean DEFAULT true
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
  v_user_id uuid := auth.uid();
  v_type text := lower(btrim(coalesce(p_item_type, '')));
BEGIN
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION USING ERRCODE = 'P0001', MESSAGE = 'Authentication required';
  END IF;

  IF v_type NOT IN ('provider', 'service', 'resource', 'event', 'category') THEN
    RAISE EXCEPTION USING ERRCODE = 'P0001', MESSAGE = 'Unsupported saved item type';
  END IF;

  IF p_entity_id IS NULL THEN
    RAISE EXCEPTION USING ERRCODE = 'P0001', MESSAGE = 'Saved item identifier is required';
  END IF;

  IF coalesce(p_saved, true) THEN
    IF NOT public.cx1_saved_entity_exists(v_type, p_entity_id) THEN
      RAISE EXCEPTION USING ERRCODE = 'P0001', MESSAGE = 'Saved item is not available';
    END IF;

    INSERT INTO public.client_saved_items (user_id, item_type, entity_id)
    VALUES (v_user_id, v_type, p_entity_id)
    ON CONFLICT DO NOTHING;
  ELSE
    DELETE FROM public.client_saved_items
    WHERE user_id = v_user_id
      AND item_type = v_type
      AND entity_id = p_entity_id;
  END IF;
END;
$$;

CREATE OR REPLACE FUNCTION public.list_my_saved_items()
RETURNS TABLE (
  item_type text,
  entity_id uuid,
  title text,
  subtitle text,
  image_url text,
  created_at timestamptz
)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public, auth
AS $$
  SELECT
    saved.item_type,
    saved.entity_id,
    CASE saved.item_type
      WHEN 'provider' THEN (
        SELECT provider.display_name
        FROM public.provider_profiles provider
        WHERE provider.provider_id = saved.entity_id
      )
      WHEN 'service' THEN (
        SELECT service.title
        FROM public.provider_services service
        WHERE service.id = saved.entity_id
      )
      WHEN 'resource' THEN (
        SELECT resource.name
        FROM public.provider_resources resource
        WHERE resource.id = saved.entity_id
      )
      WHEN 'event' THEN (
        SELECT event.title
        FROM public.events event
        WHERE event.id = saved.entity_id
      )
      WHEN 'category' THEN (
        SELECT category.name
        FROM public.service_categories category
        WHERE category.id = saved.entity_id
      )
    END AS title,
    CASE saved.item_type
      WHEN 'provider' THEN (
        SELECT provider.bio
        FROM public.provider_profiles provider
        WHERE provider.provider_id = saved.entity_id
      )
      WHEN 'service' THEN (
        SELECT service.service_address
        FROM public.provider_services service
        WHERE service.id = saved.entity_id
      )
      WHEN 'resource' THEN (
        SELECT resource.address_text
        FROM public.provider_resources resource
        WHERE resource.id = saved.entity_id
      )
      WHEN 'event' THEN (
        SELECT event.venue_name
        FROM public.events event
        WHERE event.id = saved.entity_id
      )
      WHEN 'category' THEN (
        SELECT category.description
        FROM public.service_categories category
        WHERE category.id = saved.entity_id
      )
    END AS subtitle,
    CASE saved.item_type
      WHEN 'event' THEN (
        SELECT event.image_url
        FROM public.events event
        WHERE event.id = saved.entity_id
      )
      ELSE NULL
    END AS image_url,
    saved.created_at
  FROM public.client_saved_items saved
  WHERE saved.user_id = auth.uid()
    AND public.cx1_saved_entity_exists(saved.item_type, saved.entity_id)
  ORDER BY saved.created_at DESC;
$$;

CREATE OR REPLACE FUNCTION public.get_my_account_profile_v2()
RETURNS TABLE (
  id uuid,
  full_name text,
  preferred_name text,
  phone text,
  address_text text,
  avatar_url text,
  bio text,
  notify_booking_updates boolean,
  notify_messages boolean,
  notify_promotions boolean,
  profile_visibility text,
  review_visibility text,
  saved_items_private boolean,
  allow_recommendations boolean,
  allow_profile_sharing boolean
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
    profile.avatar_url,
    profile.bio,
    coalesce(preferences.notify_booking_updates, true),
    coalesce(preferences.notify_messages, true),
    coalesce(preferences.notify_promotions, false),
    coalesce(preferences.profile_visibility, 'private'),
    coalesce(preferences.review_visibility, 'public'),
    coalesce(preferences.saved_items_private, true),
    coalesce(preferences.allow_recommendations, true),
    coalesce(preferences.allow_profile_sharing, true)
  FROM public.profiles profile
  LEFT JOIN public.account_preferences preferences
    ON preferences.user_id = profile.id
  WHERE profile.id = auth.uid();
$$;

CREATE OR REPLACE FUNCTION public.update_my_account_profile_v2(
  p_full_name text,
  p_preferred_name text DEFAULT NULL,
  p_phone text DEFAULT NULL,
  p_address_text text DEFAULT NULL,
  p_avatar_url text DEFAULT NULL,
  p_bio text DEFAULT NULL,
  p_notify_booking_updates boolean DEFAULT true,
  p_notify_messages boolean DEFAULT true,
  p_notify_promotions boolean DEFAULT false,
  p_profile_visibility text DEFAULT 'private',
  p_review_visibility text DEFAULT 'public',
  p_saved_items_private boolean DEFAULT true,
  p_allow_recommendations boolean DEFAULT true,
  p_allow_profile_sharing boolean DEFAULT true
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
  v_user_id uuid := auth.uid();
  v_full_name text := nullif(btrim(coalesce(p_full_name, '')), '');
  v_profile_visibility text := lower(btrim(coalesce(p_profile_visibility, 'private')));
  v_review_visibility text := lower(btrim(coalesce(p_review_visibility, 'public')));
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

  IF v_profile_visibility NOT IN ('private', 'registered', 'public') THEN
    RAISE EXCEPTION USING ERRCODE = 'P0001', MESSAGE = 'Invalid profile visibility';
  END IF;

  IF v_review_visibility NOT IN ('private', 'registered', 'public') THEN
    RAISE EXCEPTION USING ERRCODE = 'P0001', MESSAGE = 'Invalid review visibility';
  END IF;

  IF p_avatar_url IS NOT NULL AND char_length(btrim(p_avatar_url)) > 2048 THEN
    RAISE EXCEPTION USING ERRCODE = 'P0001', MESSAGE = 'Avatar URL is too long';
  END IF;

  IF p_bio IS NOT NULL AND char_length(p_bio) > 1200 THEN
    RAISE EXCEPTION USING ERRCODE = 'P0001', MESSAGE = 'Profile bio is too long';
  END IF;

  UPDATE public.profiles
  SET
    full_name = v_full_name,
    preferred_name = nullif(btrim(coalesce(p_preferred_name, '')), ''),
    phone = nullif(btrim(coalesce(p_phone, '')), ''),
    address_text = nullif(btrim(coalesce(p_address_text, '')), ''),
    avatar_url = nullif(btrim(coalesce(p_avatar_url, '')), ''),
    bio = nullif(btrim(coalesce(p_bio, '')), '')
  WHERE id = v_user_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION USING ERRCODE = 'P0001', MESSAGE = 'Profile not found';
  END IF;

  INSERT INTO public.account_preferences (
    user_id,
    notify_booking_updates,
    notify_messages,
    notify_promotions,
    profile_visibility,
    review_visibility,
    saved_items_private,
    allow_recommendations,
    allow_profile_sharing
  ) VALUES (
    v_user_id,
    coalesce(p_notify_booking_updates, true),
    coalesce(p_notify_messages, true),
    coalesce(p_notify_promotions, false),
    v_profile_visibility,
    v_review_visibility,
    coalesce(p_saved_items_private, true),
    coalesce(p_allow_recommendations, true),
    coalesce(p_allow_profile_sharing, true)
  )
  ON CONFLICT (user_id) DO UPDATE
  SET
    notify_booking_updates = excluded.notify_booking_updates,
    notify_messages = excluded.notify_messages,
    notify_promotions = excluded.notify_promotions,
    profile_visibility = excluded.profile_visibility,
    review_visibility = excluded.review_visibility,
    saved_items_private = excluded.saved_items_private,
    allow_recommendations = excluded.allow_recommendations,
    allow_profile_sharing = excluded.allow_profile_sharing;
END;
$$;

CREATE OR REPLACE FUNCTION public.get_client_profile(
  p_user_id uuid
)
RETURNS TABLE (
  id uuid,
  display_name text,
  avatar_url text,
  bio text,
  profile_visibility text,
  is_provider boolean
)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public, auth
AS $$
  SELECT
    profile.id,
    coalesce(nullif(profile.preferred_name, ''), nullif(profile.full_name, ''), 'Wantok user'),
    profile.avatar_url,
    profile.bio,
    coalesce(preferences.profile_visibility, 'private'),
    profile.is_provider
  FROM public.profiles profile
  LEFT JOIN public.account_preferences preferences
    ON preferences.user_id = profile.id
  WHERE profile.id = p_user_id
    AND (
      profile.id = auth.uid()
      OR coalesce(preferences.profile_visibility, 'private') = 'public'
      OR (
        auth.uid() IS NOT NULL
        AND coalesce(preferences.profile_visibility, 'private') = 'registered'
      )
    );
$$;

CREATE OR REPLACE FUNCTION public.submit_service_review(
  p_booking_id uuid,
  p_rating integer,
  p_comment text DEFAULT NULL,
  p_title text DEFAULT NULL,
  p_photo_urls text[] DEFAULT '{}'::text[],
  p_visibility text DEFAULT NULL
)
RETURNS public.service_reviews
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
  v_user_id uuid := auth.uid();
  v_booking public.service_bookings%ROWTYPE;
  v_review public.service_reviews%ROWTYPE;
  v_visibility text;
  v_photo text;
BEGIN
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION USING ERRCODE = 'P0001', MESSAGE = 'Authentication required';
  END IF;

  IF p_rating IS NULL OR p_rating < 1 OR p_rating > 5 THEN
    RAISE EXCEPTION USING ERRCODE = 'P0001', MESSAGE = 'Rating must be between 1 and 5';
  END IF;

  IF p_comment IS NOT NULL AND char_length(p_comment) > 4000 THEN
    RAISE EXCEPTION USING ERRCODE = 'P0001', MESSAGE = 'Review comment is too long';
  END IF;

  IF p_title IS NOT NULL AND char_length(p_title) > 160 THEN
    RAISE EXCEPTION USING ERRCODE = 'P0001', MESSAGE = 'Review title is too long';
  END IF;

  IF coalesce(array_length(p_photo_urls, 1), 0) > 5 THEN
    RAISE EXCEPTION USING ERRCODE = 'P0001', MESSAGE = 'A review can include up to five photos';
  END IF;

  FOREACH v_photo IN ARRAY coalesce(p_photo_urls, '{}'::text[])
  LOOP
    IF char_length(v_photo) > 2048 THEN
      RAISE EXCEPTION USING ERRCODE = 'P0001', MESSAGE = 'Review photo URL is too long';
    END IF;
  END LOOP;

  SELECT booking.*
  INTO v_booking
  FROM public.service_bookings booking
  WHERE booking.id = p_booking_id
    AND booking.customer_id = v_user_id
    AND booking.status = 'completed'
    AND booking.provider_id IS NOT NULL;

  IF NOT FOUND THEN
    RAISE EXCEPTION USING ERRCODE = 'P0001', MESSAGE = 'Completed booking not found';
  END IF;

  SELECT coalesce(
    nullif(lower(btrim(coalesce(p_visibility, ''))), ''),
    preferences.review_visibility,
    'public'
  )
  INTO v_visibility
  FROM public.profiles profile
  LEFT JOIN public.account_preferences preferences
    ON preferences.user_id = profile.id
  WHERE profile.id = v_user_id;

  IF v_visibility NOT IN ('private', 'registered', 'public') THEN
    RAISE EXCEPTION USING ERRCODE = 'P0001', MESSAGE = 'Invalid review visibility';
  END IF;

  INSERT INTO public.service_reviews (
    booking_id,
    reviewer_id,
    provider_id,
    rating,
    comment,
    title,
    photo_urls,
    visibility
  ) VALUES (
    v_booking.id,
    v_user_id,
    v_booking.provider_id,
    p_rating,
    nullif(btrim(coalesce(p_comment, '')), ''),
    nullif(btrim(coalesce(p_title, '')), ''),
    coalesce(p_photo_urls, '{}'::text[]),
    v_visibility
  )
  ON CONFLICT (booking_id) DO UPDATE
  SET
    rating = excluded.rating,
    comment = excluded.comment,
    title = excluded.title,
    photo_urls = excluded.photo_urls,
    visibility = excluded.visibility,
    updated_at = now()
  WHERE public.service_reviews.reviewer_id = v_user_id
  RETURNING * INTO v_review;

  IF v_review.id IS NULL THEN
    RAISE EXCEPTION USING ERRCODE = 'P0001', MESSAGE = 'Review cannot be changed by this account';
  END IF;

  RETURN v_review;
END;
$$;

REVOKE ALL ON FUNCTION public.cx1_saved_entity_exists(text, uuid) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.set_client_saved_item(text, uuid, boolean) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.list_my_saved_items() FROM PUBLIC;
REVOKE ALL ON FUNCTION public.get_my_account_profile_v2() FROM PUBLIC;
REVOKE ALL ON FUNCTION public.update_my_account_profile_v2(
  text, text, text, text, text, text,
  boolean, boolean, boolean,
  text, text, boolean, boolean, boolean
) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.get_client_profile(uuid) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.submit_service_review(
  uuid, integer, text, text, text[], text
) FROM PUBLIC;

GRANT EXECUTE ON FUNCTION public.set_client_saved_item(text, uuid, boolean)
  TO authenticated;
GRANT EXECUTE ON FUNCTION public.list_my_saved_items()
  TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_my_account_profile_v2()
  TO authenticated;
GRANT EXECUTE ON FUNCTION public.update_my_account_profile_v2(
  text, text, text, text, text, text,
  boolean, boolean, boolean,
  text, text, boolean, boolean, boolean
) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_client_profile(uuid)
  TO anon, authenticated;
GRANT EXECUTE ON FUNCTION public.submit_service_review(
  uuid, integer, text, text, text[], text
) TO authenticated;

COMMENT ON TABLE public.client_saved_items IS
  'Owner-scoped bookmarks for discoverable Wantok entities.';
COMMENT ON TABLE public.trusted_people IS
  'Owner-managed trusted people used as the foundation for delegated service requests.';
