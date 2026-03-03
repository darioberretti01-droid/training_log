param(
  [Parameter(Position = 0)]
  [ValidateSet("start", "restart", "stop", "status", "logs")]
  [string]$Command = "status",
  [string]$EmulatorId = "Medium_Phone_API_36.1",
  [string]$AppDir = "app",
  [switch]$Fresh,
  [switch]$Foreground,
  [switch]$NoPubGet,
  [string]$DeviceId,
  [int]$Tail = 80
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

$PackageId = "com.dario.training.training_log_app"
$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
$ResolvedAppDir = Join-Path $RepoRoot $AppDir
$RunnerDir = Join-Path $RepoRoot ".devrunner"
$StatePath = Join-Path $RunnerDir "state.json"
$PidPath = Join-Path $RunnerDir "flutter_run.pid"
$LatestLogPath = Join-Path $RunnerDir "dev_app_latest.log"

if (-not (Test-Path -LiteralPath $ResolvedAppDir)) {
  throw "App directory not found: $ResolvedAppDir"
}

function Write-Info([string]$Message) {
  Write-Host "[dev-app] $Message" -ForegroundColor Cyan
}

function Write-WarnMsg([string]$Message) {
  Write-Host "[dev-app] $Message" -ForegroundColor Yellow
}

function Write-ErrorMsg([string]$Message) {
  Write-Host "[dev-app] $Message" -ForegroundColor Red
}

function Ensure-RunnerDir() {
  if (-not (Test-Path -LiteralPath $RunnerDir)) {
    New-Item -ItemType Directory -Path $RunnerDir -Force | Out-Null
  }
}

function New-StateObject() {
  return [ordered]@{
    version = 1
    packageId = $PackageId
    appDir = $ResolvedAppDir
    emulatorId = $EmulatorId
    latestLog = $LatestLogPath
    active = [ordered]@{
      pid = $null
      startedAt = $null
      mode = $null
      deviceId = $null
      fresh = $false
      rotatedLog = $null
    }
  }
}

function ConvertTo-HashtableRecursive($InputObject) {
  if ($null -eq $InputObject) {
    return $null
  }

  if ($InputObject -is [hashtable]) {
    $map = @{}
    foreach ($key in $InputObject.Keys) {
      $map[$key] = ConvertTo-HashtableRecursive $InputObject[$key]
    }
    return $map
  }

  if ($InputObject -is [System.Collections.IDictionary]) {
    $map = @{}
    foreach ($entry in $InputObject.GetEnumerator()) {
      $map[[string]$entry.Key] = ConvertTo-HashtableRecursive $entry.Value
    }
    return $map
  }

  if (($InputObject -is [System.Collections.IEnumerable]) -and -not ($InputObject -is [string])) {
    $list = @()
    foreach ($item in $InputObject) {
      $list += ,(ConvertTo-HashtableRecursive $item)
    }
    return $list
  }

  if ($InputObject -is [psobject]) {
    $map = @{}
    foreach ($property in $InputObject.PSObject.Properties) {
      $map[$property.Name] = ConvertTo-HashtableRecursive $property.Value
    }
    return $map
  }

  return $InputObject
}

function Save-State([hashtable]$State) {
  Ensure-RunnerDir
  $json = $State | ConvertTo-Json -Depth 8
  Set-Content -LiteralPath $StatePath -Value $json -Encoding UTF8
}

function Get-State() {
  Ensure-RunnerDir
  if (-not (Test-Path -LiteralPath $StatePath)) {
    $state = New-StateObject
    Save-State -State $state
    return $state
  }

  try {
    $raw = Get-Content -LiteralPath $StatePath -Raw
    if ([string]::IsNullOrWhiteSpace($raw)) {
      $state = New-StateObject
      Save-State -State $state
      return $state
    }
    $parsed = $raw | ConvertFrom-Json
    $obj = ConvertTo-HashtableRecursive $parsed
    if (-not $obj.ContainsKey("active")) {
      $obj.active = [ordered]@{
        pid = $null
        startedAt = $null
        mode = $null
        deviceId = $null
        fresh = $false
        rotatedLog = $null
      }
    }
    if (-not $obj.ContainsKey("latestLog")) {
      $obj.latestLog = $LatestLogPath
    }
    return $obj
  } catch {
    Write-WarnMsg "State file unreadable. Resetting state."
    $state = New-StateObject
    Save-State -State $state
    return $state
  }
}

function Clear-ActiveState([hashtable]$State) {
  $State.active.pid = $null
  $State.active.startedAt = $null
  $State.active.mode = $null
  $State.active.deviceId = $null
  $State.active.fresh = $false
  $State.active.rotatedLog = $null
  Save-State -State $State
  if (Test-Path -LiteralPath $PidPath) {
    Remove-Item -LiteralPath $PidPath -Force -ErrorAction SilentlyContinue
  }
}

function Set-ActiveState(
  [hashtable]$State,
  [Nullable[int]]$RunnerProcessId,
  [string]$Mode,
  [string]$DeviceIdValue,
  [bool]$FreshValue,
  [string]$RotatedLog
) {
  $onlineIds = @(Get-AdbDeviceIds)
  $normalizedDeviceId = Normalize-DeviceId -Candidate $DeviceIdValue -OnlineIds $onlineIds
  if ([string]::IsNullOrWhiteSpace($normalizedDeviceId)) {
    $normalizedDeviceId = $DeviceIdValue
  }

  $State.active.pid = $RunnerProcessId
  $State.active.startedAt = (Get-Date).ToString("s")
  $State.active.mode = $Mode
  $State.active.deviceId = $normalizedDeviceId
  $State.active.fresh = $FreshValue
  $State.active.rotatedLog = $RotatedLog
  $State.latestLog = $LatestLogPath
  Save-State -State $State
  if ($RunnerProcessId -ne $null) {
    Set-Content -LiteralPath $PidPath -Value ([string]$RunnerProcessId) -Encoding UTF8
  } elseif (Test-Path -LiteralPath $PidPath) {
    Remove-Item -LiteralPath $PidPath -Force -ErrorAction SilentlyContinue
  }
}

function Has-Command([string]$Name) {
  return $null -ne (Get-Command $Name -ErrorAction SilentlyContinue)
}

function Test-ProcessAlive([Nullable[int]]$RunnerProcessId) {
  if ($RunnerProcessId -eq $null) {
    return $false
  }
  $proc = Get-Process -Id $RunnerProcessId -ErrorAction SilentlyContinue
  return $null -ne $proc
}

function Ensure-Flutter() {
  if (-not (Has-Command "flutter")) {
    throw "Flutter is not available in PATH."
  }
}

function Get-AdbDeviceIds() {
  if (-not (Has-Command "adb")) {
    return @()
  }

  $originalErrorPreference = $ErrorActionPreference
  $ErrorActionPreference = "Continue"
  try {
    $output = @(& adb devices 2>&1)
    $exitCode = $LASTEXITCODE

    $outputText = ($output | ForEach-Object { [string]$_ }) -join "`n"
    $daemonBooting = $outputText -match "daemon not running|daemon started successfully"

    if ($daemonBooting -or $exitCode -ne 0) {
      & adb start-server 2>&1 | Out-Null
      $output = @(& adb devices 2>&1)
      $exitCode = $LASTEXITCODE
    }
  } finally {
    $ErrorActionPreference = $originalErrorPreference
  }

  if ($exitCode -ne 0) {
    return @()
  }

  $result = @()
  foreach ($line in $output) {
    $normalized = ([string]$line).Trim()
    if ($normalized -match "^([^\s]+)\s+device$") {
      $result += $matches[1]
    }
  }
  return @($result)
}

function Get-FlutterAndroidDeviceIds() {
  if (-not (Has-Command "flutter")) {
    return @()
  }

  try {
    $raw = & flutter devices --machine 2>$null | Out-String
    if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($raw)) {
      return @()
    }
    $devices = $raw | ConvertFrom-Json
    $result = @()
    foreach ($device in $devices) {
      if ($null -eq $device) {
        continue
      }
      $platform = [string]$device.targetPlatform
      if ($platform -like "android*") {
        $result += [string]$device.id
      }
    }
    return @($result)
  } catch {
    return @()
  }
}

