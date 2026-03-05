param(
  [Parameter(Position = 0)]
  [ValidateSet("check", "update", "major")]
  [string]$Mode = "update",
  [string]$AppDir = "app"
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
$ResolvedAppDir = Join-Path $RepoRoot $AppDir

if (-not (Test-Path -LiteralPath $ResolvedAppDir)) {
  throw "App directory not found: $ResolvedAppDir"
}

function Write-Step([string]$Message) {
  Write-Host "[deps] $Message" -ForegroundColor Cyan
}

function Invoke-CommandChecked([scriptblock]$Command, [string]$Description) {
  Write-Step $Description
  & $Command
  if ($LASTEXITCODE -ne 0) {
    throw "$Description failed with exit code $LASTEXITCODE"
  }
}

if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) {
  throw "Flutter is not available in PATH."
}

Push-Location $ResolvedAppDir
try {
  Invoke-CommandChecked -Description "Running flutter pub get" -Command { flutter pub get }

  switch ($Mode) {
    "check" {
      Invoke-CommandChecked -Description "Checking outdated dependencies" -Command { flutter pub outdated }
    }
    "update" {
      Invoke-CommandChecked -Description "Upgrading resolvable dependencies" -Command { flutter pub upgrade }
      Invoke-CommandChecked -Description "Checking remaining outdated dependencies" -Command { flutter pub outdated }
    }
    "major" {
      Invoke-CommandChecked -Description "Upgrading with major versions" -Command { flutter pub upgrade --major-versions }
      Invoke-CommandChecked -Description "Checking remaining outdated dependencies" -Command { flutter pub outdated }
    }
  }

  Invoke-CommandChecked -Description "Running flutter analyze" -Command { flutter analyze }
  Invoke-CommandChecked -Description "Running flutter test" -Command { flutter test }

  Write-Host "[deps] Dependency maintenance complete." -ForegroundColor Green
} finally {
  Pop-Location
}
