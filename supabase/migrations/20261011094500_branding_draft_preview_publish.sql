-- Wantok presentation settings, separate from service availability and payments.
-- Only technical platform admins may stage/publish; readers see published only.
CREATE TABLE public.wantok_branding_state (
  id integer PRIMARY KEY DEFAULT 1 CHECK (id = 1),
  published jsonb NOT NULL DEFAULT '{"theme":{"mode":"light","primary":"#006747","secondary":"#F3C846","cardRadius":18},"media":{}}'::jsonb,
  draft jsonb NOT NULL DEFAULT '{"theme":{"mode":"light","primary":"#006747","secondary":"#F3C846","cardRadius":18},"media":{}}'::jsonb,
  version integer NOT NULL DEFAULT 1,
  draft_revision integer NOT NULL DEFAULT 1,
  updated_by uuid REFERENCES auth.users(id),
  published_at timestamptz NOT NULL DEFAULT now()
);
INSERT INTO public.wantok_branding_state(id) VALUES (1)
ON CONFLICT (id) DO NOTHING;

CREATE TABLE public.wantok_branding_history (
  version integer PRIMARY KEY,
  configuration jsonb NOT NULL,
  published_by uuid REFERENCES auth.users(id),
  published_at timestamptz NOT NULL DEFAULT now()
);
INSERT INTO public.wantok_branding_history(version, configuration)
SELECT version, published FROM public.wantok_branding_state
WHERE id = 1 ON CONFLICT DO NOTHING;

ALTER TABLE public.wantok_branding_state ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.wantok_branding_history ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON public.wantok_branding_state FROM anon, authenticated;
REVOKE ALL ON public.wantok_branding_history FROM anon, authenticated;

INSERT INTO storage.buckets (id,name,public,file_size_limit,allowed_mime_types)
VALUES ('wantok-branding','wantok-branding',true,3145728,
  ARRAY['image/png','image/jpeg','image/webp']::text[])
ON CONFLICT (id) DO UPDATE SET public=EXCLUDED.public,
  file_size_limit=EXCLUDED.file_size_limit,allowed_mime_types=EXCLUDED.allowed_mime_types;

CREATE POLICY branding_assets_upload_admin
ON storage.objects FOR INSERT TO authenticated
WITH CHECK (bucket_id='wantok-branding'
  AND public.is_technical_platform_admin(auth.uid())
  AND name ~ '^categories/[a-z0-9-]+/(homeIcon|cardImage|bannerImage)/[a-f0-9-]{36}\\.(png|jpg|webp)$');
-- Immutable image objects: do not grant UPDATE/DELETE. Rollback keeps references.

CREATE OR REPLACE FUNCTION public.validate_wantok_branding(p_doc jsonb)
RETURNS boolean LANGUAGE plpgsql IMMUTABLE SET search_path=public AS $$
DECLARE
  v_theme jsonb;
  v_media jsonb;
  v_slug text;
  v_slots jsonb;
  v_slot text;
  v_path text;
BEGIN
  IF jsonb_typeof(p_doc) <> 'object'
    OR p_doc - ARRAY['theme','media'] <> '{}'::jsonb
    OR NOT (p_doc ? 'theme' AND p_doc ? 'media') THEN RETURN false; END IF;
  v_theme := p_doc->'theme';
  v_media := p_doc->'media';
  IF jsonb_typeof(v_theme) <> 'object'
    OR jsonb_typeof(v_media) <> 'object'
    OR v_theme - ARRAY['mode','primary','secondary','cardRadius'] <> '{}'::jsonb
    OR v_theme->>'mode' NOT IN ('light','dark','system')
    OR coalesce(v_theme->>'primary','') !~ '^#[0-9A-Fa-f]{6}$'
    OR coalesce(v_theme->>'secondary','') !~ '^#[0-9A-Fa-f]{6}$'
    OR coalesce(v_theme->>'cardRadius','') !~ '^[0-9]{1,2}$'
    OR (v_theme->>'cardRadius')::integer NOT BETWEEN 8 AND 30
    THEN RETURN false; END IF;
  IF jsonb_object_length(v_media) > 80 THEN RETURN false; END IF;
  FOR v_slug,v_slots IN SELECT key,value FROM jsonb_each(v_media) LOOP
    IF v_slug !~ '^[a-z0-9-]{2,65}$' OR jsonb_typeof(v_slots) <> 'object'
      OR v_slots - ARRAY['homeIcon','cardImage','bannerImage'] <> '{}'::jsonb
    THEN RETURN false; END IF;
    FOR v_slot,v_path IN SELECT key, value #>> '{}' FROM jsonb_each(v_slots) LOOP
      IF v_path !~ ('^categories/' || v_slug || '/' || v_slot ||
          '/[a-f0-9-]{36}\\.(png|jpg|webp)$')
      THEN RETURN false; END IF;
    END LOOP;
  END LOOP;
  RETURN true;
EXCEPTION WHEN OTHERS THEN RETURN false;
END; $$;

CREATE OR REPLACE FUNCTION public.get_published_wantok_branding()
RETURNS jsonb LANGUAGE sql STABLE SECURITY DEFINER SET search_path=public AS $$
  SELECT published FROM public.wantok_branding_state WHERE id=1;
$$;

