-- CX1O isolated SQL-only, simulated actor claims. No real GoTrue/JWT testing.
\set ON_ERROR_STOP on
DO $t$ BEGIN
  IF has_function_privilege('anon','public.list_my_track_bookings_candidate()','EXECUTE')
  THEN RAISE EXCEPTION 'anon can execute private function'; END IF;
  RAISE NOTICE 'CX1O_PASS 01 anonymous execute denied';
  IF has_function_privilege('service_role','public.list_my_track_bookings_candidate()','EXECUTE')
  THEN RAISE EXCEPTION 'service_role has unexpected endpoint execution'; END IF;
  RAISE NOTICE 'CX1O_PASS 02 service_role function execute denied in toy stage';
  IF NOT has_function_privilege('authenticated','public.list_my_track_bookings_candidate()','EXECUTE')
  THEN RAISE EXCEPTION 'authenticated role cannot execute'; END IF;
  RAISE NOTICE 'CX1O_PASS 03 authenticated execute granted in toy stage';
  IF (SELECT p.prosecdef FROM pg_proc p WHERE p.oid='public.list_my_track_bookings_candidate()'::regprocedure)
  THEN RAISE EXCEPTION 'security definer is forbidden'; END IF;
  RAISE NOTICE 'CX1O_PASS 04 function is security invoker';
  IF pg_get_function_identity_arguments('public.list_my_track_bookings_candidate()'::regprocedure) <> ''
  THEN RAISE EXCEPTION 'user-injected params are forbidden'; END IF;
  RAISE NOTICE 'CX1O_PASS 05 no user-id or pagination parameters';
  IF (SELECT count(*) FROM pg_attribute a
      WHERE a.attrelid = 'public.service_bookings'::regclass AND a.attname='beneficiary_email') <> 1
  THEN RAISE EXCEPTION 'fixture privacy field missing'; END IF;
  RAISE NOTICE 'CX1O_PASS 06 private fields exist in fixture but are not contract results';
  IF has_table_privilege('anon','public.service_bookings','SELECT')
  THEN RAISE EXCEPTION 'anonymous raw booking table read'; END IF;
  RAISE NOTICE 'CX1O_PASS 07 anonymous raw bookings denied';
  IF NOT (SELECT relrowsecurity FROM pg_class WHERE oid='public.service_bookings'::regclass)
  THEN RAISE EXCEPTION 'synthetic RLS missing'; END IF;
  RAISE NOTICE 'CX1O_PASS 08 synthetic booking RLS enabled';
END $t$;
SET ROLE authenticated;
SET "request.jwt.claim.sub" = '11111111-1111-4111-8111-111111111111';
DO $t$ BEGIN
  IF (SELECT count(*) FROM public.list_my_track_bookings_candidate()) <> 100
  THEN RAISE EXCEPTION 'A actor must get 100 max rows'; END IF;
  RAISE NOTICE 'CX1O_PASS 09 A sees bounded 100 own records';
  IF EXISTS (SELECT 1 FROM public.list_my_track_bookings_candidate()
             WHERE booking_id IN ('b0000000-0000-4000-8000-000000000002'::uuid,
                                  'c0000000-0000-4000-8000-000000000003'::uuid))
  THEN RAISE EXCEPTION 'cross-customer booking visible to A'; END IF;
  RAISE NOTICE 'CX1O_PASS 10 A cannot see B bookings';
  IF (SELECT booking_id FROM public.list_my_track_bookings_candidate() LIMIT 1)
     <> 'a0000000-0000-4000-8000-000000000001'::uuid
  THEN RAISE EXCEPTION 'A descending order mismatch'; END IF;
  RAISE NOTICE 'CX1O_PASS 11 deterministic newest-first ordering';
  IF EXISTS (SELECT 1 FROM public.list_my_track_bookings_candidate() t
             WHERE to_jsonb(t) ?| ARRAY['notes','beneficiary_email','service_address','customer_id','provider_id'])
  THEN RAISE EXCEPTION 'contract projects private fields'; END IF;
  RAISE NOTICE 'CX1O_PASS 12 candidate omits synthetic private fields';
  IF EXISTS (SELECT 1 FROM public.list_my_track_bookings_candidate() t
       WHERE (SELECT count(*) FROM jsonb_object_keys(to_jsonb(t))) <> 4)
  THEN RAISE EXCEPTION 'unexpected contract field count'; END IF;
  RAISE NOTICE 'CX1O_PASS 13 candidate projects exactly four fields';
