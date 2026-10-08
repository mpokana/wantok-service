# Start the existing Wantok Services Android Virtual Device on EAGLT02.
# Preserves AVD userdata, installed apps, account sign-in and snapshots.
# Usage: powershell -NoProfile -ExecutionPolicy Bypass -File .\Start-Wantok-Emulator.ps1
param(
    [string]$AvdName = 'Medium_Phone_API_36.1',
    [int]$BootTimeoutSeconds = 240,
    [switch]$SkipWantokApp
)

$ErrorActionPreference = 'Stop'
$sdk = Join-Path $env:LOCALAPPDATA 'Android\Sdk'
$adb = Join-Path $sdk 'platform-tools\adb.exe'
$emulator = Join-Path $sdk 'emulator\emulator.exe'

if (-not (Test-Path $adb)) { throw "ADB not found at $adb" }
if (-not (Test-Path $emulator)) { throw "Emulator not found at $emulator" }

$availableAvds = @(& $emulator -list-avds 2>&1)
if ($LASTEXITCODE -ne 0 -or $AvdName -notin $availableAvds) {
    throw "AVD '$AvdName' is not installed. Found: $($availableAvds -join ', ')"
}

Write-Host "Wantok Services emulator: $AvdName" -ForegroundColor Cyan
# This laptop has one configured AVD. Detect existing emulator processes by
# process name: Windows may hide their command line across login sessions.
$running = @(Get-Process emulator, 'qemu-system-x86_64' -ErrorAction SilentlyContinue)

if ($running.Count -eq 0) {
    Write-Host 'Starting the existing AVD in a window, without wiping user data...'
    $currentSession = (Get-Process -Id $PID).SessionId
    $desktopSession = (Get-Process explorer -ErrorAction SilentlyContinue |
        Where-Object { $_.SessionId -ne 0 } |
        Select-Object -First 1 -ExpandProperty SessionId)
    if ($null -ne $desktopSession -and $currentSession -ne $desktopSession) {
        # Remote Commander sometimes launches child processes in Session 0,
        # invisible to the signed-in desktop. The pre-registered interactive
        # task starts this same AVD in Mansfield's console session instead.
        $taskName = 'Wantok Services Emulator UI'
        $task = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue
        if (-not $task) {
            throw "Interactive task '$taskName' missing. Run the Desktop shortcut instead."
        }
        Start-ScheduledTask -TaskName $taskName -ErrorAction Stop
        Write-Host 'Launched through the interactive Windows task.'
    } else {
        $arguments = @(
            '-avd', $AvdName,
            '-no-snapshot-load',
            '-no-snapshot-save',
            '-gpu', 'host',
            '-no-audio',
            '-no-boot-anim'
        )
        $p = Start-Process -FilePath $emulator -ArgumentList $arguments -WorkingDirectory (Split-Path $emulator) -PassThru
        Write-Host "Emulator process started (PID $($p.Id))."
    }
} else {
    Write-Host 'Emulator is already running; reusing the existing session.'
}

$deadline = (Get-Date).AddSeconds($BootTimeoutSeconds)
$deviceSerial = $null
do {
    $deviceList = @(& $adb devices 2>$null)
    $deviceSerial = ($deviceList |
        Select-String '^emulator-\d+\s+device(\s|$)' |
        Select-Object -First 1 |
        ForEach-Object { ($_.Line -split '\s+')[0] })
    if ($deviceSerial) {
        $booted = ((& $adb -s $deviceSerial shell getprop sys.boot_completed 2>$null) -join '').Trim()
        if ($booted -eq '1') { break }
    }
    Start-Sleep -Seconds 3
} while ((Get-Date) -lt $deadline)

if (-not $deviceSerial -or $booted -ne '1') {
    throw "Android did not finish booting within $BootTimeoutSeconds seconds. The AVD was not wiped or reset."
}

Write-Host "Android boot complete ($deviceSerial)." -ForegroundColor Green
if (-not $SkipWantokApp) {
    $packagePath = ((& $adb -s $deviceSerial shell pm path io.wantok.service 2>$null) -join '').Trim()
    if ($packagePath -notmatch 'package:') {
        Write-Warning 'Wantok Services is not installed on this AVD. Emulator is running.'
    } else {
        & $adb -s $deviceSerial shell am start -n 'io.wantok.service/.MainActivity' | Out-Host
        if ($LASTEXITCODE -ne 0) { throw 'Android started, but Wantok Services could not be launched.' }
        Write-Host 'Wantok Services launched.' -ForegroundColor Green
    }
}
Write-Host 'The emulator window should be visible on EAGLT02.' -ForegroundColor Green
