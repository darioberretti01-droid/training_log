# 03 - Codebase Guide

This document describes the current implementation in practical terms.

## 1. High-Level Architecture

App stack:
- Flutter UI
- Riverpod for dependency wiring and state providers
- GoRouter for navigation
- Drift + SQLite for local persistence

Current flow:
1. App starts and loads home (`/`).
2. Home triggers seeding if DB is empty.
3. User sees recent session overview cards and the exercise list.
4. User can open split builder from home and create a split.
5. User opens quick log for an exercise and saves sets.
6. User opens history to review best and recent sets.

## 2. Directory Map

Root:
- `README.md` - high-level project entrypoint
- `AGENT.md` - contribution/coherence rules
- `docs/` - setup, roadmap, code guide
- `scripts/windows/` - setup/bootstrap helper scripts
- `app/` - Flutter application

App source (`app/lib`):
- `core/db/`
  - `app_database.dart` - Drift tables + DB connection
  - `app_database.g.dart` - generated Drift code
  - `seed_data.dart` - seeded exercise catalog and labels
- `core/models/`
  - `exercise_with_labels.dart`
  - `logged_set_input.dart`
- `core/state/providers.dart`
  - DB/repository providers
  - app-level query providers
- `features/exercises/`
  - `exercise_repository.dart`
  - `exercise_list_screen.dart`
  - `exercise_history_screen.dart`
- `features/workouts/`
  - `quick_workout_repository.dart`
  - `quick_workout_screen.dart`
- `features/splits/`
  - `split_builder_screen.dart`
  - `split_repository.dart`
- `features/home/home_screen.dart`
  - delegates to exercise list screen
- `ui/app_router.dart`
  - app routes

Tests:
- `app/test/core/phase_1a_repositories_test.dart`
- `app/test/core/phase_1b_home_overview_test.dart`
- `app/test/core/phase_2_split_repository_test.dart`
- `app/test/core/phase_2_migration_test.dart`
- `app/test/widget_test.dart`
- `app/test/widget/phase_1b_flow_test.dart`
- `app/test/widget/phase_1b_home_overview_test.dart`
- `app/test/widget/phase_2_split_builder_test.dart`

## 3. Data Model (Drift)

Tables:
- `exercises`
  - id, name, is_seeded, created_at, updated_at
- `exercise_labels`
  - id, name
- `exercise_label_links`
  - exercise_id, label_id (composite PK)
- `workout_sessions`
  - id, session_type, started_at, ended_at
- `performed_sets`
  - id, session_id, exercise_id, set_index, reps, weight_kg, rest_seconds, rpe, performed_at
- `splits`
  - id, name, is_active, created_at, updated_at
- `day_plans`
  - id, split_id, day_index, title, created_at, updated_at
- `planned_exercises`
  - id, day_plan_id, exercise_id, order_index, target_sets, rep_min, rep_max, rest_seconds, target_rpe, created_at, updated_at

Current conventions:
- Phase 1A uses `session_type = "quick"` only.
- Unit is kilograms only.
- Best set ordering:
  1. higher `weight_kg`
  2. then higher `reps`
  3. then latest `performed_at`
- Migration strategy:
  - schema version currently `2`
  - v1 -> v2 migration adds split programming tables only (data-preserving for Phase 1 tables)
  - `MigrationStrategy` remains additive for future phases

## 4. Repositories and Providers

Repositories:
- `ExerciseRepository`
  - watch list of exercises with labels
  - get exercise by id
  - seed DB if empty
- `QuickWorkoutRepository`
  - save quick workout transactionally
  - get best set for exercise
  - get recent sets for exercise
  - get recent session-grouped history for exercise
  - get recent session overview for home (cross-exercise summary)
- `SplitRepository`
  - create split with day plans + planned exercises transactionally
  - set active split (single-active invariant)
  - watch split summaries
  - get split details by id
  - delete split (with cascading child delete)

Provider layer (`providers.dart`):
- `appDatabaseProvider`
- `exerciseRepositoryProvider`
- `quickWorkoutRepositoryProvider`
- `seedDataProvider`
- query providers for list/exercise/best/recent
- session-grouped history provider: `recentSessionsByExerciseProvider`
- home recent sessions provider: `recentHomeSessionsProvider`
- split repository provider: `splitRepositoryProvider`
- split list provider: `splitsProvider`
- active split provider: `activeSplitProvider`
- split details provider: `splitDetailsProvider`

## 5. UI and Routes

Routes:
- `/` -> exercise list
- `/quick/:exerciseId` -> quick workout entry
- `/history/:exerciseId` -> history for one exercise
- `/splits/builder` -> split builder

Screen behavior:
- Exercise list:
  - app bar includes Split Builder entrypoint
  - shows a `Recent sessions` section with session cards (timestamp, duration, total sets, exercise summary)
  - each recent session card navigates to history for its primary exercise
  - shows seeded exercises + label chips
  - tap row opens quick log
  - history icon opens history
- Split builder:
  - creates a split with ordered days and ordered planned exercises
  - captures target sets, rep range, optional rest and target RPE
  - save writes split/day/planned rows transactionally via `SplitRepository`
  - optional toggle sets the new split as active
- Quick workout:
  - starts with 3 set rows
  - required: reps and weight
  - optional: rest and RPE
  - save writes one session + N sets
- History:
  - top best-set card
  - recent sessions grouped by workout session
  - each session shows timestamp, duration, and its set list

## 6. Testing Strategy (Current)

Repository tests cover:
- seed idempotency
- DB roundtrip for quick workout save
- best-set ranking rule
- basic validation failures
- home session overview ordering, session limiting, and aggregation
- split repository validation and transactional persistence
- single-active split behavior
- split detail ordering and cascade delete behavior
- v1 -> v2 migration behavior and data preservation

Widget test covers:
- app boot with provider overrides
- home shell rendering with exercise list
- quick workout validation UX and successful save path
- home recent sessions section: populated, empty, error+retry, and tap navigation
- split builder validation and successful save path

## 7. Known Limitations

- Summary screen and launch-from-day-plan flow are not implemented yet.
- No progression/suggestion rules yet.
- No custom exercise create/edit/delete yet.

## 8. How to Extend Safely

Before changing persistence or flow:
1. Update this document and `docs/02_long_term_plan.md`.
2. Add/adjust tests first for critical behavior.
3. Keep feature boundaries in `core` and `features`.
4. Re-run:
   - `flutter analyze`
   - `flutter test`