function Get-OnlineAndroidDeviceIds() {
  $adbIds = @(Get-AdbDeviceIds)
  if ($adbIds.Count -gt 0) {
    return @($adbIds)
  }
  if (Has-Command "adb") {
    return @()
  }
  Write-WarnMsg "adb not found. Falling back to flutter device probing."
  return @(Get-FlutterAndroidDeviceIds)
}

function Select-PreferredDevice([string[]]$Ids) {
  $Ids = @($Ids)
  if ($Ids.Count -eq 0) {
    return $null
  }
  if (-not [string]::IsNullOrWhiteSpace($DeviceId)) {
    if ($Ids -contains $DeviceId) {
      return $DeviceId
    }
    throw "Requested device '$DeviceId' is not connected."
  }

  $emulator = $Ids | Where-Object { $_ -like "emulator-*" } | Select-Object -First 1
  if ($null -ne $emulator -and $emulator -ne "") {
    return $emulator
  }
  return $Ids[0]
}

function Normalize-DeviceId([string]$Candidate, [string[]]$OnlineIds) {
  if ([string]::IsNullOrWhiteSpace($Candidate)) {
    return $null
  }

  $trimmed = $Candidate.Trim()
  $online = @($OnlineIds)

  if ($online.Count -eq 0) {
    return $trimmed
  }
  if ($online -contains $trimmed) {
    return $trimmed
  }

  foreach ($onlineId in $online) {
    if ($trimmed.Contains($onlineId)) {
      return $onlineId
    }
  }

  $emulatorMatch = [Regex]::Match($trimmed, "emulator-\d+")
  if ($emulatorMatch.Success) {
    $matchedId = $emulatorMatch.Value
    if ($online -contains $matchedId) {
      return $matchedId
    }
  }

  return $null
}

