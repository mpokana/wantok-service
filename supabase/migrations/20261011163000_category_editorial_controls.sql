-- CX1 category editorial control: non-destructive, admin-owned catalogue.
-- New entries are OFF by default. No provider, booking or payment writes.
ALTER TABLE public.service_categories
  ADD COLUMN IF NOT EXISTS show_on_home boolean NOT NULL DEFAULT false,
  ADD COLUMN IF NOT EXISTS show_in_services boolean NOT NULL DEFAULT true,
  ADD COLUMN IF NOT EXISTS image_path text;

-- Preserve current Home categories and expose the rest of active categories.
UPDATE public.service_categories
SET show_on_home = true
WHERE is_active = true AND show_on_home = false;

-- Old category references stay intact; future entries are not made bookable.
INSERT INTO public.service_categories
 (slug,name,description,vertical,booking_mode,icon_key,is_active,sort_order,show_on_home,show_in_services,metadata)
VALUES
 ('it-electronics','Electronics & IT','Computer repairs, networking, device support and ICT services.','people','information','memory',false,230,false,false,'{"categoryStage":"pending-media-review"}'),
 ('automotive-repair','Automotive & Mechanics','Vehicle servicing, repairs, diagnostics and mechanics.','people','information','car_repair',false,240,false,false,'{"categoryStage":"pending-media-review"}'),
 ('agriculture-farming','Agriculture & Farming','Farm support, agricultural tools, land and crop services.','people','information','agriculture',false,250,false,false,'{"categoryStage":"pending-media-review"}'),
 ('pets-animal-care','Pets & Animal Care','Pet care, veterinary and animal services.','people','information','pets',false,260,false,false,'{"categoryStage":"pending-media-review"}'),
 ('cleaning-maintenance','Cleaning & Maintenance','Home and commercial cleaning, facilities and maintenance.','people','information','cleaning_services',false,270,false,false,'{"categoryStage":"pending-media-review"}'),
 ('construction-trades','Construction & Trades','Building, renovation and skilled construction services.','people','information','construction',false,280,false,false,'{"categoryStage":"pending-media-review"}')
ON CONFLICT (slug) DO NOTHING;

-- Reuse immutable, admin-only branding storage for category card images.
-- Require category-scoped immutable paths; the public URL is derived by client.
ALTER TABLE public.service_categories
  ADD CONSTRAINT service_category_image_scope_check
  CHECK (
    image_path IS NULL OR image_path ~
    ('^categories/' || slug || '/cardImage/[a-f0-9-]{36}[.](png|jpg|webp)$')
  );

CREATE TABLE IF NOT EXISTS public.service_category_editorial_audit (
  id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  actor_id uuid NOT NULL REFERENCES auth.users(id),
  action text NOT NULL CHECK (action IN ('create','update','archive','remove')),
  category_id uuid NOT NULL,
  category_slug text NOT NULL,
  changed_at timestamptz NOT NULL DEFAULT now(),
  before_record jsonb,
  after_record jsonb
);
ALTER TABLE public.service_category_editorial_audit ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.service_category_editorial_audit FROM PUBLIC,anon,authenticated;

-- All backend mutation fields are validated server-side; no direct authenticated
-- INSERT/UPDATE/DELETE grants on service_categories are added.
CREATE OR REPLACE FUNCTION public.manage_service_category(
  p_action text,
  p_record jsonb DEFAULT '{}'::jsonb,
  p_id uuid DEFAULT NULL,
  p_expected_updated_at timestamptz DEFAULT NULL
) RETURNS jsonb
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public,auth
AS $$
DECLARE
  v_before public.service_categories%ROWTYPE;
  v_after public.service_categories%ROWTYPE;
  v_slug text;
  v_name text;
  v_vertical text;
  v_booking text;
  v_order integer;
  v_icon text;
  v_image text;
  v_active boolean;
  v_home boolean;
  v_services boolean;
  v_description text;
