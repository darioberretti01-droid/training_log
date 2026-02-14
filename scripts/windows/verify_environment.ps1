$ErrorActionPreference = 'Continue'

function Header($text) {
    Write-Host "`n=== $text ===" -ForegroundColor Cyan
}

Header 'Versions'
if (Get-Command git -ErrorAction SilentlyContinue) { git --version } else { Write-Host 'git not found' -ForegroundColor Red }
if (Get-Command java -ErrorAction SilentlyContinue) { java -version } else { Write-Host 'java not found in PATH (Android Studio may still bundle JDK)' -ForegroundColor Yellow }
if (Get-Command flutter -ErrorAction SilentlyContinue) { flutter --version } else { Write-Host 'flutter not found in PATH' -ForegroundColor Red }

Header 'Flutter doctor'
if (Get-Command flutter -ErrorAction SilentlyContinue) {
    flutter doctor -v
} else {
    Write-Host 'Cannot run flutter doctor without flutter in PATH.' -ForegroundColor Red
}

Header 'Android tools'
if (Get-Command adb -ErrorAction SilentlyContinue) { adb version } else { Write-Host 'adb not found in PATH' -ForegroundColor Yellow }
if (Get-Command sdkmanager -ErrorAction SilentlyContinue) { sdkmanager --version } else { Write-Host 'sdkmanager not found in PATH (usually under Android SDK cmdline-tools)' -ForegroundColor Yellow }

Write-Host "`nDone. Resolve any red issues first, then rerun this script." -ForegroundColor Green
