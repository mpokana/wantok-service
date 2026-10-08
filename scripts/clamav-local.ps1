param(
  [ValidateSet('Status','Start','Stop','Test')]
  [string]$Action = 'Status'
)

$ErrorActionPreference = 'Stop'
$container = 'wantok-clamav-scanner'
$volume = 'wantok-clamav-signatures'
$docker = (Get-Command docker.exe -ErrorAction SilentlyContinue).Source
if (-not $docker) {
  $docker = Join-Path $env:LOCALAPPDATA 'Programs\DockerDesktop\resources\bin\docker.exe'
}
if (-not (Test-Path $docker)) {
  throw 'Docker CLI not found. Check Docker Desktop before starting a scanner.'
}

if ($Action -eq 'Start') {
  $names = @(& $docker ps -a --filter "name=^/$container$" --format '{{.Names}}')
  if ($LASTEXITCODE -ne 0) { throw 'Cannot enumerate Docker containers.' }
  if ($names -contains $container) {
    & $docker start $container
    if ($LASTEXITCODE -ne 0) { throw 'Existing ClamAV container could not be started.' }
  } else {
    $port = Get-NetTCPConnection -LocalPort 3310 -State Listen -ErrorAction SilentlyContinue
    if ($port) { throw 'TCP port 3310 is already in use. No scanner was created.' }
    & $docker volume create $volume
    if ($LASTEXITCODE -ne 0) { throw 'Cannot create scanner signature volume.' }
    $args = @(
      'run', '--detach', '--name', $container,
      '--publish', '127.0.0.1:3310:3310',
      '--mount', "source=$volume,target=/var/lib/clamav",
      '--memory=4g', '--memory-reservation=2g', '--cpus=2', '--pids-limit=200',
      '--restart=unless-stopped', 'clamav/clamav:stable'
    )
    & $docker @args
    if ($LASTEXITCODE -ne 0) { throw 'ClamAV container could not be started.' }
  }
}
if ($Action -eq 'Stop') {
  & $docker stop $container
  if ($LASTEXITCODE -ne 0) { throw 'Failed to stop only the Wantok scanner.' }
}
if ($Action -eq 'Test') {
  $repo = Split-Path -Parent $PSScriptRoot
  Push-Location $repo
  try {
    & npm.cmd run test:evidence:real
    if ($LASTEXITCODE -ne 0) { throw 'Actual ClamAV detection test failed.' }
  } finally { Pop-Location }
}

Write-Output '=== Wantok ClamAV (application uploads remain disabled) ==='
& $docker ps --filter "name=^/$container$" --format '{{.Names}} {{.Status}} {{.Ports}}'
if ($LASTEXITCODE -ne 0) { throw 'Docker status command failed.' }
$running = @(& $docker ps --filter "name=^/$container$" --format '{{.Names}}')
if ($running -contains $container) {
  & $docker exec $container clamd --version
  if ($LASTEXITCODE -ne 0) { throw 'ClamAV engine version check failed.' }
}
