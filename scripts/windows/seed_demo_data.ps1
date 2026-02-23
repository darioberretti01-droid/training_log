param(
  [string]$DeviceId = "emulator-5554"
)

$ErrorActionPreference = "Stop"

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..\..")
$appDir = Join-Path $repoRoot "app"

Push-Location $appDir
try {
  flutter pub get
  flutter test integration_test/seed_demo_data_test.dart -d $DeviceId
} finally {
  Pop-Location
}

