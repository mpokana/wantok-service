#Requires -Version 5.1
<#
T2.4 isolated integration: schema-only + five non-personal reference tables.
Runs without published ports, external network, customer records or SQL writes
to the live Supabase database. Default action removes the disposable container.
#>
param([switch]$KeepContainer)
$ErrorActionPreference = 'Stop'
$root = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$source = 'supabase_db_wantok-service'
$image = 'public.ecr.aws/supabase/postgres:17.11.0.002'
$id = [Guid]::NewGuid().ToString('N').Substring(0, 10)
$target = "wantok-t24-qa-$id"
$cache = Join-Path $root '.wantok'
$schema = Join-Path $cache "t24-schema-$id.dump"
$reference = Join-Path $cache "t24-reference-$id.dump"
$sourceSchema = "/tmp/t24-schema-$id.dump"
$sourceReference = "/tmp/t24-reference-$id.dump"
$started = $false

function RunDocker {
  param([string[]]$Arguments)
  & docker @Arguments
  if ($LASTEXITCODE -ne 0) { throw 'T2.4 isolated Docker step failed.' }
}

try {
  if (!(Test-Path $cache)) { New-Item -ItemType Directory -Path $cache | Out-Null }
  $names = @(& docker ps -a --format '{{.Names}}')
  if ($names -contains $target) { throw 'Unexpected test-container name collision.' }
  Write-Output 'T24_STAGE=Starting disconnected PostgreSQL'
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

  Write-Output 'T24_STAGE=Schema-only and reference-only snapshot'
  RunDocker @('exec',$source,'pg_dump','-U','postgres','-d','postgres',
    '-F','c','--schema-only','--no-owner','--no-acl','-f',$sourceSchema)
  RunDocker @('exec',$source,'pg_dump','-U','postgres','-d','postgres',
    '-F','c','--data-only','--no-owner','--no-acl',
    '--table=public.app_roles','--table=public.technical_modules',
    '--table=public.technical_access_levels',
    '--table=public.technical_permissions',
    '--table=public.technical_access_level_permissions','-f',$sourceReference)
  RunDocker @('cp',"$($source):$sourceSchema",$schema)
  RunDocker @('cp',"$($source):$sourceReference",$reference)
  RunDocker @('cp',$schema,"$($target):/tmp/t24-schema.dump")
  RunDocker @('cp',$reference,"$($target):/tmp/t24-reference.dump")

  Write-Output 'T24_STAGE=Restoring isolated schema'
  RunDocker @('exec',$target,'createdb','-U','supabase_admin',
    '--template=template0','t24_stage')
  RunDocker @('exec',$target,'pg_restore','-U','supabase_admin',
    '-d','t24_stage','--no-owner','--no-acl','--exit-on-error',
    '/tmp/t24-schema.dump')
  $roleGrants = 'GRANT USAGE ON SCHEMA public,auth,extensions TO authenticated; ' +
    'GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA extensions TO authenticated; ' +
    'ALTER DEFAULT PRIVILEGES IN SCHEMA extensions GRANT EXECUTE ON FUNCTIONS TO authenticated;'
  RunDocker @('exec',$target,'psql','-X','-U','supabase_admin',
    '-d','t24_stage','-v','ON_ERROR_STOP=1','-c',$roleGrants)
  RunDocker @('exec',$target,'pg_restore','-U','supabase_admin',
    '-d','t24_stage','--no-owner','--no-acl','--exit-on-error',
    '/tmp/t24-reference.dump')

  $migrations = @(
    '20261011240000_technical_scoped_health_log_adapter.sql',
    '20261011241000_technical_messaging_queue_snapshot.sql',
    '20261011242000_technical_scoped_activity_audit.sql',
    '20261011243000_technical_central_log_source_contract.sql'
  )
  foreach ($migration in $migrations) {
    $file = Join-Path $root "supabase\migrations\$migration"
    if (!(Test-Path $file)) { throw "Missing migration $migration" }
    RunDocker @('cp',$file,"$($target):/tmp/$migration")
    RunDocker @('exec',$target,'psql','-X','-U','supabase_admin',
      '-d','t24_stage','-v','ON_ERROR_STOP=1','-f',"/tmp/$migration")
    Write-Output "T24_STAGE_APPLIED=$migration"
  }

  $tests = @(
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
    $output = @(& docker exec $target psql -X -U supabase_admin -d t24_stage -v ON_ERROR_STOP=1 -f "/tmp/$name")
    if ($LASTEXITCODE -ne 0) { throw "PostgreSQL test command failed: $name" }
    $ok = @($output | Where-Object { $_ -match '^\s*ok \d+ - ' }).Count
    $failed = @($output | Where-Object { $_ -match '^\s*not ok \d+' -or $_ -match '^\s*# Failed' }).Count
    if ($failed -gt 0 -or $ok -ne $test.count) {
      throw "Assertion mismatch: $name expected $($test.count); observed $ok; failures $failed"
    }
    Write-Output "T24_STAGE_TEST_PASS=$name assertions=$ok"
  }

  $isolatedSql = "select (to_regprocedure('public.list_technical_module_log_events(text,integer)') is not null) and (to_regprocedure('public.get_technical_messaging_queue_snapshot(text)') is not null) and (to_regprocedure('public.list_technical_module_activity(text,integer)') is not null) and (to_regprocedure('public.get_technical_central_log_readiness(text)') is not null) and (not exists(select 1 from auth.users where id in ('b2400000-0000-0000-0000-000000000001'::uuid,'b2410000-0000-0000-0000-000000000001'::uuid,'b2420000-0000-0000-0000-000000000001'::uuid))) and ((select count(*) from public.notification_outbox)=0)"
  $check = @(& docker exec $target psql -X -U supabase_admin -d t24_stage -t -A -c $isolatedSql)
  if ($LASTEXITCODE -ne 0 -or ($check -join '').Trim() -ne 't') {
    throw 'Isolated migration or test rollback verification failed.'
  }
  $sharedSql = "select (to_regprocedure('public.list_technical_module_log_events(text,integer)') is null) and (to_regprocedure('public.get_technical_messaging_queue_snapshot(text)') is null) and (to_regprocedure('public.list_technical_module_activity(text,integer)') is null) and (to_regprocedure('public.get_technical_central_log_readiness(text)') is null)"
  $shared = @(& docker exec $source psql -X -U postgres -d postgres -t -A -c $sharedSql)
  if ($LASTEXITCODE -ne 0 -or ($shared -join '').Trim() -ne 't') {
    throw 'Shared Supabase database has unexpected T2.4 schema state.'
  }
  Write-Output 'T24_STAGING_PASS=4 migrations,58 assertions,fixtures rolled back'
  Write-Output 'T24_SHARED_DB_UNCHANGED=true'
  if ($KeepContainer) { Write-Output "T24_DEBUG_CONTAINER=$target" }
}
finally {
  if ($started -and !$KeepContainer) {
    & docker stop $target | Out-Null
    Write-Output 'T24_ISOLATED_CONTAINER_REMOVED=true'
  }
  if (Test-Path $schema) { Remove-Item -LiteralPath $schema -Force }
  if (Test-Path $reference) { Remove-Item -LiteralPath $reference -Force }
  & docker exec $source rm -f $sourceSchema $sourceReference 2>$null | Out-Null
}