END $t$;
SET "request.jwt.claim.sub" = '22222222-2222-4222-8222-222222222222';
DO $t$ BEGIN
  IF (SELECT count(*) FROM public.list_my_track_bookings_candidate()) <> 2
  THEN RAISE EXCEPTION 'B should see exactly two records'; END IF;
  RAISE NOTICE 'CX1O_PASS 14 B sees only its two records';
  IF EXISTS (SELECT 1 FROM public.list_my_track_bookings_candidate()
     WHERE booking_id='a0000000-0000-4000-8000-000000000001'::uuid)
  THEN RAISE EXCEPTION 'B can forge A booking query'; END IF;
  RAISE NOTICE 'CX1O_PASS 15 B crafted booking ID cannot fetch A';
END $t$;
SET "request.jwt.claim.sub" = '33333333-3333-4333-8333-333333333333';
DO $t$ BEGIN
  IF (SELECT count(*) FROM public.service_bookings) < 1
  THEN RAISE EXCEPTION 'synthetic provider legacy policy is not represented'; END IF;
  IF (SELECT count(*) FROM public.list_my_track_bookings_candidate()) <> 0
  THEN RAISE EXCEPTION 'provider sees foreign customer through candidate'; END IF;
  RAISE NOTICE 'CX1O_PASS 16 provider raw-RLS permit does not broaden candidate';
END $t$;
SET "request.jwt.claim.sub" = '55555555-5555-4555-8555-555555555555';
DO $t$ BEGIN
  IF (SELECT count(*) FROM public.service_bookings) < 1
  THEN RAISE EXCEPTION 'qualified-provider open-request policy fixture missing'; END IF;
  IF (SELECT count(*) FROM public.list_my_track_bookings_candidate()) <> 0
  THEN RAISE EXCEPTION 'qualified provider sees unrelated bookings through candidate'; END IF;
  RAISE NOTICE 'CX1O_PASS 17 qualified-provider open-request rule not exported';
END $t$;
SET "request.jwt.claim.sub" = '44444444-4444-4444-8444-444444444444';
DO $t$ BEGIN
  IF (SELECT count(*) FROM public.service_bookings) < 100
  THEN RAISE EXCEPTION 'synthetic admin policy fixture missing'; END IF;
  IF (SELECT count(*) FROM public.list_my_track_bookings_candidate()) <> 0
  THEN RAISE EXCEPTION 'admin sees another user through customer-only candidate'; END IF;
  RAISE NOTICE 'CX1O_PASS 18 admin legacy raw-read does not broaden candidate';
END $t$;
SET "request.jwt.claim.sub" = '66666666-6666-4666-8666-666666666666';
DO $t$ BEGIN
  IF (SELECT count(*) FROM public.list_my_track_bookings_candidate()) <> 0
  THEN RAISE EXCEPTION 'unknown customer should have real empty result'; END IF;
  RAISE NOTICE 'CX1O_PASS 19 valid no-booking actor yields zero rows';
END $t$;
RESET "request.jwt.claim.sub";
DO $t$ BEGIN
  IF (SELECT count(*) FROM public.list_my_track_bookings_candidate()) <> 0
  THEN RAISE EXCEPTION 'missing identity should return data'; END IF;
  RAISE NOTICE 'CX1O_PASS 20 missing actor identity yields no rows';
  IF has_table_privilege(current_user,'public.service_bookings','UPDATE')
     OR has_table_privilege(current_user,'public.service_bookings','DELETE')
  THEN RAISE EXCEPTION 'toy stage has unexpected table update/delete'; END IF;
  RAISE NOTICE 'CX1O_PASS 21 no authenticated table update/delete fixture privilege';
END $t$;
RESET ROLE;