function Wait-ForAndroidBoot([int]$TimeoutSeconds = 240) {
  if (-not (Has-Command "adb")) {
    $deadline = (Get-Date).AddSeconds($TimeoutSeconds)
    while ((Get-Date) -lt $deadline) {
      $ids = @(Get-FlutterAndroidDeviceIds)
      if ($ids.Count -gt 0) {
        return
      }
      Start-Sleep -Seconds 3
    }
    throw "Emulator launch timeout. Try: flutter emulators --launch $EmulatorId"
  }

  $deadline = (Get-Date).AddSeconds($TimeoutSeconds)
  while ((Get-Date) -lt $deadline) {
    $ids = @(Get-AdbDeviceIds)
    $target = $ids | Where-Object { $_ -like "emulator-*" } | Select-Object -First 1
    if ($null -eq $target -or $target -eq "") {
      Start-Sleep -Seconds 2
      continue
    }

    $boot = (& adb -s $target shell getprop sys.boot_completed 2>$null | Out-String).Trim()
    if ($boot -eq "1") {
      return
    }
    Start-Sleep -Seconds 2
  }

  throw "Emulator launch timeout. Try: flutter emulators --launch $EmulatorId"
}

function Ensure-DeviceOnline() {
  $ids = @(Get-OnlineAndroidDeviceIds)
  if ($ids.Count -eq 0) {
    Write-Info "No Android device detected. Launching emulator '$EmulatorId'."
    Ensure-Flutter
    & flutter emulators --launch $EmulatorId
    if ($LASTEXITCODE -ne 0) {
      throw "Failed to launch emulator '$EmulatorId'. Try manually: flutter emulators --launch $EmulatorId"
    }
    Wait-ForAndroidBoot
    $ids = @(Get-OnlineAndroidDeviceIds)
  }

  if ($ids.Count -eq 0) {
    throw "No Android device is online. Start an emulator manually and retry."
  }

  return (Select-PreferredDevice -Ids $ids)
}

function Invoke-AdbForceStop([string]$TargetDevice) {
  if (-not (Has-Command "adb")) {
    return
  }
  $online = @(Get-AdbDeviceIds)
  if ($online.Count -eq 0) {
    return
  }
  $resolvedDevice = Normalize-DeviceId -Candidate $TargetDevice -OnlineIds $online
  if ([string]::IsNullOrWhiteSpace($resolvedDevice)) {
    & adb shell am force-stop $PackageId 2>$null 1>$null
  } else {
    & adb -s $resolvedDevice shell am force-stop $PackageId 2>$null 1>$null
  }
}

function Invoke-AdbUninstall([string]$TargetDevice) {
  if (-not (Has-Command "adb")) {
    return
  }
  $online = @(Get-AdbDeviceIds)
  if ($online.Count -eq 0) {
    return
  }
  $resolvedDevice = Normalize-DeviceId -Candidate $TargetDevice -OnlineIds $online
  if ([string]::IsNullOrWhiteSpace($resolvedDevice)) {
    & adb uninstall $PackageId 2>$null 1>$null
  } else {
    & adb -s $resolvedDevice uninstall $PackageId 2>$null 1>$null
  }
}

function Get-AppPid([string]$TargetDevice) {
  if (-not (Has-Command "adb")) {
    return $null
  }
  try {
    $online = @(Get-AdbDeviceIds)
    $resolvedDevice = Normalize-DeviceId -Candidate $TargetDevice -OnlineIds $online
    $processPid = ""
    if ([string]::IsNullOrWhiteSpace($resolvedDevice)) {
      $processPid = (& adb shell pidof $PackageId 2>$null | Out-String).Trim()
    } else {
      $processPid = (& adb -s $resolvedDevice shell pidof $PackageId 2>$null | Out-String).Trim()
    }
    if ([string]::IsNullOrWhiteSpace($processPid)) {
      return $null
    }
    return $processPid
  } catch {
    return $null
  }
}

