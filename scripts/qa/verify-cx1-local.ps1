#requires -Version 5.1
<#
.SYNOPSIS
  Read-only CX1 local release parity and static-media acceptance gate.
.DESCRIPTION
  Verifies Client and Technical Control static builds, staging parity, shared
  category photos, presence of the three CX1 refresh affordances, and Operations
  shell availability. Optional ADB check reads package metadata only.
  Does not connect to authenticated APIs, inspect Chrome profiles, write data,
  change categories, install APKs or operate bookings, payments or messages.
  Live browser rendering and refresh-button interaction require separate QA.
.EXAMPLE
  .\scripts\qa\verify-cx1-local.ps1 -CheckAndroid
#>
[CmdletBinding()]
param(
  [string]$HostName = '127.0.0.1',
  [ValidateRange(1, 60)] [int]$TimeoutSeconds = 12,
  [switch]$CheckAndroid,
  [ValidateRange(1, 999999)] [int]$MinAndroidBuild = 4009,
  [string]$EmulatorSerial = 'emulator-5554'
)
$ErrorActionPreference = 'Stop'
$failures = New-Object System.Collections.Generic.List[string]
function Record([string]$kind,[string]$detail) {
  Write-Output ('{0} {1}' -f $kind,$detail)
  if ($kind -eq 'FAIL') { $script:failures.Add($detail) }
}
function Asset([int]$port, [string]$relative) {
  $uri = ('http://{0}:{1}/{2}' -f $HostName,$port,$relative)
  try {
    $response = Invoke-WebRequest -Uri $uri -UseBasicParsing -TimeoutSec $TimeoutSeconds
    if ([int]$response.StatusCode -ne 200) { throw "Unexpected HTTP $($response.StatusCode)" }
    if ($relative -eq 'main.dart.js') {
      $bytes = [System.Text.Encoding]::UTF8.GetBytes([string]$response.Content)
    } elseif ($relative -eq '') {
      $bytes = [System.Text.Encoding]::UTF8.GetBytes([string]$response.Content)
    } else {
      $bytes = [byte[]]$response.Content
    }
    if ($bytes.Length -le 0) { throw 'Empty asset response' }
    $hashing = [System.Security.Cryptography.SHA256]::Create()
    try { $digest = [BitConverter]::ToString($hashing.ComputeHash($bytes)).Replace('-', '') }
    finally { $hashing.Dispose() }
    return [pscustomobject]@{ Hash=$digest; Bytes=$bytes.Length; Response=$response }
  } catch {
    Record 'FAIL' ("$port /$relative : $($_.Exception.Message)")
    return $null
  }
}
$client = @{}
$technical = @{}
foreach ($port in @(3000, 3100, 3200, 3300, 3400)) {
  try {
    $index = Invoke-WebRequest -Uri ("http://{0}:{1}/" -f $HostName,$port) -UseBasicParsing -TimeoutSec $TimeoutSeconds
    if ([int]$index.StatusCode -ne 200) { throw "HTTP $($index.StatusCode)" }
    Record 'PASS' ("HTTP shell :$port")
  } catch {
    Record 'FAIL' ("HTTP shell :$port : $($_.Exception.Message)")
  }
}
$js = @{}
foreach ($port in @(3000,3100,3300,3400)) {
  $item = Asset $port 'main.dart.js'
  if ($null -ne $item) {
    $js[$port] = $item
    Record 'PASS' ("JS :$port bytes=$($item.Bytes) sha256=$($item.Hash)")
  }
}
if ($js.ContainsKey(3000) -and $js.ContainsKey(3300)) {
  if ($js[3000].Hash -eq $js[3300].Hash) { Record 'PASS' 'Client main/staging JS parity 3000=3300' }
  else { Record 'FAIL' 'Client main/staging JS differ' }
}
if ($js.ContainsKey(3100) -and $js.ContainsKey(3400)) {
  if ($js[3100].Hash -eq $js[3400].Hash) { Record 'PASS' 'Technical main/staging JS parity 3100=3400' }
  else { Record 'FAIL' 'Technical main/staging JS differ' }
}
if ($js.ContainsKey(3000)) {
  $compiled = [string]$js[3000].Response.Content
  foreach ($caption in @('Refresh saved items','Refresh Inbox','Refresh activity')) {
    if ($compiled.Contains($caption)) { Record 'PASS' ("Client compiled action: $caption") }
    else { Record 'FAIL' ("Client JS missing compiled action: $caption") }
  }
}
$images = @(
  'assets/packages/wantok_ui/assets/images/categories/category_taxi.webp',
  'assets/packages/wantok_ui/assets/images/reference/services_public_photo.jpg'
)
foreach ($image in $images) {
  $digests = @{}
  foreach ($port in @(3000,3100,3300,3400)) {
    $asset = Asset $port $image
    if ($null -ne $asset) {
      $digests[$port] = $asset.Hash
      Record 'PASS' ("Category asset :$port /$($image.Split('/')[-1]) bytes=$($asset.Bytes)")
    }
  }
  if ($digests.Count -eq 4) {
    if (@($digests.Values | Select-Object -Unique).Count -eq 1) {
      Record 'PASS' ("Shared category photo exact-byte parity: $($image.Split('/')[-1])")
    } else { Record 'FAIL' ("Category photo differs across main/staging apps: $image") }
  }
}
if ($CheckAndroid) {
  $adb = Join-Path $env:LOCALAPPDATA 'Android\Sdk\platform-tools\adb.exe'
  if (!(Test-Path -LiteralPath $adb)) { Record 'FAIL' 'ADB executable not found; no installation attempted' }
  else {
    $package = & $adb -s $EmulatorSerial shell dumpsys package io.wantok.service 2>&1
    if ($LASTEXITCODE -ne 0) { Record 'FAIL' "ADB metadata read failed: $EmulatorSerial" }
    else {
      $match = [regex]::Match(($package -join "`n"), 'versionCode=(\d+)')
      if (!$match.Success) { Record 'FAIL' "Unable to parse Android app version: $EmulatorSerial" }
      elseif ([int]$match.Groups[1].Value -lt $MinAndroidBuild) {
        Record 'FAIL' ("Android app too old: $($match.Groups[1].Value) < $MinAndroidBuild")
      } else {
        Record 'PASS' ("Android existing package versionCode=$($match.Groups[1].Value) on $EmulatorSerial")
      }
    }
  }
}
Write-Output 'NOTE Source/HTTP parity is not proof of what an individual Chrome tab has cached/rendered.'
Write-Output 'NOTE Authenticated UI interactions and physical HONOR testing are separate CX1 gates.'
if ($failures.Count -gt 0) {
  Write-Output ("CX1_RELEASE_QA_FAIL count=$($failures.Count)")
  exit 1
}
Write-Output 'CX1_RELEASE_QA_PASS'
