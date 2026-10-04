$ErrorActionPreference = 'Stop'
$root = Resolve-Path (Join-Path $PSScriptRoot '..\..')
$targets = @(
  'packages\wantok_core',
  'packages\wantok_api',
  'packages\wantok_auth',
  'packages\wantok_ui',
  'apps\wantok_app',
  'apps\wantok_admin'
)

foreach ($target in $targets) {
  Write-Host "==> flutter pub get: $target"
  Push-Location (Join-Path $root $target)
  try {
    & flutter pub get
    if ($LASTEXITCODE -ne 0) {
      throw "flutter pub get failed for $target with exit code $LASTEXITCODE"
    }
  }
  finally {
    Pop-Location
  }
}
