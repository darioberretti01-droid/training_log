param(
    [string]$RepoRoot = 'C:\Users\dario\Documents\training-log-app'
)

$ErrorActionPreference = 'Stop'

Push-Location $RepoRoot

if (-not (Test-Path '.git')) {
    git init
    Write-Host 'Initialized git repository.' -ForegroundColor Green
} else {
    Write-Host 'Git repository already exists.' -ForegroundColor Yellow
}

@'
# System / editor
.DS_Store
Thumbs.db
.vscode/
.idea/

# Flutter / Dart
**/.dart_tool/
**/.flutter-plugins
**/.flutter-plugins-dependencies
**/.packages
**/build/
**/coverage/

# Android / iOS generated
**/android/.gradle/
**/android/local.properties
**/ios/Pods/
**/ios/.symlinks/
'@ | Set-Content -Path '.gitignore' -Encoding UTF8

if (-not (Test-Path 'app')) {
    Write-Host 'App folder not found yet. Run create_flutter_app.ps1 first.' -ForegroundColor Yellow
} else {
    Write-Host 'App folder detected.' -ForegroundColor Green
}

Write-Host 'Next:' -ForegroundColor Cyan
Write-Host '1) git add .' -ForegroundColor Cyan
Write-Host "2) git commit -m 'chore: bootstrap training log app'" -ForegroundColor Cyan

Pop-Location
