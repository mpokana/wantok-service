-- Read-only, admin-scoped clearance health. No issuance pathway.
CREATE OR REPLACE FUNCTION public.list_vendor_clearance_status()
RETURNS TABLE(provider_id uuid,display_name text,expires_at timestamptz,
 revoked_at timestamptz) LANGUAGE plpgsql SECURITY DEFINER
 SET search_path=public,auth AS $$
BEGIN
 IF auth.uid() IS NULL OR NOT public.is_admin(auth.uid()) THEN
  RAISE EXCEPTION 'Operations administrator required' USING errcode='42501';
 END IF;
 RETURN QUERY
 SELECT c.provider_id,p.display_name,c.expires_at,c.revoked_at
 FROM public.vendor_activation_clearances c
 JOIN public.provider_profiles p ON p.provider_id=c.provider_id
 ORDER BY c.expires_at ASC LIMIT 200;
END $$;
REVOKE ALL ON FUNCTION public.list_vendor_clearance_status()
 FROM PUBLIC,anon;
GRANT EXECUTE ON FUNCTION public.list_vendor_clearance_status()
 TO authenticated;
COMMENT ON FUNCTION public.list_vendor_clearance_status() IS
 'Limited read-only clearance expiry/revocation view for authorised Operations. No evidence or identity numbers and no issuance.';
