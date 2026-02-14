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

## 3. Required Workflow Before Every Commit
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
