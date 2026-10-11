BEGIN;
CREATE EXTENSION IF NOT EXISTS pgtap WITH SCHEMA extensions;
SELECT plan(4);
INSERT INTO auth.users(id,aud,role,email,created_at,updated_at)
VALUES('c7000000-0000-0000-0000-000000000001','authenticated','authenticated',
'intake-case-test@wantok.local',now(),now());
SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub','c7000000-0000-0000-0000-000000000001',true);
SELECT lives_ok($$SELECT public.submit_vendor_intake_case(
'home-services','individual','Plumbing Test','PG','Morobe','Lae',
'Section 02 Lot 03','test@wantok.example','+67570000000',
'national_id','1234',NULL,NULL,'Repairs and plumbing installations',
'{"trade_speciality":"Plumbing"}'::jsonb)$$,'Intake accepts a complete case');
SELECT is((SELECT count(*)::integer FROM public.vendor_intake_cases),1,'Case was created');
SELECT is((SELECT count(*)::integer FROM public.vendor_intake_events),1,'Audit event recorded');
SELECT is((SELECT status FROM public.vendor_intake_cases LIMIT 1),'submitted','No auto approval');
SELECT * FROM finish();
ROLLBACK;
