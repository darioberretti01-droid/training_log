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