BEGIN
  IF auth.uid() IS NULL OR NOT public.is_technical_platform_admin(auth.uid()) THEN
    RAISE EXCEPTION 'Technical Platform Administrator required';
  END IF;
  IF p_action NOT IN ('create','update','archive','remove') THEN
    RAISE EXCEPTION 'Invalid category operation';
  END IF;

  IF p_action <> 'create' THEN
    IF p_id IS NULL THEN RAISE EXCEPTION 'Category id required'; END IF;
    SELECT * INTO v_before FROM public.service_categories
    WHERE id = p_id FOR UPDATE;
    IF NOT FOUND THEN RAISE EXCEPTION 'Category not found'; END IF;
    IF p_expected_updated_at IS NOT NULL
       AND v_before.updated_at IS DISTINCT FROM p_expected_updated_at THEN
      RAISE EXCEPTION 'Category changed by another editor; reload first';
    END IF;
  END IF;

  IF p_action IN ('create','update') THEN
    IF jsonb_typeof(p_record) <> 'object' OR
       p_record - ARRAY['slug','name','description','vertical','booking_mode',
         'icon_key','is_active','sort_order','show_on_home','show_in_services',
         'image_path'] <> '{}'::jsonb THEN
      RAISE EXCEPTION 'Invalid category editor fields';
    END IF;
    v_slug := lower(btrim(COALESCE(p_record->>'slug',v_before.slug,'')));
    v_name := btrim(COALESCE(p_record->>'name',v_before.name,''));
    v_description := NULLIF(btrim(COALESCE(p_record->>'description',v_before.description,'')),'');
    v_vertical := COALESCE(p_record->>'vertical',v_before.vertical,'people');
    v_booking := COALESCE(p_record->>'booking_mode',v_before.booking_mode,'information');
    v_icon := NULLIF(btrim(COALESCE(p_record->>'icon_key',v_before.icon_key,'')),'');
    v_order := COALESCE((p_record->>'sort_order')::integer,v_before.sort_order,500);
    v_active := COALESCE((p_record->>'is_active')::boolean,v_before.is_active,false);
    v_home := COALESCE((p_record->>'show_on_home')::boolean,v_before.show_on_home,false);
    v_services := COALESCE((p_record->>'show_in_services')::boolean,v_before.show_in_services,true);
    v_image := NULLIF(btrim(COALESCE(p_record->>'image_path',v_before.image_path,'')),'');
    IF v_slug !~ '^[a-z0-9]+(-[a-z0-9]+)*$' OR length(v_slug)>65
      OR length(v_name) NOT BETWEEN 2 AND 100
      OR COALESCE(length(v_description),0)>800
      OR v_vertical NOT IN ('mobility','delivery','hire','people','places','events','food','shopping','travel','other')
      OR v_booking NOT IN ('on_demand','scheduled','quote','reservation','commerce','ticketing','information')
      OR v_order NOT BETWEEN 0 AND 9999
      OR (v_icon IS NOT NULL AND (length(v_icon)>60 OR v_icon !~ '^[a-z0-9_]+$')) THEN
      RAISE EXCEPTION 'Category data failed validation';
    END IF;
    IF v_image IS NOT NULL AND v_image !~
      ('^categories/' || v_slug || '/cardImage/[a-f0-9-]{36}[.](png|jpg|webp)$') THEN
      RAISE EXCEPTION 'Image must be a category-scoped uploaded image';
    END IF;
    IF v_image IS NOT NULL AND NOT EXISTS (
      SELECT 1 FROM storage.objects
      WHERE bucket_id='wantok-branding' AND name=v_image
    ) THEN RAISE EXCEPTION 'Upload the category picture first'; END IF;
    IF v_active AND (
       p_action='create' OR COALESCE(v_before.metadata->>'categoryStage','')='pending-media-review'
      ) AND v_image IS NULL THEN
      RAISE EXCEPTION 'New category requires an approved picture before activation';
    END IF;
    -- No accidental public release of draft catalogue entries.
    IF NOT v_active AND (v_home OR v_services) THEN
      -- show_in_services is an editorial option, but inactive is never discoverable.
      v_home := false;
      v_services := false;
    END IF;
    IF p_action = 'create' THEN
      INSERT INTO public.service_categories
        (slug,name,description,vertical,booking_mode,icon_key,is_active,
         sort_order,show_on_home,show_in_services,image_path)
      VALUES (v_slug,v_name,v_description,v_vertical,v_booking,v_icon,
        v_active,v_order,v_home,v_services,v_image)
      RETURNING * INTO v_after;
    ELSE
      -- Slug becomes immutable once created: provider relations and media URLs
      -- cannot safely follow arbitrary slug renames.
      IF v_slug <> v_before.slug THEN
        RAISE EXCEPTION 'Category slug cannot be changed after creation';
      END IF;
      UPDATE public.service_categories SET
        name=v_name,description=v_description,vertical=v_vertical,
        booking_mode=v_booking,icon_key=v_icon,is_active=v_active,
        sort_order=v_order,show_on_home=v_home,show_in_services=v_services,
        image_path=v_image,updated_at=now()
      WHERE id=p_id RETURNING * INTO v_after;
    END IF;
  ELSIF p_action = 'archive' THEN
    UPDATE public.service_categories SET is_active=false,
      show_on_home=false,show_in_services=false,updated_at=now()
    WHERE id=p_id RETURNING * INTO v_after;
  ELSE
    -- Restrict physical deletion to unused inactive drafts, never live history.
    IF v_before.is_active THEN
      RAISE EXCEPTION 'Deactivate the category before deleting it';
    END IF;
    IF EXISTS(SELECT 1 FROM public.provider_services WHERE category_id=p_id)
      OR EXISTS(SELECT 1 FROM public.provider_resources WHERE category_id=p_id)
      OR EXISTS(SELECT 1 FROM public.service_bookings WHERE category_id=p_id)
      OR EXISTS(SELECT 1 FROM public.provider_category_interests WHERE category_id=p_id)
    THEN
      RAISE EXCEPTION 'Category is referenced; archive instead of deleting';
    END IF;
    DELETE FROM public.service_categories WHERE id=p_id;
  END IF;

  INSERT INTO public.service_category_editorial_audit
    (actor_id,action,category_id,category_slug,before_record,after_record)
  VALUES (auth.uid(),p_action,COALESCE(p_id,v_after.id),
    COALESCE(v_after.slug,v_before.slug),
    CASE WHEN p_action='create' THEN NULL ELSE to_jsonb(v_before) END,
    CASE WHEN p_action='remove' THEN NULL ELSE to_jsonb(v_after) END);
  PERFORM public.write_audit_event('category_'||p_action,'service_category',
    COALESCE(p_id,v_after.id),
    jsonb_build_object('slug',COALESCE(v_after.slug,v_before.slug)));
  RETURN CASE WHEN p_action='remove'
    THEN jsonb_build_object('removed',true,'id',p_id)
    ELSE to_jsonb(v_after) END;
END;
$$;

CREATE OR REPLACE FUNCTION public.list_managed_service_categories()
RETURNS SETOF public.service_categories
LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path=public,auth AS $$
BEGIN
 IF auth.uid() IS NULL OR NOT public.is_technical_platform_admin(auth.uid())
 THEN RAISE EXCEPTION 'Technical Platform Administrator required'; END IF;
 RETURN QUERY SELECT * FROM public.service_categories ORDER BY sort_order,name;
END; $$;

REVOKE ALL ON FUNCTION public.manage_service_category(text,jsonb,uuid,timestamptz) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.list_managed_service_categories() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.manage_service_category(text,jsonb,uuid,timestamptz) TO authenticated;
GRANT EXECUTE ON FUNCTION public.list_managed_service_categories() TO authenticated;
