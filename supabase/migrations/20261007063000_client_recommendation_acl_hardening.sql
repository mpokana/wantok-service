-- CX1D hardening: personalised recommendations are authenticated-only.
-- Supabase default function privileges can grant anon direct EXECUTE at create
-- time, so revoke the role explicitly in addition to PUBLIC.

REVOKE EXECUTE ON FUNCTION public.list_client_service_recommendations(
  double precision,
  double precision,
  integer
) FROM anon;

REVOKE EXECUTE ON FUNCTION public.list_client_service_recommendations(
  double precision,
  double precision,
  integer
) FROM PUBLIC;

GRANT EXECUTE ON FUNCTION public.list_client_service_recommendations(
  double precision,
  double precision,
  integer
) TO authenticated;
