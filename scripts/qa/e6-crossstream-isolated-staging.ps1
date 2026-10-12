#Requires -Version 5.1
<#
E6I cross-stream integration: schema-only + seven non-personal reference tables.
Runs without published ports, external network, customer records or SQL writes
to the live Supabase database. Default action removes the disposable container.
#>
param([switch]$KeepContainer)
$ErrorActionPreference = 'Stop'
$root = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$source = 'supabase_db_wantok-service'
$image = 'public.ecr.aws/supabase/postgres:17.11.0.002'
$id = [Guid]::NewGuid().ToString('N').Substring(0, 10)
$target = "wantok-e6i-qa-$id"
$cache = Join-Path $root '.wantok'
$schema = Join-Path $cache "e6i-schema-$id.dump"
$reference = Join-Path $cache "e6i-reference-$id.dump"
$sourceSchema = "/tmp/e6i-schema-$id.dump"
$sourceReference = "/tmp/e6i-reference-$id.dump"
$started = $false

function RunDocker {
  param([string[]]$Arguments)
  & docker @Arguments
  if ($LASTEXITCODE -ne 0) { throw 'E6I isolated Docker step failed.' }
}

try {
  if (!(Test-Path $cache)) { New-Item -ItemType Directory -Path $cache | Out-Null }
  $names = @(& docker ps -a --format '{{.Names}}')
  if ($names -contains $target) { throw 'Unexpected test-container name collision.' }
  Write-Output 'E6I_STAGE=Starting disconnected PostgreSQL'
  $secret = [Guid]::NewGuid().ToString('N')
  RunDocker @('run','--detach','--rm','--name',$target,
    '--network','none','--memory','1024m',
    '--tmpfs','/var/lib/postgresql/data:rw,size=256m',
    '-e',"POSTGRES_PASSWORD=$secret",'--entrypoint','docker-entrypoint.sh',
    $image,'postgres','-D','/var/lib/postgresql/data')
  $started = $true
  $secret = $null
  $ready = $false
  for ($i = 0; $i -lt 40; $i++) {
    & docker exec $target pg_isready -U postgres -d postgres 2>$null | Out-Null
    if ($LASTEXITCODE -eq 0) { $ready = $true; break }
    Start-Sleep -Milliseconds 500
  }
  if (!$ready) { throw 'Isolated database did not start.' }
  $networkMode = (& docker inspect $target --format '{{.HostConfig.NetworkMode}}').Trim()
  if ($networkMode -ne 'none') { throw 'Test database must not have networking.' }

  Write-Output 'E6I_STAGE=Schema-only and reference-only snapshot'
  RunDocker @('exec',$source,'pg_dump','-U','postgres','-d','postgres',
    '-F','c','--schema-only','--no-owner','--no-acl','-f',$sourceSchema)
  RunDocker @('exec',$source,'pg_dump','-U','postgres','-d','postgres',
    '-F','c','--data-only','--no-owner','--no-acl',
    '--table=public.app_roles','--table=public.technical_modules',
    '--table=public.technical_access_levels',
    '--table=public.technical_permissions',
    '--table=public.technical_access_level_permissions',
    '--table=public.service_categories',
    '--table=public.provider_onboarding_policies','-f',$sourceReference)
  RunDocker @('cp',"$($source):$sourceSchema",$schema)
  RunDocker @('cp',"$($source):$sourceReference",$reference)
  RunDocker @('cp',$schema,"$($target):/tmp/e6i-schema.dump")
  RunDocker @('cp',$reference,"$($target):/tmp/e6i-reference.dump")

  Write-Output 'E6I_STAGE=Restoring isolated schema'
  RunDocker @('exec',$target,'createdb','-U','supabase_admin',
    '--template=template0','e6i_stage')
  RunDocker @('exec',$target,'pg_restore','-U','supabase_admin',
    '-d','e6i_stage','--no-owner','--no-acl','--exit-on-error',
    '/tmp/e6i-schema.dump')
  $roleGrants = 'GRANT USAGE ON SCHEMA public,auth,extensions TO anon,authenticated,service_role; ' +
    'GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA extensions TO anon,authenticated,service_role; ' +
    'ALTER DEFAULT PRIVILEGES IN SCHEMA extensions GRANT EXECUTE ON FUNCTIONS TO authenticated;'
  RunDocker @('exec',$target,'psql','-X','-U','supabase_admin',
    '-d','e6i_stage','-v','ON_ERROR_STOP=1','-c',$roleGrants)
  RunDocker @('exec',$target,'pg_restore','-U','supabase_admin',
    '-d','e6i_stage','--no-owner','--no-acl','--exit-on-error',
    '/tmp/e6i-reference.dump')

  # The schema-only --no-acl restore intentionally omits original grants.
  # Recreate ONLY the E6 read/execute permissions needed by test 057.
  # This is a fixture ACL and does not assert production privilege parity.
  $caseTestAcl = 'GRANT SELECT ON public.vendor_intake_cases, ' +
    'public.vendor_verification_checks, public.vendor_evidence_requests, ' +
    'public.staged_provider_applications, public.provider_services, ' +
    'public.vendor_clearance_revocation_events TO authenticated; ' +
    'GRANT SELECT ON public.provider_profiles, public.provider_services TO anon, authenticated; ' +
    'REVOKE ALL ON FUNCTION public.register_operations_case_jurisdiction(uuid,text,uuid,text) ' +
    'FROM PUBLIC,anon,authenticated; ' +
    'REVOKE ALL ON FUNCTION public.map_operations_service_category(uuid,text,uuid,text) ' +
    'FROM PUBLIC,anon,authenticated; ' +
    'REVOKE ALL ON FUNCTION public.register_operations_region(text,text,uuid,text) ' +
    'FROM PUBLIC,anon,authenticated; ' +
    'REVOKE ALL ON FUNCTION public.emergency_revoke_vendor_clearance_trusted(uuid,uuid,text) ' +
    'FROM PUBLIC,anon,authenticated; ' +
    'REVOKE ALL ON FUNCTION public.pause_expired_vendor_clearances() ' +
    'FROM PUBLIC,anon,authenticated; ' +
    'GRANT EXECUTE ON FUNCTION public.emergency_revoke_vendor_clearance_trusted(uuid,uuid,text) ' +
    'TO service_role; ' +
    'REVOKE ALL ON FUNCTION public.record_operations_case_conflict_trusted(text,uuid,uuid,uuid,text) ' +
    'FROM PUBLIC,anon,authenticated; ' +
    'GRANT EXECUTE ON FUNCTION public.record_operations_case_conflict_trusted(text,uuid,uuid,uuid,text) ' +
    'TO service_role; ' +
    'REVOKE ALL ON FUNCTION public.has_operations_clearance_scope(text,uuid) ' +
    'FROM PUBLIC,anon; ' +
    'GRANT EXECUTE ON FUNCTION public.has_operations_clearance_scope(text,uuid) ' +
    'TO authenticated; ' +
    'REVOKE ALL ON FUNCTION public.configure_operations_provisioner(uuid,text,text,uuid,text,boolean) ' +
    'FROM PUBLIC,anon,authenticated; ' +
    'GRANT EXECUTE ON FUNCTION public.configure_operations_provisioner(uuid,text,text,uuid,text,boolean) ' +
    'TO service_role; ' +
    'REVOKE ALL ON FUNCTION public.decide_operations_duty_change(uuid,boolean,text) ' +
    'FROM PUBLIC,anon,authenticated; ' +
    'GRANT EXECUTE ON FUNCTION public.decide_operations_duty_change(uuid,boolean,text) TO authenticated,service_role; ' +
    'GRANT EXECUTE ON FUNCTION public.write_audit_event(text,text,uuid,jsonb,uuid) ' +
    'TO anon,authenticated,service_role; ' +
    'GRANT EXECUTE ON FUNCTION public.enqueue_notification(uuid,text,text,text,jsonb,text,text,text) ' +
    'TO anon,authenticated,service_role;'
  RunDocker @('exec',$target,'psql','-X','-U','supabase_admin',
    '-d','e6i_stage','-v','ON_ERROR_STOP=1','-c',$caseTestAcl)

  # Capture the selected function ownership/grants/SQL bodies immediately
  # before and after E6N ALTER FUNCTION; proconfig is the ONLY intended change.
  # This is same-disposable-stage preservation, NOT production owner/ACL parity.
  $aclFingerprintSql = "SELECT count(*)::text || '|' || md5(string_agg(p.oid::text || ':' || p.proowner::text || ':' || coalesce(p.proacl::text,'') || ':' || md5(p.prosrc), ';' ORDER BY p.oid)) FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace WHERE n.nspname='public' AND p.prosecdef AND (p.proname ~ '^(has_operations_|configure_operations_|request_operations_|decide_operations_|register_operations_|map_operations_|record_operations_|triage_vendor_|submit_vendor_intake_|list_vendor_clearance_|revoke_vendor_activation_|emergency_revoke_vendor_|pause_expired_vendor_)' OR p.proname IN ('admin_set_provider_service_status','review_provider_application'))"
  $ownerAclBefore = $null
  $migrations = @(
    '20261011233000_operations_independent_case_review.sql',
    '20261011240000_technical_scoped_health_log_adapter.sql',
    '20261011241000_technical_messaging_queue_snapshot.sql',
    '20261011242000_technical_scoped_activity_audit.sql',
    '20261011243000_technical_central_log_source_contract.sql',
    '20261012140000_e6_operations_definer_search_path.sql',
    '20261012152000_e6_shared_internal_rpc_execute_boundary.sql'
  )
  foreach ($migration in $migrations) {
    $file = Join-Path $root "supabase\migrations\$migration"
    if (!(Test-Path $file)) { throw "Missing migration $migration" }
    if ($migration -eq '20261012152000_e6_shared_internal_rpc_execute_boundary.sql') {
      $unsafeAcl = "SELECT has_function_privilege('anon','public.write_audit_event(text,text,uuid,jsonb,uuid)','EXECUTE') AND has_function_privilege('authenticated','public.enqueue_notification(uuid,text,text,text,jsonb,text,text,text)','EXECUTE')"
      $unsafeBaseline = (@(& docker exec $target psql -X -U supabase_admin -d e6i_stage -v ON_ERROR_STOP=1 -t -A -c $unsafeAcl) -join '').Trim()
      if ($LASTEXITCODE -ne 0 -or $unsafeBaseline -ne 't') { throw 'Expected isolated fixture baseline RPC grants missing before E6O' }
      Write-Output 'E6O_DISPOSABLE_PREPATCH_UNTRUSTED_GRANTS_REPRODUCED=true'
    }
    if ($migration -eq '20261012140000_e6_operations_definer_search_path.sql') {
      $ownerAclBefore = (@(& docker exec $target psql -X -U supabase_admin -d e6i_stage -v ON_ERROR_STOP=1 -t -A -c $aclFingerprintSql) -join '').Trim()
      if ($LASTEXITCODE -ne 0 -or !$ownerAclBefore.StartsWith('19|')) { throw 'Unexpected E6 definer pre-hardening catalog or count' }
    }
    RunDocker @('cp',$file,"$($target):/tmp/$migration")
    RunDocker @('exec',$target,'psql','-X','-U','supabase_admin',
      '-d','e6i_stage','-v','ON_ERROR_STOP=1','-f',"/tmp/$migration")
    Write-Output "E6I_STAGE_APPLIED=$migration"
  }
  $ownerAclAfter = (@(& docker exec $target psql -X -U supabase_admin -d e6i_stage -v ON_ERROR_STOP=1 -t -A -c $aclFingerprintSql) -join '').Trim()
  if ($LASTEXITCODE -ne 0 -or $ownerAclBefore -ne $ownerAclAfter) { throw 'E6N changed SQL body, ownership or function grants in disposable staging' }
  Write-Output 'E6N_19_FUNCTION_BODY_OWNER_ACL_UNCHANGED=true'

  $tests = @(
    @{ name='051_operations_case_jurisdiction.test.sql'; count=35 },
    @{ name='052_operations_clearance_safety_scope.test.sql'; count=34 },
    @{ name='056_operations_case_recusals.test.sql'; count=18 },
    @{ name='057_operations_independent_case_review.test.sql'; count=19 },
    @{ name='058_public_marketplace_visibility_boundary.test.sql'; count=17 },
    @{ name='060_operations_definer_temp_path.test.sql'; count=25 },
    @{ name='061_internal_rpc_execute_boundary.test.sql'; count=14 },
    @{ name='062_privileged_role_control_anon_denials.test.sql'; count=23 },
    @{ name='063_role_helper_cross_principal_boundary.test.sql'; count=25 },
    @{ name='090_technical_scoped_health_log_adapter.test.sql'; count=12 },
    @{ name='091_technical_messaging_queue_snapshot.test.sql'; count=13 },
    @{ name='092_technical_scoped_activity_audit.test.sql'; count=14 },
    @{ name='093_technical_central_log_source_contract.test.sql'; count=19 }
  )
  foreach ($test in $tests) {
    $name = $test.name
    $file = Join-Path $root "supabase\tests\$name"
    if (!(Test-Path $file)) { throw "Missing test $name" }
    RunDocker @('cp',$file,"$($target):/tmp/$name")
    $output = @(& docker exec $target psql -X -U supabase_admin -d e6i_stage -v ON_ERROR_STOP=1 -f "/tmp/$name")
    if ($LASTEXITCODE -ne 0) { throw "PostgreSQL test command failed: $name" }
    $ok = @($output | Where-Object { $_ -match '^\s*ok \d+ - ' }).Count
    $failed = @($output | Where-Object { $_ -match '^\s*not ok \d+' -or $_ -match '^\s*# Failed' }).Count
    if ($failed -gt 0 -or $ok -ne $test.count) {
      $output | Where-Object { $_ -match '^\s*not ok|^\s*#' } | Select-Object -First 25 | Write-Output
      throw "Assertion mismatch: $name expected $($test.count); observed $ok; failures $failed"
    }
    Write-Output "E6I_STAGE_TEST_PASS=$name assertions=$ok"
  }

  $isolatedSql = "select (to_regprocedure('public.has_operations_clearance_scope(text,uuid)') is not null) and (to_regprocedure('public.list_technical_module_log_events(text,integer)') is not null) and (to_regprocedure('public.get_technical_messaging_queue_snapshot(text)') is not null) and (to_regprocedure('public.list_technical_module_activity(text,integer)') is not null) and (to_regprocedure('public.get_technical_central_log_readiness(text)') is not null) and ((select count(*) from public.technical_log_source_contracts)=0) and ((select count(*) from auth.users)=0) and ((select count(*) from public.vendor_intake_cases)=0) and ((select count(*) from public.notification_outbox)=0) and ((select count(*) from public.audit_events)=0)"
  $check = @(& docker exec $target psql -X -U supabase_admin -d e6i_stage -t -A -c $isolatedSql)
  if ($LASTEXITCODE -ne 0 -or ($check -join '').Trim() -ne 't') {
    throw 'Isolated migration or test rollback verification failed.'
  }
  $sharedSql = "select (to_regprocedure('public.list_technical_module_log_events(text,integer)') is null) and (to_regprocedure('public.get_technical_messaging_queue_snapshot(text)') is null) and (to_regprocedure('public.list_technical_module_activity(text,integer)') is null) and (to_regprocedure('public.get_technical_central_log_readiness(text)') is null) and (not exists (select 1 from supabase_migrations.schema_migrations where version in ('20261011233000','20261011240000','20261011241000','20261011242000','20261011243000','20261012140000','20261012152000')))"
  $shared = @(& docker exec $source psql -X -U postgres -d postgres -t -A -c $sharedSql)
  if ($LASTEXITCODE -ne 0 -or ($shared -join '').Trim() -ne 't') {
    throw 'Shared Supabase database has unexpected T2.4 schema state.'
  }
  Write-Output 'E6Q_STAGING_PASS=7 migrations,268 assertions,fixtures rolled back'
  Write-Output 'E6I_SHARED_DB_UNCHANGED=true'
  if ($KeepContainer) { Write-Output "E6I_DEBUG_CONTAINER=$target" }
}
finally {
  if ($started -and !$KeepContainer) {
    & docker stop $target | Out-Null
    Write-Output 'E6I_ISOLATED_CONTAINER_REMOVED=true'
  }
  if (Test-Path $schema) { Remove-Item -LiteralPath $schema -Force }
  if (Test-Path $reference) { Remove-Item -LiteralPath $reference -Force }
  & docker exec $source rm -f $sourceSchema $sourceReference 2>$null | Out-Null
}
