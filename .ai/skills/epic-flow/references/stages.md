# Stages

One issue goes through these stages. The label `stage:<name>` is the column. A worker advances only when the exit criteria are met by commands it ran itself (epic-flow R9).

| Stage | Who | Does | Leaves behind | Exit (gate) | Next |
|---|---|---|---|---|---|
| `plan` | any | Reads item + `digest`; writes a short implementation plan as a `handoff` note: files, approach, risks, how the Gates will be satisfied. Uses the `plan-feature` approach for features. | plan note | plan names every file inside Owns and every Gate | `test-plan` |
| `test-plan` | any (same session may continue) | Writes the failing tests / characterization tests / before-screenshots first, per the `testing` skill. | tests committed on the branch | new tests exist and fail (or, for characterization, pass on the old code) | `build` |
| `build` | any | Implements with the relevant skills loaded (`senior-rails-dev` for Rails/Phlex/Stimulus work; the item says if a specialised builder applies). Commits in small steps. | code on the branch | Gates green locally | `gates` |
| `gates` | same session | Runs every Gate command from the issue exactly as written, plus `bin/rubocop` on touched Ruby. Pastes the summary into the advance note. | gate output summary | all green | `audit` (release) |
| `audit` | **different** session than build/fix (R10) | Runs `/audit-feature` on the branch diff (gem paths use the gem routing), re-runs the Gates independently. Findings go to the issue as one `blocker`-free `handoff` note, MANDATORY vs ADVISORY. | audit findings note | no MANDATORY finding | `review`, or `fix` |
| `fix` | any, prefers the builder | Fixes MANDATORY findings, re-runs Gates, max 3 iterations (R11). | commits | Gates green and findings resolved | `audit` (release) |
| `review` | the worker opens the PR; a human merges | Opens/updates the PR from branch `epic/<slug>/<N>-<title>` (the branch name is how `reviews` finds it; `Closes #N` is NOT used), requests review, releases the item. Nobody works an item in `review`. | PR | merged to `main` | `done` (via the merge sweep) |
| `done` | the merge sweep, run first by every `/work` iteration | `reviews` reports `merged`; the sweeper claims the item, re-runs the Gates on `origin/main` in a detached worktree, posts a `shared` note if others consume the result, advances to `done` (closes the issue, unblocking dependents). Red on main -> `block`. PR `closed_unmerged` -> `fix`. | `shared` note | Gates green on `main` (R14) | |

## Rules of thumb

- Pull the lowest `wave` first; `next` already does.
- Between `build` and `gates`, `heartbeat`. A stage longer than 15 minutes without a heartbeat risks takeover.
- A gate that cannot run for environmental reasons (no browser, no network) is a `blocker`, not a skip.
- `advance --note` is read by the next worker: say what changed and what to look at.
