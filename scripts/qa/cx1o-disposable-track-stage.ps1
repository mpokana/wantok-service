#Requires -Version 5.1
<# CX1O synthetic PostgreSQL stage; never live, networked, persisted or credentialed. #>
param()
$ErrorActionPreference = 'Stop'
$root = (Resolve-Path (Join-Path $PSScriptRoot '../..')).Path
$image = 'public.ecr.aws/supabase/postgres:17.11.0.002'
$container = 'wantok-cx1o-synthetic-' + [guid]::NewGuid().ToString('N').Substring(0,10)
$fixture = Join-Path $PSScriptRoot 'cx1o-disposable-track-fixture.sql'
$tests = Join-Path $PSScriptRoot 'cx1o-disposable-track-assertions.sql'
$started = $false
function Assert-Code {
  if ($LASTEXITCODE -ne 0) { throw ('CX1O Docker/PostgreSQL failure exit ' + $LASTEXITCODE) }
}
try {
  if (!(Test-Path $fixture) -or !(Test-Path $tests)) { throw 'SQL input absent' }
  & docker image inspect $image --format '{{.Id}}' | Out-Null
  Assert-Code
  $existing = @(& docker ps -a --format '{{.Names}}')
  Assert-Code
  if ($existing -contains $container) { throw 'Container name conflict' }
  $password = [guid]::NewGuid().ToString('N') + [guid]::NewGuid().ToString('N')
  $id = & docker run --detach --rm --name $container --network none --memory 1024m --cpus 1 --tmpfs '/var/lib/postgresql/data:rw,size=256m' -e ("POSTGRES_PASSWORD="+$password) --entrypoint docker-entrypoint.sh $image postgres -D /var/lib/postgresql/data
  Assert-Code
  $started = $true
  $password = $null
  if (!$id) { throw 'Container launch failed' }
  $net = (& docker inspect $container --format '{{.HostConfig.NetworkMode}}').Trim()
  Assert-Code
  $ports = (& docker inspect $container --format '{{json .HostConfig.PortBindings}}').Trim()
  Assert-Code
  $mounts = (& docker inspect $container --format '{{json .Mounts}}').Trim()
  Assert-Code
  if ($net -ne 'none' -or $ports -notin @('null','{}') -or $mounts -ne '[]') {
    throw 'Disconnected stage precondition failed'
  }
  Write-Output 'CX1O_DISCONNECTED_NO_PUBLISHED_PORTS_NO_MOUNTS=true'
  $ready = $false
  for ($i=0;$i -lt 50;$i++) {
    & docker exec $container pg_isready -U postgres -d postgres 2>$null | Out-Null
    if ($LASTEXITCODE -eq 0) { $ready=$true; break }
    Start-Sleep -Milliseconds 600
  }
  if (!$ready) { throw 'Disposable PostgreSQL not ready' }
  & docker exec $container createdb -U supabase_admin --template=template0 cx1o_stage | Out-Null
  Assert-Code
  $roles = (@(& docker exec $container psql -X -U supabase_admin -d cx1o_stage -t -A -c "SELECT count(*) FROM pg_roles WHERE rolname IN ('anon','authenticated','service_role')") -join '').Trim()
  Assert-Code
  if ($roles -ne '3') { throw 'Expected isolated Supabase roles absent' }
  & docker cp $fixture ("$($container):/tmp/cx1o-fixture.sql") | Out-Null
  Assert-Code
  & docker cp $tests ("$($container):/tmp/cx1o-tests.sql") | Out-Null
  Assert-Code
  & docker exec $container psql -X -q -U supabase_admin -d cx1o_stage -v ON_ERROR_STOP=1 -f /tmp/cx1o-fixture.sql
  Assert-Code
  Write-Output 'CX1O_SYNTHETIC_FIXTURE_APPLIED_DISCONNECTED=true'
  & docker exec $container psql -X -q -U supabase_admin -d cx1o_stage -v ON_ERROR_STOP=1 -f /tmp/cx1o-tests.sql
  Assert-Code
  Write-Output 'CX1O_SQL_ASSERTIONS_PASS=21'
  $count = (@(& docker exec $container psql -X -U supabase_admin -d cx1o_stage -t -A -c 'SELECT count(*) FROM public.service_bookings') -join '').Trim()
  Assert-Code
  if ($count -ne '108') { throw "Expected 108 synthetic rows, saw $count" }
  Write-Output 'CX1O_SYNTHETIC_ROWS=108_NO_SHARED_SOURCE'
}
finally {
  if ($started) {
    & docker stop --time 3 $container | Out-Null
    Write-Output 'CX1O_DISPOSABLE_CONTAINER_REMOVED=true'
  }
}