CREATE OR REPLACE FUNCTION public.get_wantok_branding_workspace()
RETURNS jsonb LANGUAGE plpgsql STABLE SECURITY DEFINER
SET search_path=public,auth AS $$
DECLARE v public.wantok_branding_state%ROWTYPE;
BEGIN
  IF auth.uid() IS NULL OR NOT public.is_technical_platform_admin(auth.uid()) THEN
    RAISE EXCEPTION 'Technical platform administrator required';
  END IF;
  SELECT * INTO STRICT v FROM public.wantok_branding_state WHERE id=1;
  RETURN jsonb_build_object('draft',v.draft,'published',v.published,
    'version',v.version,'draftRevision',v.draft_revision);
END; $$;

CREATE OR REPLACE FUNCTION public.save_wantok_branding_draft(
  p_config jsonb, p_draft_revision integer)
RETURNS integer LANGUAGE plpgsql SECURITY DEFINER SET search_path=public,auth AS $$
DECLARE v_revision integer;
BEGIN
  IF auth.uid() IS NULL OR NOT public.is_technical_platform_admin(auth.uid()) THEN
    RAISE EXCEPTION 'Technical platform administrator required';
  END IF;
  IF NOT public.validate_wantok_branding(p_config) THEN
    RAISE EXCEPTION 'Invalid branding document';
  END IF;
  UPDATE public.wantok_branding_state SET
    draft=p_config,draft_revision=draft_revision+1,updated_by=auth.uid()
  WHERE id=1 AND draft_revision=p_draft_revision
  RETURNING draft_revision INTO v_revision;
  IF v_revision IS NULL THEN RAISE EXCEPTION 'Branding draft changed; reload first'; END IF;
  PERFORM public.write_audit_event('branding_draft_saved','branding',NULL,
    jsonb_build_object('draft_revision',v_revision));
  RETURN v_revision;
END; $$;

CREATE OR REPLACE FUNCTION public.publish_wantok_branding_draft(
  p_version integer,p_draft_revision integer)
RETURNS integer LANGUAGE plpgsql SECURITY DEFINER SET search_path=public,auth AS $$
DECLARE v public.wantok_branding_state%ROWTYPE;
BEGIN
  IF auth.uid() IS NULL OR NOT public.is_technical_platform_admin(auth.uid()) THEN
    RAISE EXCEPTION 'Technical platform administrator required'; END IF;
  SELECT * INTO STRICT v FROM public.wantok_branding_state WHERE id=1 FOR UPDATE;
  IF v.version<>p_version OR v.draft_revision<>p_draft_revision
  THEN RAISE EXCEPTION 'Branding was changed by another admin; reload first'; END IF;
  IF NOT public.validate_wantok_branding(v.draft) THEN
    RAISE EXCEPTION 'Invalid branding draft'; END IF;
  UPDATE public.wantok_branding_state SET published=v.draft,
    version=v.version+1,published_at=now(),updated_by=auth.uid() WHERE id=1;
  INSERT INTO public.wantok_branding_history(version,configuration,published_by)
  VALUES (v.version+1,v.draft,auth.uid());
  PERFORM public.write_audit_event('branding_published','branding',NULL,
    jsonb_build_object('version',v.version+1));
  RETURN v.version+1;
END; $$;

CREATE OR REPLACE FUNCTION public.restore_wantok_branding_version(
  p_history_version integer, p_current_version integer)
RETURNS integer LANGUAGE plpgsql SECURITY DEFINER SET search_path=public,auth AS $$
DECLARE v public.wantok_branding_state%ROWTYPE;
DECLARE v_saved jsonb;
BEGIN
  IF auth.uid() IS NULL OR NOT public.is_technical_platform_admin(auth.uid()) THEN
    RAISE EXCEPTION 'Technical platform administrator required'; END IF;
  SELECT * INTO STRICT v FROM public.wantok_branding_state WHERE id=1 FOR UPDATE;
  IF v.version<>p_current_version THEN
    RAISE EXCEPTION 'Branding changed; reload first'; END IF;
  SELECT configuration INTO STRICT v_saved FROM public.wantok_branding_history
  WHERE version=p_history_version;
  UPDATE public.wantok_branding_state SET published=v_saved,draft=v_saved,
    version=v.version+1,draft_revision=v.draft_revision+1,
    updated_by=auth.uid(),published_at=now() WHERE id=1;
  INSERT INTO public.wantok_branding_history(version,configuration,published_by)
  VALUES (v.version+1,v_saved,auth.uid());
  PERFORM public.write_audit_event('branding_restored','branding',NULL,
    jsonb_build_object('from_version',p_history_version,'new_version',v.version+1));
  RETURN v.version+1;
END; $$;

REVOKE ALL ON FUNCTION public.validate_wantok_branding(jsonb) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.get_published_wantok_branding() FROM PUBLIC;
REVOKE ALL ON FUNCTION public.get_wantok_branding_workspace() FROM PUBLIC;
REVOKE ALL ON FUNCTION public.save_wantok_branding_draft(jsonb,integer) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.publish_wantok_branding_draft(integer,integer) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.restore_wantok_branding_version(integer,integer) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.get_published_wantok_branding() TO anon,authenticated;
GRANT EXECUTE ON FUNCTION public.get_wantok_branding_workspace() TO authenticated;
GRANT EXECUTE ON FUNCTION public.save_wantok_branding_draft(jsonb,integer) TO authenticated;
GRANT EXECUTE ON FUNCTION public.publish_wantok_branding_draft(integer,integer) TO authenticated;
GRANT EXECUTE ON FUNCTION public.restore_wantok_branding_version(integer,integer) TO authenticated;
