# Environment Setup (Windows + WSL Friendly)

This guide gets your machine ready to build a Flutter app for Android and iOS.

## 1. Open the right shell
Use **Windows PowerShell** (not WSL) for installation and Flutter mobile commands.

Why: Android Studio, emulators, and Windows PATH integration are native Windows tools. WSL is fine for editing and Git, but device/emulator tooling is simpler in PowerShell.

## 2. Run prerequisite installer
From PowerShell:

```powershell
Set-ExecutionPolicy -Scope CurrentUser RemoteSigned
cd C:\Users\dario\Documents\training-log-app\scripts\windows
.\install_prerequisites.ps1
```

What it installs:
- Git (if missing)
- Android Studio
- Flutter SDK (latest stable) in `C:\dev\flutter`
- PATH update for Flutter

## 3. Complete Android Studio first-run
Open Android Studio once and install:
- Android SDK
- Android SDK Platform
- Android SDK Command-line Tools
- Android Emulator

Then create one emulator (for example Pixel 8 / API 35).

## 4. Verify the toolchain
From PowerShell:

```powershell
cd C:\Users\dario\Documents\training-log-app\scripts\windows
.\verify_environment.ps1
```

If `flutter doctor -v` reports Android toolchain issues, fix the listed item and rerun.

## 5. Accept Android licenses
If requested by `flutter doctor`:

```powershell
flutter doctor --android-licenses
```

## 6. Create the project

```powershell
cd C:\Users\dario\Documents\training-log-app\scripts\windows
.\create_flutter_app.ps1
```

This creates `C:\Users\dario\Documents\training-log-app\app` and installs planned packages.

## 7. Run once

```powershell
cd C:\Users\dario\Documents\training-log-app\app
flutter run
```

If multiple devices are available:

```powershell
flutter devices
flutter run -d <device_id>
```

## iOS note
iOS builds require macOS + Xcode. You can still develop most of the app on Windows and run Android now.
