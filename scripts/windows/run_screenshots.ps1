param(
  [string]$DeviceId = "emulator-5554"
)

$ErrorActionPreference = "Stop"

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..\..")
$appDir = Join-Path $repoRoot "app"
$screenshotsDir = Join-Path $appDir "screenshots\current"

if (-not (Test-Path $screenshotsDir)) {
  New-Item -ItemType Directory -Path $screenshotsDir -Force | Out-Null
}

Get-ChildItem -Path $screenshotsDir -Filter *.png -File -ErrorAction SilentlyContinue | Remove-Item -Force

Push-Location $appDir
try {
  flutter pub get
  flutter drive --driver=test_driver/screenshots_driver.dart --target=integration_test/screenshots_flow_test.dart -d $DeviceId
  dart run tool/validate_screenshots.dart
  dart run tool/generate_screenshot_index.dart
} finally {
  Pop-Location
}

