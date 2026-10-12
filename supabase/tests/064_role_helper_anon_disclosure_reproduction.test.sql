-- E6R: reproduce local role-helper metadata visibility, NOT a safety certificate.
-- Network-disabled disposable fixture ONLY; synthetic user IDs; full rollback.
-- Passing observations represent an OPEN G8 information-disclosure decision.
BEGIN;
CREATE EXTENSION IF NOT EXISTS pgtap WITH SCHEMA extensions;
SELECT plan(18);

INSERT INTO auth.users(id,aud,role,email,created_at,updated_at)
VALUES
 ('a6400000-0000-4000-8000-000000000001','authenticated','authenticated','e6r-operations@example.test',now(),now()),
 ('a6400000-0000-4000-8000-000000000002','authenticated','authenticated','e6r-technical@example.test',now(),now()),
 ('a6400000-0000-4000-8000-000000000003','authenticated','authenticated','e6r-ordinary@example.test',now(),now());
INSERT INTO public.user_roles(user_id,role_code)
VALUES ('a6400000-0000-4000-8000-000000000001','admin'),
       ('a6400000-0000-4000-8000-000000000002','tech_platform_admin');

SELECT ok(has_function_privilege('anon','public.has_role(text,uuid)','EXECUTE'),'anon currently has EXECUTE: has_role');
SELECT ok(has_function_privilege('anon','public.is_admin(uuid)','EXECUTE'),'anon currently has EXECUTE: is_admin');
SELECT ok(has_function_privilege('anon','public.is_technical_platform_admin(uuid)','EXECUTE'),'anon currently has EXECUTE: is_technical_platform_admin');
SELECT ok(has_function_privilege('anon','public.has_platform_permission(text,uuid)','EXECUTE'),'anon currently has EXECUTE: has_platform_permission');
SELECT ok(has_function_privilege('anon','public.has_technical_permission(text,text,uuid)','EXECUTE'),'anon currently has EXECUTE: has_technical_permission');
SELECT ok(has_function_privilege('anon','public.effective_technical_access_level(text,uuid)','EXECUTE'),'anon currently has EXECUTE: effective_technical_access_level');
SELECT ok(has_function_privilege('anon','public.can_access_technical_console(uuid)','EXECUTE'),'anon currently has EXECUTE: can_access_technical_console');
SELECT ok(has_function_privilege('anon','public.can_manage_technical_module_access(text,uuid)','EXECUTE'),'anon currently has EXECUTE: can_manage_technical_module_access');
SET LOCAL ROLE anon;
SELECT is(auth.uid(),NULL::uuid,'anon has no authenticated identity');
SELECT ok(public.has_role('admin','a6400000-0000-4000-8000-000000000001'::uuid),'anon can query another synthetic subject has_role');
SELECT ok(public.is_admin('a6400000-0000-4000-8000-000000000001'::uuid),'anon can query another synthetic subject is_admin');
SELECT ok(public.is_technical_platform_admin('a6400000-0000-4000-8000-000000000002'::uuid),'anon can query another synthetic subject Technical admin');
SELECT ok(public.can_access_technical_console('a6400000-0000-4000-8000-000000000002'::uuid),'anon can query another synthetic subject Technical entitlement');
SELECT ok(NOT public.is_admin(),'anon own-default lookup does not confer admin');
SELECT ok(NOT public.is_technical_platform_admin(),'anon own-default lookup does not confer Technical admin');
SELECT throws_ok(
 $$SELECT public.grant_user_role('a6400000-0000-4000-8000-000000000003'::uuid,'admin',NULL)$$,
 'P0001','Authentication required','anon still cannot assign staff privilege');
RESET ROLE;
SELECT is((SELECT count(*)::integer FROM public.user_roles WHERE user_id='a6400000-0000-4000-8000-000000000003' AND role_code IN ('admin','tech_platform_admin')),0,'no privileged role assigned to ordinary synthetic target (customer base role is expected)');
SELECT ok(NOT public.is_admin('a6400000-0000-4000-8000-000000000003'::uuid),'ordinary synthetic target has no admin role');
SELECT * FROM finish();
ROLLBACK;
