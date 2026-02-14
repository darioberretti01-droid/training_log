# Training Log App

Beginner-first Flutter project for a smartphone training log.

## Project Status
- Environment setup: complete
- Android toolchain: verified
- Current implementation milestone: **Phase 1A complete**
  - local DB schema
  - seeded exercises
  - exercise list
  - quick single-exercise logging
  - basic history with best-set logic
- Phase 1B status: **in progress**
  - session-grouped exercise history
  - improved quick-log validation UX
  - expanded widget coverage for quick-log flow

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

## Pre-Commit Checklist
1. Ensure feature scope matches current roadmap phase.
2. Update docs if code behavior/schema/routes changed:
   - `docs/02_long_term_plan.md`
   - `docs/03_codebase_guide.md`
   - `README.md` (if entrypoint workflow changed)
3. Run:
   - `flutter analyze`
   - `flutter test`
4. Commit only when checks pass.