function Stop-TrackedProcess([hashtable]$State) {
  $runnerPid = $State.active.pid
  if ($runnerPid -ne $null -and (Test-ProcessAlive -RunnerProcessId $runnerPid)) {
    Write-Info "Stopping tracked runner process PID=$runnerPid"
    Stop-Process -Id $runnerPid -Force -ErrorAction SilentlyContinue
    Start-Sleep -Milliseconds 500
  }
}

function Stop-OrphanRunnerProcesses() {
  $escapedAppPath = [Regex]::Escape($ResolvedAppDir)
  $procs = Get-CimInstance Win32_Process -ErrorAction SilentlyContinue | Where-Object {
    ($_.CommandLine -match "flutter\s+run") -and
    ($_.CommandLine -match $escapedAppPath)
  }

  foreach ($proc in $procs) {
    $pidValue = [int]$proc.ProcessId
    Write-Info "Stopping orphan runner process PID=$pidValue"
    Stop-Process -Id $pidValue -Force -ErrorAction SilentlyContinue
  }
}

function Invoke-Start([switch]$IsRestart) {
  $state = Get-State
  $statePid = $state.active.pid
  if ($statePid -ne $null -and -not (Test-ProcessAlive -RunnerProcessId $statePid)) {
    Write-WarnMsg "Tracked PID is stale. Clearing runner state."
    Clear-ActiveState -State $state
    $state = Get-State
  }

  if (-not $IsRestart -and $state.active.pid -ne $null -and (Test-ProcessAlive -RunnerProcessId $state.active.pid)) {
    Write-WarnMsg "Runner already active. Treating 'start' as 'restart'."
    Invoke-Restart
    return
  }

  Ensure-Flutter
  $targetDevice = Ensure-DeviceOnline
  $targetDevice = Normalize-DeviceId -Candidate $targetDevice -OnlineIds @(Get-OnlineAndroidDeviceIds)
  if ([string]::IsNullOrWhiteSpace($targetDevice)) {
    throw "No target device resolved."
  }
  Write-Info "Using device: $targetDevice"

  if ($Fresh) {
    Write-Info "Executing fresh deploy path."
    Invoke-AdbForceStop -TargetDevice $targetDevice
    Invoke-AdbUninstall -TargetDevice $targetDevice
  }

  Push-Location $ResolvedAppDir
  try {
    if ($Fresh) {
      & flutter clean
      if ($LASTEXITCODE -ne 0) {
        throw "flutter clean failed."
      }
      & flutter pub get
      if ($LASTEXITCODE -ne 0) {
        throw "flutter pub get failed."
      }
    } elseif (-not $NoPubGet) {
      & flutter pub get
      if ($LASTEXITCODE -ne 0) {
        throw "flutter pub get failed."
      }
    }

    if ($Foreground) {
      Write-Info "Starting app in foreground."
      Set-ActiveState -State $state -RunnerProcessId $null -Mode "foreground" -DeviceIdValue $targetDevice -FreshValue ([bool]$Fresh) -RotatedLog ""
      try {
        & flutter run -d $targetDevice
      } finally {
        $latestState = Get-State
        Clear-ActiveState -State $latestState
      }
      return
    }

    Ensure-RunnerDir
    if (Test-Path -LiteralPath $LatestLogPath) {
      Remove-Item -LiteralPath $LatestLogPath -Force -ErrorAction SilentlyContinue
    }
    New-Item -ItemType File -Path $LatestLogPath -Force | Out-Null
    $stamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $rotatedLog = Join-Path $RunnerDir "dev_app_$stamp.log"
    New-Item -ItemType File -Path $rotatedLog -Force | Out-Null

    $innerScript = @"
Set-Location -LiteralPath '$ResolvedAppDir'
flutter run -d '$targetDevice' 2>&1 | Tee-Object -FilePath '$LatestLogPath' -Append | Tee-Object -FilePath '$rotatedLog' -Append
"@
    $runner = Start-Process -FilePath "powershell.exe" `
      -ArgumentList @("-NoProfile", "-ExecutionPolicy", "Bypass", "-Command", $innerScript) `
      -WindowStyle Hidden `
      -PassThru

    Set-ActiveState -State $state -RunnerProcessId $runner.Id -Mode "background" -DeviceIdValue $targetDevice -FreshValue ([bool]$Fresh) -RotatedLog $rotatedLog
    Write-Info "Background runner started (PID=$($runner.Id))."
    Write-Info "Log file: $LatestLogPath"
    Start-Sleep -Seconds 7
    $appPid = Get-AppPid -TargetDevice $targetDevice
    if ($null -eq $appPid) {
      Write-WarnMsg "App process check failed or app not ready yet. Inspect logs with: scripts\\windows\\dev_app.ps1 logs"
    } else {
      Write-Info "App process PID on device: $appPid"
    }
  } finally {
    Pop-Location
  }
}

function Invoke-Stop() {
  $state = Get-State
  Stop-TrackedProcess -State $state
  Stop-OrphanRunnerProcesses

  $onlineIds = @(Get-AdbDeviceIds)
  $deviceForStop = Normalize-DeviceId -Candidate ([string]$state.active.deviceId) -OnlineIds $onlineIds
  if ([string]::IsNullOrWhiteSpace($deviceForStop) -and $onlineIds.Count -gt 0) {
    $deviceForStop = Select-PreferredDevice -Ids $onlineIds
  }
  Invoke-AdbForceStop -TargetDevice $deviceForStop
  Clear-ActiveState -State $state
  Write-Info "Runner stopped."
}

function Invoke-Restart() {
  Write-Info "Restarting app."
  Invoke-Stop
  Invoke-Start -IsRestart
}

function Invoke-Status() {
  $state = Get-State
  $flutterOk = Has-Command "flutter"
  $adbOk = Has-Command "adb"
  $deviceIds = @(Get-OnlineAndroidDeviceIds)
  $activePid = $state.active.pid
  $runnerAlive = Test-ProcessAlive -RunnerProcessId $activePid

  if ($activePid -ne $null -and -not $runnerAlive) {
    Write-WarnMsg "Tracked PID is stale. Clearing runner state."
    Clear-ActiveState -State $state
    $state = Get-State
    $activePid = $state.active.pid
    $runnerAlive = Test-ProcessAlive -RunnerProcessId $activePid
  }

  $activeDevice = Normalize-DeviceId -Candidate ([string]$state.active.deviceId) -OnlineIds $deviceIds
  if ([string]::IsNullOrWhiteSpace($activeDevice) -and $deviceIds.Count -gt 0) {
    $activeDevice = Select-PreferredDevice -Ids $deviceIds
  }
  if ($activeDevice -ne $state.active.deviceId -and -not [string]::IsNullOrWhiteSpace($activeDevice)) {
    $state.active.deviceId = $activeDevice
    Save-State -State $state
  }
  $appPid = Get-AppPid -TargetDevice $activeDevice

  Write-Host ""
  Write-Host "=== Dev App Status ===" -ForegroundColor Green
  Write-Host ("flutter available : {0}" -f $flutterOk)
  Write-Host ("adb available     : {0}" -f $adbOk)
  Write-Host ("devices online    : {0}" -f ($(if ($deviceIds.Count -eq 0) { "none" } else { ($deviceIds -join ", ") })))
  Write-Host ("tracked runner pid: {0}" -f $(if ($activePid -eq $null) { "none" } else { $activePid }))
  Write-Host ("runner alive      : {0}" -f $runnerAlive)
  Write-Host ("active device     : {0}" -f $(if ([string]::IsNullOrWhiteSpace($activeDevice)) { "none" } else { $activeDevice }))
  Write-Host ("app pid           : {0}" -f $(if ($null -eq $appPid) { "not running" } else { $appPid }))
  Write-Host ("run mode          : {0}" -f $(if ($null -eq $state.active.mode) { "none" } else { $state.active.mode }))
  Write-Host ("last start        : {0}" -f $(if ($null -eq $state.active.startedAt) { "n/a" } else { $state.active.startedAt }))
  Write-Host ("latest log        : {0}" -f $LatestLogPath)
  if ($state.active.rotatedLog) {
    Write-Host ("rotated log       : {0}" -f $state.active.rotatedLog)
  }
  Write-Host ""
}

function Invoke-Logs() {
  if (-not (Test-Path -LiteralPath $LatestLogPath)) {
    Write-WarnMsg "No log file found yet at $LatestLogPath"
    return
  }
  Write-Info "Tailing logs from $LatestLogPath"
  Get-Content -LiteralPath $LatestLogPath -Tail $Tail -Wait
}

switch ($Command) {
  "start" {
    Invoke-Start
    break
  }
  "restart" {
    Invoke-Restart
    break
  }
  "stop" {
    Invoke-Stop
    break
  }
  "status" {
    Invoke-Status
    break
  }
  "logs" {
    Invoke-Logs
    break
  }
  default {
    throw "Unsupported command: $Command"
  }
}
