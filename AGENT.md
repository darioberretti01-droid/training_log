# AGENT.md - Project Coherence Rules

This file defines how contributors (human or AI) should work in this repository.

## 1. Mission
- Keep the project aligned with the roadmap in `docs/02_long_term_plan.md`.
- Keep implementation understandable for beginners.
- Preserve working software at every commit.

## 2. Source of Truth
- Product roadmap: `docs/02_long_term_plan.md`
- Current architecture and code map: `docs/03_codebase_guide.md`
- Environment setup: `docs/01_environment_setup.md`
- Root overview: `README.md`

When code and docs diverge, update docs in the same branch before commit.

## 3. Pre-Commit Checklist
1. Confirm scope matches the current phase/milestone.
2. Update docs if any of the following changed:
   - data model or persistence behavior
   - routes/screens/user flows
   - repository/provider interfaces
   - setup/dev workflow
3. Run quality checks from `app/`:
   - `flutter analyze`
   - `flutter test`
4. Commit only when checks pass (unless explicitly documented exception).

## 4. Coding Standards
- Keep changes incremental and testable.
- Prefer explicit, simple logic over clever abstractions.
- Keep user-facing copy clear and practical.
- Use Riverpod providers for app wiring/state boundaries.
- Keep database writes transactional when one user action spans multiple rows.

## 5. Documentation Standards
- `README.md` should stay high-level and task-oriented.
- `docs/02_long_term_plan.md` should reflect phase status and next priorities.
- `docs/03_codebase_guide.md` should reflect actual code structure and behavior.
- Avoid stale TODO text; if a plan changed, update the document explicitly.

## 6. Git and Change Safety
- Do not rewrite published history unless explicitly requested.
- Do not commit generated machine-specific config that should stay local.
- Keep commits scoped and with clear messages.

## 7. Default Definition of Done
- Feature behavior works locally.
- Relevant tests exist and pass.
- Documentation is updated.
- No analyzer errors.

## 8. Emulator Deploy Verification (Required for UI Changes)
When a user asks to "open/start the app" after code changes, use a fresh deploy path so they see the latest build:
1. Ensure emulator is running and online (`flutter emulators`, `adb devices`).
2. Stop old app instance and uninstall package:
   - `adb shell am force-stop com.dario.training.training_log_app`
   - `adb uninstall com.dario.training.training_log_app`
3. From `app/`, rebuild/install with:
   - `flutter clean`
   - `flutter pub get`
   - `flutter run -d emulator-5554`
4. Confirm app process exists after install (`adb shell pidof com.dario.training.training_log_app`).
5. If a detached/background launch is required, still ensure one confirmed successful install happened first.

## 9. Command Execution Safety
- ALWAYS run commands with an explicit timeout.
- For agent tool calls, always set `timeout_ms`; never run a command without it.
- Prefer short, bounded timeouts first, then retry with a longer timeout only if needed.
