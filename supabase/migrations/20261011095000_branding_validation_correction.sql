-- Correct JSONB map-count validation and literal-dot file extensions.
CREATE OR REPLACE FUNCTION public.validate_wantok_branding(p_doc jsonb)
RETURNS boolean LANGUAGE plpgsql IMMUTABLE SET search_path=public AS $$
DECLARE
  v_theme jsonb; v_media jsonb; v_slug text; v_slots jsonb;
  v_slot text; v_path text;
BEGIN
  IF jsonb_typeof(p_doc) <> 'object' OR NOT (p_doc ? 'theme' AND p_doc ? 'media')
    OR p_doc - ARRAY['theme','media'] <> '{}'::jsonb THEN RETURN false; END IF;
  v_theme := p_doc->'theme'; v_media := p_doc->'media';
  IF jsonb_typeof(v_theme)<>'object' OR jsonb_typeof(v_media)<>'object'
    OR v_theme - ARRAY['mode','primary','secondary','cardRadius'] <> '{}'::jsonb
    OR v_theme->>'mode' NOT IN ('light','dark','system')
    OR coalesce(v_theme->>'primary','') !~ '^#[0-9A-Fa-f]{6}$'
    OR coalesce(v_theme->>'secondary','') !~ '^#[0-9A-Fa-f]{6}$'
    OR coalesce(v_theme->>'cardRadius','') !~ '^[0-9]{1,2}$'
    OR (v_theme->>'cardRadius')::integer NOT BETWEEN 8 AND 30
  THEN RETURN false; END IF;
  IF (SELECT count(*) FROM jsonb_object_keys(v_media)) > 80 THEN RETURN false; END IF;
  FOR v_slug,v_slots IN SELECT key,value FROM jsonb_each(v_media) LOOP
    IF v_slug !~ '^[a-z0-9-]{2,65}$' OR jsonb_typeof(v_slots)<>'object'
      OR v_slots - ARRAY['homeIcon','cardImage','bannerImage'] <> '{}'::jsonb
    THEN RETURN false; END IF;
    FOR v_slot,v_path IN SELECT key,value #>> '{}' FROM jsonb_each(v_slots) LOOP
      IF v_path !~ ('^categories/' || v_slug || '/' || v_slot ||
        '/[a-f0-9-]{36}[.](png|jpg|webp)$') THEN RETURN false; END IF;
    END LOOP;
  END LOOP;
  RETURN true;
EXCEPTION WHEN OTHERS THEN RETURN false;
END; $$;
DROP POLICY IF EXISTS branding_assets_upload_admin ON storage.objects;
CREATE POLICY branding_assets_upload_admin
ON storage.objects FOR INSERT TO authenticated
WITH CHECK (bucket_id='wantok-branding'
  AND public.is_technical_platform_admin(auth.uid())
  AND name ~ '^categories/[a-z0-9-]+/(homeIcon|cardImage|bannerImage)/[a-f0-9-]{36}[.](png|jpg|webp)$');
