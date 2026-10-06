$ErrorActionPreference = 'Stop'
$root = Resolve-Path (Join-Path $PSScriptRoot '..\..')
$targets = @(
  'packages\wantok_core',
  'packages\wantok_api',
  'packages\wantok_auth',
  'packages\wantok_ui',
  'apps\wantok_app',
  'apps\wantok_admin',
  'apps\wantok_tech'
)

function Invoke-FlutterChecked {
  param(
    [Parameter(Mandatory = $true)][string]$WorkingDirectory,
    [Parameter(Mandatory = $true)][string[]]$Arguments
  )

  Push-Location $WorkingDirectory
  try {
    & flutter @Arguments
    if ($LASTEXITCODE -ne 0) {
      throw "flutter $($Arguments -join ' ') failed in $WorkingDirectory with exit code $LASTEXITCODE"
    }
  }
  finally {
    Pop-Location
  }
}

foreach ($target in $targets) {
  Write-Host "==> flutter analyze: $target"
  Invoke-FlutterChecked -WorkingDirectory (Join-Path $root $target) -Arguments @('analyze')
}

Write-Host '==> flutter test: apps\wantok_app'
Invoke-FlutterChecked -WorkingDirectory (Join-Path $root 'apps\wantok_app') -Arguments @('test')

Write-Host '==> flutter test: apps\wantok_admin'
Invoke-FlutterChecked -WorkingDirectory (Join-Path $root 'apps\wantok_admin') -Arguments @('test')

Write-Host '==> flutter test: apps\wantok_tech'
Invoke-FlutterChecked -WorkingDirectory (Join-Path $root 'apps\wantok_tech') -Arguments @('test')
