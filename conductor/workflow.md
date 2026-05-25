# Workflow

## TDD Policy

**Moderate.** Tests encouraged but not gated. For this repo specifically:

- Test the toolkit via the documented `_test_project` integration sequence (Step 10 of original spec). That sequence is the acceptance test.
- Unit tests via `pytest` welcome for non-trivial Python (e.g. codemap parsing edge cases) but not required for one-shot scripts.

## Commit Strategy

Conventional Commits: `<type>(<scope>): <subject>`. Types: `feat`, `fix`, `refactor`, `chore`, `docs`, `test`, `perf`, `ci`. Subject ≤ 72 chars, imperative. Body explains WHY not WHAT. Footer for issue refs.

## Branching & PR Flow

**Never commit directly to `main`** (one exception: the original `chore: init` commit).

For every new change — feature, fix, doc tweak, refactor:

1. Branch off `main` with a name matching commit type:
   ```bash
   git checkout main && git pull
   git checkout -b <type>/<short-description>
   ```
   Examples: `feat/add-go-skill`, `fix/codemap-cache-bug`, `docs/git-flow-policy`.
2. Make changes, commit on the dev branch using Conventional Commits format.
3. Push the dev branch:
   ```bash
   git push -u origin <type>/<short-description>
   ```
4. Open a PR against `main`:
   ```bash
   gh pr create --base main --head <type>/<short-description> \
     --title "<conventional-commit-style title>" \
     --body "..."
   ```
5. Review (self or otherwise). Address comments with additional commits on the same branch.
6. Merge to `main` only after review. Prefer **squash merge** to keep `main` history linear.
7. Delete the dev branch locally and on remote after merge.

## Code Review

Self-review acceptable for solo work. Use the `python-code-reviewer` agent on non-trivial Python diffs before commit.

## Verification Checkpoints

- After each **track** completes: visually inspect generated files.
- After **Track H** (test sequence): all 8 documented commands must pass with zero errors.
- Before **Track I** (commit): user explicitly confirms.

## Task Lifecycle

1. Pick a track from `tracks.md`.
2. Read `tracks/<id>/spec.md` and `plan.md`.
3. Implement tasks in order from `plan.md`.
4. Mark track complete in `tracks.md` when all tasks pass verification.
5. Move on to next track.

## Idempotency

Every `add` / install operation must be safe to re-run. If a tool is already installed, prompt or skip — never silently corrupt state.
