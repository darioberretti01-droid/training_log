# 02 - Long Term Plan

This document tracks the product roadmap and current status.

## Current Status (as of 2026-02-22)
- Environment setup complete (Flutter + Android toolchain verified).
- Phase 1A implemented:
  - local DB schema (exercises, labels, sessions, performed sets)
  - seeded exercise catalog
  - exercise list screen
  - quick single-exercise logging
  - exercise history with best-set logic
  - automated tests for repository logic + basic widget shell
- Phase 1B started:
  - quick-log validation UX improved (inline, persistent validation feedback)
  - session-level history browsing added (grouped by workout session)
  - home recent session overview added (cross-exercise summary cards)
  - widget tests expanded for quick-log flow
  - DB migration strategy scaffold added for next schema phases
  - note: remaining Phase 1B polish/integration tasks are deferred while Phase 2 starts
- Phase 2 started:
  - schema v2 with split-programming tables (`splits`, `day_plans`, `planned_exercises`)
  - migration path from v1 to v2 (additive, data-preserving)
  - split repository + provider foundations
  - repository and migration tests for split foundation
  - split builder create flow added (day/exercise planning + save)
  - split browsing page added (active split highlight + all splits list)
  - root app shell updated to 4 tabs (`Home`, `Splits`, `Exercises`, `Other`)
  - exercise history updated to show:
    - best set
    - best current-split set
    - last set
    - editable label section
  - label selection upgraded to searchable multi-select pill picker with persistent `ADD LABEL` action
  - `Other` tab now includes a dedicated `Labels` screen for browsing/creating labels
  - labels management behavior expanded:
    - custom labels can be deleted
    - standard labels can be hidden/restored
    - labels screen supports per-session undo for add/hide/delete actions
  - navigation shell updated so bottom tab selector remains visible across screens
  - exercises tab behavior updated:
    - tap exercise opens history (not quick log)
    - top-right `+` opens new exercise creation
  - separate user exercise DB added for:
    - custom exercises
    - temporary label overrides for standard exercises
    - restore-standard-labels flow for overridden standard exercises
  - split volume visualization added:
    - full muscle-volume overview in split builder/edit with selectable control labels
    - lightweight muscle-volume summary in split detail view
  - standard label set expanded with: `glutes`, `forearms`, `back`, `abs`

## Roadmap

### Phase 0 - Foundations (done)
- Git repo and initial commit
- CI workflow scaffold in app
- basic project structure
- setup docs and bootstrap scripts

### Phase 1 - Core Log Minimal (in progress)
Phase 1A (done):
- DB entities: `Exercise`, `WorkoutSession`, `PerformedSet` (+ labels tables)
- seed exercises (no video)
- UI: exercise list + quick workout
- save sessions
- history basics per exercise
- tests: persistence roundtrip and best-set logic

Phase 1B (in progress):
- done:
  - improve quick-log validation UX
  - add session-level history browsing
  - add session-level overview from home (cross-exercise)
  - strengthen widget tests for quick-log flow
  - add migration strategy scaffold for future split programming
- deferred backlog for now:
  - add more UX polish for loading/error/empty states
  - add integration-style tests for log -> history roundtrip across routes

### Phase 2 - Split Programming (MVP, in progress)
- done:
  - DB tables: `Split`, `DayPlan`, `PlannedExercise`
  - migration v1 -> v2 (additive)
  - repository layer for split create/read/delete + active split selection
  - split builder create flow (name, ordered days, planned exercises, set/rep/rest/RPE targets)
  - split browse UI with active split section and full split list
  - bottom-tab root shell with dedicated Home/Splits/Exercises sections
  - split muscle-volume overview (per-day + whole-split sets) in builder/edit/detail
  - control-label based split volume tracking with default muscles:
    - chest, back, shoulders, biceps, triceps, quads, glutes, hamstrings
- next:
  - launch workout from day plan
  - workout screen references: last / best-in-split / best all-time
  - connect home quick actions to actual workout flows (currently placeholders)

### Phase 3 - Progression and Warnings (v1.1)
- increase-load suggestion when prior range was saturated
- warning when reps drop below lower bound
- starting load suggestion:
  - first by same exercise
  - then by similar labels

### Phase 4 - Smart Scheduling (v1.2)
- home logic based on:
  - last completed workout
  - split sequence
  - skipped days / extra workouts
- tests for today/next selection logic

### Phase 5 - Advanced Features (post-MVP)
- quick exercise swap during workout + load suggestion
- superset/dropset modeling and UI
- technique videos
- export/backup
- analytics
- optional cloud sync/login

## Non-Goals for Current Scope
- iOS runtime support from Windows host
- cloud auth/sync
- advanced progression algorithms

## Planning and Delivery Rules
- Keep each implementation slice small and test-backed.
- Before each commit, update:
  - this roadmap if phase status changed
  - `docs/03_codebase_guide.md` if architecture/behavior changed
