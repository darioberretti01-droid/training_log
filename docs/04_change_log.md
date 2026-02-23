# 04 - Change Log

Detailed implementation notes by commit.  
Purpose: keep `README.md` high-level while preserving concrete engineering history.

## 2026-02-21

### `e513172` - feat: redesign exercises screen controls and grouping
- Reworked Exercises screen into configurable views:
  - Grouping modes: muscles, push-pull-legs, upper-lower, compound-isolation, all exercises.
  - Presentation modes: pills/list.
  - Ordering modes: alphabetic, creation date, most used, with invert control.
- Added in-screen search and `ADD EXERCISE` action.
- Removed legacy Exercises app-bar add action from root shell.
- Added providers for:
  - exercise creation timestamp map
  - exercise log-count map
- Added widget tests for grouping, ordering, narrow layout safety, and control visibility.

### `ffef75d` - fix: make restore-label action undoable
- Extended Labels screen undo logic so restoring a hidden standard label can be undone back to hidden.
- Added widget test coverage for restore -> undo behavior.

### `5aa97f3` - feat: refine labels UX and unify app shell navigation
- Added persistent bottom navigation shell across app routes.
- Implemented dedicated Labels management UX:
  - hide/restore standard labels
  - delete/restore custom labels
  - session-scoped undo for add/hide/delete
- Added hidden-standard-label persistence table and migration.
- Updated routing structure to shell-based tab roots.
- Expanded docs and tests to reflect navigation and label-management changes.

### `5cb1a4c` - feat: add exercise label management and custom catalog flow
- Added custom/standard label catalog behavior and management foundations.
- Added + normalized label creation flow and screen wiring.
- Added related repository methods and tests.

## 2026-02-22

### `431d6ed` - feat: add phase 1b home overview and phase 2 split foundation
- Added session-level home overview foundations.
- Introduced initial split-programming schema/repository work.

### `ff91462` - feat: add split builder screen and home entrypoint
- Added split builder UI and persistence entry flow.
- Wired initial Home entry actions for split-based logging.

### `07254ae` - feat: add tabbed home shell and splits browsing UI
- Added bottom-tab shell structure.
- Added split browsing with active split emphasis.

### `c52b09d` - feat: add exercise hide/delete mode and label ui refinements
- Added delete/hide mode behavior in exercises list.
- Refined label management interactions.

### `7f8dd5d` - Refine exercise delete-mode pills and add split detail/edit flow
- Improved exercises delete-mode controls.
- Added split detail + edit navigation flow.

### `7b9994a` - Add control-label split volume UI and expand standard labels
- Added split volume visualization around control labels.
- Expanded baseline label coverage.

### `ee5445f` - Show exercises in all matching muscle categories
- Updated exercise grouping behavior so exercises can appear in all matching categories.

### `6a3429d` - feat: build home v2 and split/free workout logger
- Delivered Home v2 with sequence-based "Next workout" logic.
- Added unified logger with `split_day` and `free` modes.
- Added session save metadata for split/day context.
- Added draft resume behavior for in-progress workouts.
- Added tests for sequence logic and session persistence paths.

## 2026-02-23

### `95c1edd` - feat: add deterministic screenshot pipeline and demo fixture tooling
- Added deterministic app clock provider and fixture service.
- Added base fixture + scenario overlays for Home/logger states.
- Added debug tooling in `Other` tab for reset/seed.
- Added integration screenshot manifest/driver/flow and output validation.
- Added auto-generated screenshot index documentation.

### `b425dcf` - test: add additional screenshot coverage states
- Expanded screenshot catalog to cover picker/dialog/delete-mode states.
- Updated integration capture steps and docs generation output.

### `e8457d1` - Fix home screenshot top anchoring in capture flow
- Stabilized Home screenshot framing by forcing scroll-to-top before Home captures.
- Kept `home_recent_sessions_populated` as the only intentionally bottom-focused Home frame.
