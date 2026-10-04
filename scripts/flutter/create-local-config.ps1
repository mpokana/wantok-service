$ErrorActionPreference = 'Stop'
$root = Resolve-Path (Join-Path $PSScriptRoot '..\..')
$envFile = Join-Path $root '.env'
$outFile = Join-Path $root 'config\local.json'

if (-not (Test-Path $envFile)) {
  throw "Missing $envFile"
}

$values = @{}
Get-Content $envFile | ForEach-Object {
  $line = $_.Trim()
  if (-not $line -or $line.StartsWith('#') -or -not $line.Contains('=')) { return }
  $parts = $line.Split('=', 2)
  $values[$parts[0].Trim()] = $parts[1].Trim()
}

$url = $values['EXPO_PUBLIC_SUPABASE_URL']
if (-not $url) { $url = $values['SUPABASE_URL'] }
$key = $values['EXPO_PUBLIC_SUPABASE_PUBLISHABLE_KEY']
if (-not $key) { $key = $values['SUPABASE_PUBLISHABLE_KEY'] }

if (-not $url -or -not $key) {
  throw 'Supabase URL/publishable key were not found in .env.'
}

$config = [ordered]@{
  APP_ENV = 'development'
  SUPABASE_URL = $url
  SUPABASE_PUBLISHABLE_KEY = $key
  PUBLIC_WEB_URL = 'http://localhost:8080'
}
$config | ConvertTo-Json | Set-Content -Path $outFile -Encoding utf8
Write-Host "Created $outFile"
