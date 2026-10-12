-- E6Q: isolated fake identity/RBAC tests. No real users or login tokens.
-- auth.users rows are synthetic and transaction rollback removes ALL fixtures.
-- SET ROLE with request.jwt.claim.sub is NOT a verified GoTrue sign-in.
BEGIN;
CREATE EXTENSION IF NOT EXISTS pgtap WITH SCHEMA extensions;
SELECT plan(25);

INSERT INTO auth.users(id,aud,role,email,created_at,updated_at)
VALUES
 ('a6100000-0000-4000-8000-000000000001','authenticated','authenticated','e6q-operations@example.test',now(),now()),
 ('a6100000-0000-4000-8000-000000000002','authenticated','authenticated','e6q-technical@example.test',now(),now()),
 ('a6100000-0000-4000-8000-000000000003','authenticated','authenticated','e6q-ordinary@example.test',now(),now()),
 ('a6100000-0000-4000-8000-000000000004','authenticated','authenticated','e6q-target@example.test',now(),now());
INSERT INTO public.user_roles(user_id,role_code)
VALUES
 ('a6100000-0000-4000-8000-000000000001','admin'),
 ('a6100000-0000-4000-8000-000000000002','tech_platform_admin');

SELECT ok(public.is_admin('a6100000-0000-4000-8000-000000000001'), 'Synthetic Operations role is recognised');
SELECT ok(public.is_technical_platform_admin('a6100000-0000-4000-8000-000000000002'), 'Synthetic Technical platform role is recognised');
SELECT ok(NOT public.is_admin('a6100000-0000-4000-8000-000000000002'), 'Technical platform role alone is not Operations admin');
SELECT ok(NOT public.is_technical_platform_admin('a6100000-0000-4000-8000-000000000001'), 'Operations admin role alone is not Technical platform admin');

SET LOCAL ROLE authenticated;
SELECT set_config('request.jwt.claim.sub','a6100000-0000-4000-8000-000000000003',true);
SELECT ok(NOT public.is_admin(), 'Ordinary synthetic caller is not Operations admin');
SELECT ok(NOT public.is_technical_platform_admin(), 'Ordinary synthetic caller is not Technical platform admin');
-- Helper accepts an arbitrary SUBJECT ID. These checks demonstrate a
-- potential cross-person role-information exposure, NOT caller privileges.
SELECT ok(public.is_admin('a6100000-0000-4000-8000-000000000001'), 'Explicit other-subject Operations role can be queried; G8 disclosure review');
SELECT ok(public.is_technical_platform_admin('a6100000-0000-4000-8000-000000000002'), 'Explicit other-subject Technical role can be queried; G8 disclosure review');
SELECT ok(public.can_access_technical_console('a6100000-0000-4000-8000-000000000002'), 'Explicit other-subject technical access metadata is accessible; G8 review');
SELECT ok(NOT public.can_access_technical_console(), 'Implicit caller identity remains without Technical console access');
SELECT throws_ok($$SELECT public.grant_user_role('a6100000-0000-4000-8000-000000000004','admin',NULL)$$,
 'P0001','Operations admin access required','Ordinary actor cannot grant admin');
SELECT throws_ok($$SELECT public.grant_user_role('a6100000-0000-4000-8000-000000000004','tech_support',NULL)$$,
 'P0001','Technical platform admin access required','Ordinary actor cannot grant Technical role');
SELECT throws_ok($$SELECT public.revoke_user_role('a6100000-0000-4000-8000-000000000001','admin')$$,
 'P0001','Operations admin access required','Ordinary actor cannot revoke Operations admin');

SELECT set_config('request.jwt.claim.sub','a6100000-0000-4000-8000-000000000001',true);
SELECT lives_ok($$SELECT public.grant_user_role('a6100000-0000-4000-8000-000000000004','support',NULL)$$,
 'Synthetic Operations admin may issue permitted Operations support role');
SELECT ok(public.has_role('support','a6100000-0000-4000-8000-000000000004'), 'Permitted Operations role is effective in stage');
SELECT throws_ok($$SELECT public.grant_user_role('a6100000-0000-4000-8000-000000000004','tech_platform_admin',NULL)$$,
 'P0001','Technical platform admin access required','Operations-only role cannot grant Technical platform admin');
SELECT throws_ok($$SELECT public.revoke_user_role('a6100000-0000-4000-8000-000000000002','tech_platform_admin')$$,
 'P0001','Technical platform admin access required','Operations-only role cannot revoke Technical platform admin');

SELECT set_config('request.jwt.claim.sub','a6100000-0000-4000-8000-000000000002',true);
SELECT lives_ok($$SELECT public.grant_user_role('a6100000-0000-4000-8000-000000000004','tech_support',NULL)$$,
 'Synthetic Technical platform admin may issue permitted Technical support role');
SELECT ok(public.has_role('tech_support','a6100000-0000-4000-8000-000000000004'), 'Permitted Technical role is effective in stage');
SELECT throws_ok($$SELECT public.grant_user_role('a6100000-0000-4000-8000-000000000004','admin',NULL)$$,
 'P0001','Operations admin access required','Technical-only actor cannot grant Operations admin');
SELECT throws_ok($$SELECT public.revoke_user_role('a6100000-0000-4000-8000-000000000001','admin')$$,
 'P0001','Operations admin access required','Technical-only actor cannot revoke Operations admin');
RESET ROLE;
SELECT ok(NOT public.has_role('admin','a6100000-0000-4000-8000-000000000004'), 'Synthetic target did not gain global Operations admin');
SELECT ok(NOT public.has_role('tech_platform_admin','a6100000-0000-4000-8000-000000000004'), 'Synthetic target did not gain Technical platform admin');
SELECT ok(NOT public.is_admin('a6100000-0000-4000-8000-000000000004'), 'Synthetic target cannot gain Operations admin via helper');
SELECT ok(NOT public.is_technical_platform_admin('a6100000-0000-4000-8000-000000000004'), 'Synthetic target cannot gain Technical platform admin via helper');
SELECT * FROM finish();
ROLLBACK;
