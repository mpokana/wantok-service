-- Wantok Service provider onboarding hardening.
-- Provider applications use a trusted RPC so allowed service types and duplicate
-- pending applications are enforced consistently across mobile and web clients.

CREATE OR REPLACE FUNCTION public.submit_provider_application(
  p_service_type text,
  p_company_name text DEFAULT NULL,
  p_vehicle_plate text DEFAULT NULL,
  p_vehicle_make text DEFAULT NULL,
  p_vehicle_model text DEFAULT NULL,
  p_vehicle_color text DEFAULT NULL,
  p_notes text DEFAULT NULL
)
RETURNS public.provider_applications
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
  v_service_type text := lower(trim(COALESCE(p_service_type, '')));
  v_application public.provider_applications%ROWTYPE;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Authentication required';
  END IF;

  IF v_service_type NOT IN (
    'driver',
    'vehicle_hire',
    'boat_hire',
    'boat_operator',
    'delivery',
    'food_vendor',
    'shop',
    'specialist',
    'general_labour',
    'venue',
    'events'
  ) THEN
    RAISE EXCEPTION 'Unsupported provider service type';
  END IF;

  IF EXISTS (
    SELECT 1
    FROM public.provider_applications AS pa
    WHERE pa.user_id = auth.uid()
      AND lower(pa.service_type) = v_service_type
      AND pa.status IN ('pending', 'approved')
  ) THEN
    RAISE EXCEPTION 'An application already exists for this service';
  END IF;

  INSERT INTO public.provider_applications (
    user_id,
    service_type,
    company_name,
    vehicle_plate,
    vehicle_make,
    vehicle_model,
    vehicle_color,
    notes
  )
  VALUES (
    auth.uid(),
    v_service_type,
    NULLIF(trim(p_company_name), ''),
    NULLIF(trim(p_vehicle_plate), ''),
    NULLIF(trim(p_vehicle_make), ''),
    NULLIF(trim(p_vehicle_model), ''),
    NULLIF(trim(p_vehicle_color), ''),
    NULLIF(trim(p_notes), '')
  )
  RETURNING * INTO v_application;

  RETURN v_application;
END;
$$;

REVOKE INSERT ON TABLE public.provider_applications FROM authenticated;
REVOKE ALL ON FUNCTION public.submit_provider_application(
  text, text, text, text, text, text, text
) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.submit_provider_application(
  text, text, text, text, text, text, text
) TO authenticated;
