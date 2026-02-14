$ErrorActionPreference = 'Stop'

function Ensure-Winget {
    if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
        throw "winget not found. Install 'App Installer' from Microsoft Store, then rerun."
    }
}

function Ensure-Package {
    param(
        [Parameter(Mandatory=$true)][string]$Id,
        [Parameter(Mandatory=$true)][string]$Name
    )

    Write-Host "Checking $Name..." -ForegroundColor Cyan
    $found = winget list --id $Id --exact | Out-String
    if ($found -match $Id) {
        Write-Host "$Name already installed." -ForegroundColor Green
        return
    }

    Write-Host "Installing $Name..." -ForegroundColor Yellow
    winget install --id $Id --exact --accept-package-agreements --accept-source-agreements
}

function Install-Flutter {
    $flutterRoot = 'C:\dev\flutter'
    $flutterBin = Join-Path $flutterRoot 'bin'
    $flutterExe = Join-Path $flutterBin 'flutter.bat'

    if (Test-Path $flutterExe) {
        Write-Host "Flutter already installed at $flutterRoot" -ForegroundColor Green
    } else {
        Write-Host "Installing Flutter stable SDK..." -ForegroundColor Yellow
        New-Item -Path 'C:\dev' -ItemType Directory -Force | Out-Null

        $releaseInfo = Invoke-RestMethod 'https://storage.googleapis.com/flutter_infra_release/releases/releases_windows.json'
        $stableHash = $releaseInfo.current_release.stable
        $stableRelease = $releaseInfo.releases | Where-Object { $_.hash -eq $stableHash } | Select-Object -First 1

        if (-not $stableRelease) {
            throw 'Unable to resolve latest stable Flutter release.'
        }

        $archiveUrl = "$($releaseInfo.base_url)/$($stableRelease.archive)"
        $zipPath = Join-Path $env:TEMP 'flutter_windows_stable.zip'

        Write-Host "Downloading $archiveUrl" -ForegroundColor Cyan
        Invoke-WebRequest -Uri $archiveUrl -OutFile $zipPath

        Write-Host "Extracting Flutter to C:\dev" -ForegroundColor Cyan
        Expand-Archive -Path $zipPath -DestinationPath 'C:\dev' -Force
        Remove-Item $zipPath -Force
    }

    $userPath = [Environment]::GetEnvironmentVariable('Path', 'User')
    $pathEntries = @()
    if (-not [string]::IsNullOrWhiteSpace($userPath)) {
        $pathEntries = $userPath.Split(';')
    }

    if (-not ($pathEntries -contains $flutterBin)) {
        $newPath = if ([string]::IsNullOrWhiteSpace($userPath)) { $flutterBin } else { "$userPath;$flutterBin" }
        [Environment]::SetEnvironmentVariable('Path', $newPath, 'User')
        Write-Host "Added $flutterBin to User PATH." -ForegroundColor Green
        Write-Host "Open a new PowerShell window after this script." -ForegroundColor Yellow
    } else {
        Write-Host "Flutter bin already in PATH." -ForegroundColor Green
    }
}

Ensure-Winget
Ensure-Package -Id 'Git.Git' -Name 'Git'
Ensure-Package -Id 'Google.AndroidStudio' -Name 'Android Studio'
Install-Flutter

Write-Host "\nBase installation completed." -ForegroundColor Green
Write-Host "Next: open Android Studio once to install SDK components and emulator." -ForegroundColor Cyan
Write-Host "Then run verify_environment.ps1" -ForegroundColor Cyan
