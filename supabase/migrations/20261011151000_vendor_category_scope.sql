-- Civic/regulated public utilities are not commercial vendor categories.
CREATE OR REPLACE FUNCTION public.guard_vendor_intake_category()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path=public AS $$
DECLARE v_slug text;
BEGIN
  SELECT slug INTO v_slug FROM public.service_categories WHERE id=NEW.category_id;
  IF v_slug IN ('public-services','government-services','community-services',
    'emergency-safety','health-services','health-medical','financial-services') THEN
    RAISE EXCEPTION 'Vendor applications are not accepted for this category'
    USING errcode='22023';
  END IF;
  RETURN NEW;
END $$;
CREATE TRIGGER vendor_intake_category_scope BEFORE INSERT
ON public.vendor_intake_cases FOR EACH ROW
EXECUTE FUNCTION public.guard_vendor_intake_category();
REVOKE ALL ON FUNCTION public.guard_vendor_intake_category() FROM PUBLIC,anon,authenticated;
