# 03 - Codebase Guide

Current implementation snapshot for day-to-day development.

## 1. Architecture

Stack:
- Flutter UI
- Riverpod providers/notifiers
- GoRouter shell navigation
- Drift + SQLite local persistence

High-level shell:
- Bottom tabs: `Home`, `Splits`, `Exercises`, `Other`
- Shared shell in `app/lib/ui/root_shell.dart`
- Route config in `app/lib/ui/app_router.dart`

## 2. Core Product Flows

### Home (`/home`)
- Shows active split + last session line.
- Shows "Next workout" card with sequence-only suggestion logic.
- Supports recovery states:
  - last-used split differs from current split
  - last-used split deleted
  - no active split
- Shows draft-resume state: `Keep logging today's workout`.
- Secondary actions include:
  - log different split
  - log different day
  - free workout
  - create new split
- Recent sessions list opens session overview (`/sessions/:sessionId`).

### Workout Logger (`/workout-logger`)
- Modes:
  - `split_day` (`splitId`, `dayIndex`)
  - `free`
- Split mode hydrates planned exercises from split day.
- Free mode starts empty and uses the same full-screen exercise picker used by split builder.
- Draft is persisted and resumed for same day.
- Finish flow warns about unfilled sets before save.
- Session save writes split metadata when applicable.

### Sessions (`/sessions/:sessionId`)
- Session overview for full workout (not single-exercise history).
- Editable set rows.
- Delete session flow with confirmation.

### Splits (`/splits`)
- Split list with active split highlight.
- Split detail view and edit entrypoint.
- Split builder supports planned exercise setup and control-label volume summary.

### Exercises (`/exercises`)
- Grouped/list views with ordering and search.
- Delete/hide mode for custom/standard entries.
- Exercise history and label editor.

## 3. Data Model

Main DB (`training_log.sqlite`, schema v3):
- `exercises`
- `exercise_labels`
- `exercise_label_links`
- `workout_sessions`
  - includes `session_type`, `split_id`, `day_index`, `session_name`, timestamps
- `performed_sets`
- `splits`
  - includes `schedule_mode` (`sequence` active now, `weekday` reserved)
- `day_plans`
- `planned_exercises`
- `workout_drafts` (JSON payload table created in migration `beforeOpen`)

User DB (`training_log_user_exercises.sqlite`, schema v3):
- `user_exercises`
- `user_exercise_labels`
- `user_exercise_label_links`
- `hidden_standard_labels`
- `hidden_standard_exercises`

## 4. Important Providers and Services

Key providers (`app/lib/core/state/providers.dart`):
- `appClockProvider` for deterministic time injection
- repositories:
  - `exerciseRepositoryProvider`
  - `quickWorkoutRepositoryProvider`
  - `splitRepositoryProvider`
- home/session providers:
  - `recentHomeSessionsProvider`
  - `lastHomeSessionProvider`
  - `lastSplitDaySessionProvider`
  - `suggestedWorkoutCardStateProvider`
- draft providers:
  - `workoutDraftProvider`
  - `persistedWorkoutDraftProvider`
  - `effectiveWorkoutDraftProvider`
  - `todayWorkoutDraftProvider`
- fixtures:
  - `demoFixtureServiceProvider`

Home suggestion logic (`app/lib/features/home/home_workout_logic.dart`):
- `getActiveSplit()`
- `getLastSession(...)`
- `getNextDayIndexSequence(...)`
- `getSuggestedWorkoutCardState(...)`

## 5. Route Summary

Main routes:
- `/home`
- `/workout-logger`
- `/sessions/:sessionId`
- `/splits`, `/splits/builder`, `/splits/:splitId`, `/splits/:splitId/edit`
- `/exercises`, `/exercises/new`, `/exercises/:exerciseId/history`, `/exercises/:exerciseId/labels`, `/exercises/:exerciseId/quick`
- `/other`, `/other/labels`

## 6. Deterministic Demo Fixtures and Screenshots

Fixture APIs:
- `DemoFixtureService.resetAllData()`
- `DemoFixtureService.seedBaseFixture(...)`
- `DemoFixtureService.applyScenarioOverlay(...)`
- `DemoFixtureService.resetAndSeed(...)`

Scenario enum:
- `DemoFixtureScenario` in `app/lib/devtools/demo_fixture_models.dart`

Screenshot pipeline:
- Manifest: `app/integration_test/screenshots_manifest.dart`
- Capture flow: `app/integration_test/screenshots_flow_test.dart`
- Driver: `app/test_driver/screenshots_driver.dart`
- Validation: `app/tool/validate_screenshots.dart`
- Index generator: `app/tool/generate_screenshot_index.dart`
- Output: `app/screenshots/current/*.png`

Windows scripts:
- `scripts/windows/seed_demo_data.ps1`
- `scripts/windows/run_screenshots.ps1`

## 7. Tests

Core tests:
- repositories/migrations/split-volume/home logic/draft storage
- fixture and clock determinism
- screenshot manifest integrity

Widget tests:
- shell navigation
- home states
- split builder
- exercise and labels flows
- debug tools controls

Integration tests:
- deterministic screenshot capture suite
- fixture seeding smoke test

## 8. Current Limitations

- Weekday scheduling UI/logic is not enabled yet (`schedule_mode=weekday` reserved).
- Screenshot workflow currently capture-only (no pixel-diff regression gate yet).
