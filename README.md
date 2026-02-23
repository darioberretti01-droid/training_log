# Training Log App

Beginner-first Flutter project for a smartphone training log.

## Quick Start (Run From GitHub)
1. Clone the repository:
   - `git clone https://github.com/darioberretti01-droid/training_log.git`
   - `cd training_log`
2. Enter the Flutter app folder:
   - `cd app`
3. Install dependencies:
   - `flutter pub get`
4. Verify setup:
   - `flutter doctor`
5. Run checks:
   - `flutter analyze`
   - `flutter test`
6. Start the app (Android emulator/device):
   - `flutter emulators --launch Medium_Phone_API_36.1` (if needed)
   - `flutter run -d emulator-5554`

## Project Status
- Core logging flow is implemented and test-covered.
- Split planning foundation is implemented (schema + builder + browsing).
- Exercise/label management UX is in active iteration.

## Repository Structure
- `app/` - Flutter application code
- `docs/` - setup, roadmap, and architecture docs
- `scripts/windows/` - Windows helper scripts for setup/bootstrap
- `AGENT.md` - contributor rules to keep project coherence

## Documentation Map
- `docs/01_environment_setup.md`
  - Windows setup walkthrough
- `docs/02_long_term_plan.md`
  - roadmap, phase tracking, and next priorities
- `docs/03_codebase_guide.md`
  - current architecture, data model, flow, and test strategy
- `docs/04_change_log.md`
  - detailed commit-by-commit implementation notes
- `docs/05_screenshots.md`
  - auto-generated screenshot index from integration manifest

## Development Workflow
From `app/`:

```bash
flutter pub get
flutter analyze
flutter test
flutter run -d emulator-5554
```

## Windows Setup Scripts
- `scripts/windows/install_prerequisites.ps1`
- `scripts/windows/verify_environment.ps1`
- `scripts/windows/create_flutter_app.ps1`
- `scripts/windows/init_git_repo.ps1`

These are useful for recovery/new machine onboarding even after initial setup.

## Screenshot Automation (Windows)
- Seed deterministic demo data:
  - `scripts/windows/seed_demo_data.ps1`
- Capture full screenshot catalog:
  - `scripts/windows/run_screenshots.ps1`
