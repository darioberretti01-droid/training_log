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
2. Root shell shows bottom tabs: `Home`, `Splits`, `Exercises`, `Other`.
3. `Home` shows quick logging actions and recent session overview.
4. `Exercises` triggers seeding if DB is empty and shows exercise list.
5. User can open split builder from `Splits` via top-right `+`.
6. User taps an exercise to open history/details.
7. User can edit exercise labels and create custom exercises from `Exercises`.
8. Label picking uses a searchable multi-select pill selector with persistent `+add` dialog.
9. `Other` exposes a `Labels` screen for global label browse/create.
10. Quick logging still exists via `/quick/:exerciseId` route.

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
  - `user_exercise_database.dart` - separate Drift DB for custom exercises + standard-label overrides
  - `user_exercise_database.g.dart` - generated Drift code
  - `seed_data.dart` - seeded exercise catalog and labels
- `core/models/`
  - `exercise_with_labels.dart`
  - `logged_set_input.dart`
- `core/state/providers.dart`
  - DB/repository providers
  - app-level query providers
- `features/exercises/`
  - `exercise_repository.dart`
  - `exercise_create_screen.dart`
  - `exercise_labels_screen.dart`
  - `labels_screen.dart`
  - `exercise_list_screen.dart`
  - `exercise_history_screen.dart`
- `features/workouts/`
  - `quick_workout_repository.dart`
  - `quick_workout_screen.dart`
- `features/splits/`
  - `split_builder_screen.dart`
  - `splits_screen.dart`
  - `split_repository.dart`
- `features/home/home_screen.dart`
  - root tab shell and lightweight Home/Other tab content
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
- `app/test/widget/phase_2_home_shell_test.dart`
- `app/test/widget/phase_2_split_builder_test.dart`

## 3. Data Model (Drift)

Main DB (`training_log.sqlite`):
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

User exercise DB (`training_log_user_exercises.sqlite`):
- `user_exercises`
  - id, name, is_override, standard_exercise_id, created_at, updated_at
- `user_exercise_labels`
  - id, name
- `user_exercise_label_links`
  - exercise_id, label_id (composite PK)

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
  - watch merged list of standard + custom exercises
  - get exercise by id
  - seed DB if empty
  - create custom exercise
  - edit labels
  - restore standard labels for overridden standard exercises
- `QuickWorkoutRepository`
  - save quick workout transactionally
  - get best set for exercise or exercise-id group
  - get last set for exercise-id group
  - get recent sets for exercise
  - get recent session-grouped history for exercise or exercise-id group
  - get recent session overview for home (cross-exercise summary)
- `SplitRepository`
  - create split with day plans + planned exercises transactionally
  - set active split (single-active invariant)
  - watch split summaries
  - get split details by id
  - delete split (with cascading child delete)

Provider layer (`providers.dart`):
- `appDatabaseProvider`
- `userExerciseDatabaseProvider`
- `exerciseRepositoryProvider`
- `allLabelsProvider`
- `quickWorkoutRepositoryProvider`
- `seedDataProvider`
- query providers for list/exercise/best/recent
- session-grouped history provider: `recentSessionsByExerciseProvider`
- lookup-based history providers: `bestSetByLookupProvider`, `lastSetByLookupProvider`, `recentSessionsByLookupProvider`
- home recent sessions provider: `recentHomeSessionsProvider`
- split repository provider: `splitRepositoryProvider`
- split list provider: `splitsProvider`
- active split provider: `activeSplitProvider`
- split details provider: `splitDetailsProvider`

## 5. UI and Routes

Routes:
- `/` -> root tab shell
- `/quick/:exerciseId` -> quick workout entry
- `/history/:exerciseId` -> history for one exercise
- `/exercises/new` -> create custom exercise
- `/exercises/:exerciseId/labels` -> edit labels for exercise
- `/splits/builder` -> split builder

Screen behavior:
- Root shell:
  - app bar title reflects selected tab (`Home`, `Splits`, `Exercises`, `Other`)
  - bottom navigation exposes 4 sections
  - top-right prominent `+` appears on `Splits` tab and opens split builder
  - top-right prominent `+` appears on `Exercises` tab and opens custom exercise creation
  - `Other` tab includes navigation to global label management
- Home tab:
  - large `Log current split` action
  - two secondary actions: `Log from other split`, `Log single exercises`
  - `Recent sessions` section with session cards (timestamp, duration, total sets, exercise summary)
  - each recent session card navigates to history for its primary exercise
- Exercise list:
  - shows merged exercise catalog (standard + custom + overridden labels)
  - tap row opens exercise history/details
  - history icon also opens history
- Exercise create:
  - create custom exercise with name + labels
- Exercise labels editor:
  - add/remove labels
  - label selection supports search + multi-select chips
  - chip list always ends with a persistent `+add` chip (opens centered create-label dialog)
  - when editing a standard exercise, save creates/updates a temporary override entry
  - overridden standard exercises can restore original labels via `Back to standard labels`
- Labels screen:
  - shows all known labels via searchable multi-select chips
  - supports creating new labels through the same persistent `+add` dialog flow
- Splits:
  - highlighted `Current split` section showing active split (if any)
  - `All splits` section with all saved splits ordered by latest update
  - each split row shows day count and update timestamp
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
  - labels section with edit action
  - top performance cards: best set, best current split set, last set
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
- app boot with root home tab + tab switch behavior
- home shell rendering with exercise list
- quick workout validation UX and successful save path
- home recent sessions section: populated, empty, error+retry, and tap navigation
- split tab rendering and split-builder navigation from `+`
- split builder validation and successful save path

## 7. Known Limitations

- Summary screen and launch-from-day-plan flow are not implemented yet.
- Home tab action buttons are UI placeholders (logging behavior not wired yet).
- No progression/suggestion rules yet.
- No delete flow yet for custom exercises.

## 8. How to Extend Safely

Before changing persistence or flow:
1. Update this document and `docs/02_long_term_plan.md`.
2. Add/adjust tests first for critical behavior.
3. Keep feature boundaries in `core` and `features`.
4. Re-run:
   - `flutter analyze`
   - `flutter test`
