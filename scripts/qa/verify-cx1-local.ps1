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
  Use -ClientOnly for isolated 127.0.0.1:3000/:3300 Web testing without
  starting or verifying paused Technical/Operations services. The final
  status says CX1_CLIENT_RELEASE_QA_PASS, not full-stack PASS.
.EXAMPLE
  .\scripts\qa\verify-cx1-local.ps1 -CheckAndroid
.EXAMPLE
  .\scripts\qa\verify-cx1-local.ps1 -ClientOnly
#>
[CmdletBinding()]
param(
  [string]$HostName = '127.0.0.1',
  [ValidateRange(1, 60)] [int]$TimeoutSeconds = 12,
  [switch]$CheckAndroid,
  [switch]$ClientOnly,
  [ValidateRange(1, 999999)] [int]$MinAndroidBuild = 4009,
  [string]$EmulatorSerial = 'emulator-5554'
)
$ErrorActionPreference = 'Stop'
$failures = New-Object System.Collections.Generic.List[string]
$httpPorts = if ($ClientOnly) { @(3000,3300) } else { @(3000,3100,3200,3300,3400) }
$jsPorts = if ($ClientOnly) { @(3000,3300) } else { @(3000,3100,3300,3400) }
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
    # Record writes a human-readable string; do not accidentally return it as
    # an asset object (which would create false hash/parity PASS messages).
    Record 'FAIL' ("$port /$relative : $($_.Exception.Message)") | Out-Host
    return $null
  }
}
$client = @{}
$technical = @{}
foreach ($port in $httpPorts) {
  try {
    $index = Invoke-WebRequest -Uri ("http://{0}:{1}/" -f $HostName,$port) -UseBasicParsing -TimeoutSec $TimeoutSeconds
    if ([int]$index.StatusCode -ne 200) { throw "HTTP $($index.StatusCode)" }
    Record 'PASS' ("HTTP shell :$port")
  } catch {
    Record 'FAIL' ("HTTP shell :$port : $($_.Exception.Message)")
  }
}
$js = @{}
foreach ($port in $jsPorts) {
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
  foreach ($port in $jsPorts) {
    $asset = Asset $port $image
    if ($null -ne $asset) {
      $digests[$port] = $asset.Hash
      Record 'PASS' ("Category asset :$port /$($image.Split('/')[-1]) bytes=$($asset.Bytes)")
    }
  }
  if ($digests.Count -eq $jsPorts.Count) {
    if (@($digests.Values | Select-Object -Unique).Count -eq 1) {
      $scope = if ($ClientOnly) { 'Client main/staging' } else { 'Shared' }
      Record 'PASS' ("$scope category photo exact-byte parity: $($image.Split('/')[-1])")
    } else { Record 'FAIL' ("Category photo differs across main/staging apps: $image") }
  }
}
if ($CheckAndroid) {
  $adb = Join-Path $env:LOCALAPPDATA 'Android\Sdk\platform-tools\adb.exe'
  if (!(Test-Path -LiteralPath $adb)) { Record 'FAIL' 'ADB executable not found; no installation attempted' }
  else {
    try {
      # ADB can emit a native-command stderr exception if the emulator is
      # missing. That is a legitimate BLOCK, not a crash or a positive PASS.
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
    } catch {
      Record 'FAIL' ("ADB metadata unavailable for $EmulatorSerial : $($_.Exception.Message)")
    }
  }
}
if ($ClientOnly) { Write-Output 'NOTE ClientOnly checks only 3000 and 3300; Technical and Operations are NOT verified.' }
Write-Output 'NOTE Source/HTTP parity is not proof of what an individual Chrome tab has cached/rendered.'
Write-Output 'NOTE Authenticated UI interactions and physical HONOR testing are separate CX1 gates.'
if ($failures.Count -gt 0) {
  $label = if ($ClientOnly) { 'CX1_CLIENT_RELEASE_QA_FAIL' } else { 'CX1_RELEASE_QA_FAIL' }
  Write-Output ("$label count=$($failures.Count)")
  exit 1
}
if ($ClientOnly) { Write-Output 'CX1_CLIENT_RELEASE_QA_PASS' }
else { Write-Output 'CX1_RELEASE_QA_PASS' }
