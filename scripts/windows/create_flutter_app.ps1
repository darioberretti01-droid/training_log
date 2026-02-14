param(
    [string]$ProjectRoot = 'C:\Users\dario\Documents\training-log-app\app',
    [string]$Org = 'com.dario.training',
    [string]$ProjectName = 'training_log_app'
)

$ErrorActionPreference = 'Stop'

if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) {
    throw 'flutter command not found. Open a new PowerShell or run install_prerequisites.ps1 first.'
}

if (Test-Path $ProjectRoot) {
    throw "Project path already exists: $ProjectRoot"
}

$parent = Split-Path $ProjectRoot -Parent
if (-not (Test-Path $parent)) {
    New-Item -Path $parent -ItemType Directory -Force | Out-Null
}

Write-Host "Creating Flutter project at $ProjectRoot" -ForegroundColor Cyan
Push-Location $parent
flutter create --platforms=android,ios --org $Org $ProjectName
Pop-Location

$appPath = Join-Path $parent $ProjectName
if ($appPath -ne $ProjectRoot) {
    Rename-Item -Path $appPath -NewName (Split-Path $ProjectRoot -Leaf)
}

Push-Location $ProjectRoot

Write-Host 'Adding dependencies...' -ForegroundColor Cyan
flutter pub add flutter_riverpod go_router drift sqlite3_flutter_libs path_provider path intl uuid collection
flutter pub add --dev drift_dev build_runner mocktail

Write-Host 'Creating feature folders...' -ForegroundColor Cyan
$folders = @(
    '.github/workflows',
    'lib/core/db',
    'lib/core/state',
    'lib/core/logic',
    'lib/core/models',
    'lib/core/utils',
    'lib/features/exercises',
    'lib/features/splits',
    'lib/features/workouts',
    'lib/features/home',
    'lib/features/analytics',
    'lib/ui'
)

foreach ($folder in $folders) {
    New-Item -Path $folder -ItemType Directory -Force | Out-Null
}

Write-Host 'Writing starter architecture files...' -ForegroundColor Cyan

@'
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';

void main() {
  runApp(const ProviderScope(child: TrainingLogApp()));
}
'@ | Set-Content -Path 'lib/main.dart' -Encoding UTF8

@'
import 'package:flutter/material.dart';

import 'ui/app_router.dart';

class TrainingLogApp extends StatelessWidget {
  const TrainingLogApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Training Log',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      routerConfig: appRouter,
    );
  }
}
'@ | Set-Content -Path 'lib/app.dart' -Encoding UTF8

@'
import 'package:go_router/go_router.dart';

import '../features/home/home_screen.dart';

final appRouter = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const HomeScreen(),
    ),
  ],
);
'@ | Set-Content -Path 'lib/ui/app_router.dart' -Encoding UTF8

@'
import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Training Log')),
      body: const Center(
        child: Text(
          'Environment ready. Next step: implement Milestone 1.',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
'@ | Set-Content -Path 'lib/features/home/home_screen.dart' -Encoding UTF8

@'
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:training_log_app/app.dart';

void main() {
  testWidgets('App boots and shows home title', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: TrainingLogApp()));
    expect(find.text('Training Log'), findsOneWidget);
  });
}
'@ | Set-Content -Path 'test/widget_test.dart' -Encoding UTF8

@'
# Training Log App

Bootstrapped with Flutter + Riverpod + GoRouter + Drift.

## Run
```bash
flutter pub get
flutter run
```

## Check quality
```bash
flutter analyze
flutter test
```
'@ | Set-Content -Path 'README.md' -Encoding UTF8

@'
name: Flutter CI

on:
  pull_request:
  push:
    branches: [ main ]

jobs:
  analyze-and-test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with:
          channel: stable
      - run: flutter pub get
      - run: flutter analyze
      - run: flutter test
'@ | Set-Content -Path '.github/workflows/flutter_ci.yml' -Encoding UTF8

Write-Host 'Getting packages...' -ForegroundColor Cyan
flutter pub get

Write-Host "\nProject bootstrap completed at $ProjectRoot" -ForegroundColor Green
Write-Host 'Next steps:' -ForegroundColor Cyan
Write-Host '1) cd C:\Users\dario\Documents\training-log-app\app' -ForegroundColor Cyan
Write-Host '2) flutter run' -ForegroundColor Cyan
Write-Host '3) come back here and we implement Milestone 1' -ForegroundColor Cyan

Pop-Location
