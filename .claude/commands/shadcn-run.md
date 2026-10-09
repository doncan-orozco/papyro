---
description: Orchestrate the full shadcn -> Phlex port end to end: infra wave, pilot checkpoint, then fan-out waves of plan -> build -> gate -> triage -> fix, resumable. One call, no human input.
argument-hint: "[all|a,b,c|wave:N] [--resume] [--concurrency 4] [--max-iter 3] [--pilot-only] [--no-browser]"
allowed-tools: Agent, Read, Write, Edit, Grep, Glob, TodoWrite, Bash(ruby:*), Bash(node:*), Bash(npm:*), Bash(npx:*), Bash(curl:*), Bash(cd:*), Bash(mkdir:*), Bash(bin/rails:*), Bash(bin/rubocop:*), Bash(bin/shadcn-servers:*), Bash(git status:*), Bash(git diff:*), Bash(git rev-parse:*), Bash(grep:*), Bash(ls:*), Bash(lsof:*), Bash(kill:*)
---

# /shadcn-run: the orchestrator

Arguments: $ARGUMENTS
Parse: scope (`all` default | comma list | `wave:N`), `--resume` (default behavior when state exists), `--concurrency N` (default 4, max 6), `--max-iter N` (fix iterations per component, default 3), `--pilot-only` (stop after the pilot checkpoint), `--no-browser` (G1 only; marks components `built`, never `done`).

You coordinate; you do NOT write app code, edit components or edit scenarios. Everything is done by `shadcn-port-planner`, `shadcn-port-builder` and `shadcn-parity-auditor` via the Agent tool, and every verdict comes from the gate scripts that YOU run yourself. Read `.ai/skills/shadcn-port/SKILL.md` and `references/parity-gates.md` first.

## Why this shape (keep in mind when deciding)
- **Per-component loop, wave-ordered.** Gates are cheap scripts, so each component is verified immediately after its build instead of at the end: failures are found while the context that caused them is fresh, and a bug in shared infra is caught by the pilot, not by 40 components.
- **Pilot checkpoint.** Infra + 6 representative components (static cva, boolean control, floating, menu, selection, modal) must be green before fan-out. If the pilot cannot go green, stop: the problem is the infra or the contract, not 50 components.
- **Ownership prevents conflicts,** so builders in a batch run in parallel on one checkout with shared dev servers (no worktrees).
- **Scripts judge, agents fix.** The auditor is called only when a gate fails twice or for the final deep review.

## Phase 0: State and servers
1. If `docs/shadcn-port/state.json` or the oracle is missing: run the `/shadcn-plan --lazy` procedure first (Phases 0-4), then continue.
2. `ruby .claude/scripts/shadcn/port_state.rb summary`. Print it. `--resume`: statuses `done` stay done unless their oracle `source_sha` changed (then `port_state.rb reset <name>`).
3. Unless `--no-browser`: ensure both servers are up (start whichever is down with `Bash run_in_background`): Rails dev on :3000 (`bin/rails server -p 3000`; remember the app serves the public site on subdomain `""`, so the parity route is on `localhost:3000`) and the catalog on :5173 (`cd react-shadcn-catalog && npm run dev -- --port 5173 --strictPort`). Poll `curl -s -o /dev/null -w "%{http_code}" http://localhost:3000/up` and `http://localhost:5173/` until both answer (use an until-loop, max 90s). Set `SERVERS_UP=true`. Wave 0 is allowed to start before `_harness` exists; set `SERVERS_UP=false` for wave 0 builders except `_harness` self-test.
4. `mkdir -p tmp/shadcn-port`; append every step to `tmp/shadcn-port/run.log` (one line: time, wave, component, event). TodoWrite one item per wave.

## Phase 1: Main loop
Repeat until `port_state.rb next` returns `done: true`, or a stop condition fires:

1. `port_state.rb next --concurrency N` -> `{ wave, kind, batch[] }`.
2. **Plan just-in-time** (components still `pending`): dispatch `shadcn-port-planner` for the batch AND, in the same message, for the first `N` components of the next wave (pipelining, so planning is ahead of building). Set `planned` on `coverage: pass`.
3. **Build:** dispatch one `shadcn-port-builder` per batch item, all in ONE message (parallel). Prompt (self-contained): `COMPONENT`, `SERVERS_UP`, `OWNS` (infra only), paths of spec/scenarios/oracle, `MAX_RUNS=4`, list of DONE dependencies (their Phlex class names). Infra order inside wave 0: `_theme`, `_base` and `_icons` together, then `_harness`, then `_primitives` split into four family builders (overlay, floating, selection, forms) in parallel.
4. **Verify yourself (never trust the receipt):** for each returned component run, in this order, and stop at the first red:
   - `ruby .claude/scripts/shadcn/static_gate.rb --component X` (G1)
   - `bin/rubocop app/components/v2/<x>.rb app/javascript/controllers/v2` is not required for JS; run rubocop on the Ruby files only.
   - if browser: `cd react-shadcn-catalog && node ../.claude/scripts/shadcn/parity_run.mjs --component X > ../tmp/shadcn-port/X/g2.json` (G2+G3), then G4: for each `--theme slate|stone|zinc-radius0` with `--only` = the scenarios whose id starts with `variant-` or equals `default*` (cap 12), and once with `--dark`.
   - infra items: the acceptance checks in `references/infra-tasks.md`.
   Green -> `port_state.rb set X done --sha $(git rev-parse --short HEAD) --iteration n`. No browser -> `built`.
5. **Fix loop (Actor-Critic), per red component, max `--max-iter`:**
   - iteration 1: send the gate diffs back to the SAME builder via `SendMessage` if still available, else a new `shadcn-port-builder` with the diffs (capped to 40 entries, grouped by `kind`).
   - iteration 2+: dispatch `shadcn-parity-auditor` (`MODE: triage`, with the gate JSONs) and pass its `causes[].fix_target` to the builder.
   - after each fix re-run step 4. Stop early when the diff count did not drop for two consecutive iterations.
   - Exhausted -> `port_state.rb set X blocked --note "<top cause, scenario ids>"`; write `tmp/shadcn-port/X/BLOCKED.md` with the last triage. Dependents of a blocked component stay `pending` with note `dep blocked: X`.
6. **After every wave:**
   - regression: `ruby .claude/scripts/shadcn/house_check.rb --static-all`; if any file under `app/javascript/v2/`, `app/assets/tailwind/theme/` or `app/components/base.rb` changed this wave (`git diff --name-only` against the wave start sha you recorded) re-run G2 default scenarios (`--only` ids starting `default`) for all `done` components, and treat red ones as new work for the fix loop.
   - `bin/rails test test/components` (if the dir exists) must stay green.
   - print `port_state.rb summary` (compact).

## Stop conditions
- **Pilot checkpoint** (after waves with `kind: pilot`): if any pilot component is `blocked`, STOP. Write `docs/shadcn-port/PILOT_FAILURE.md` with the causes grouped by shared layer (primitive, harness, theme, contract) and the proposed fix to infra/contract. Do not fan out. With `--pilot-only`, stop here after success too.
- More than 25% of a fan-out wave blocked: stop that wave's remainder, report the common causes.
- Servers die twice: stop with the log.
- Never loop forever: global cap of `3 x components` builder dispatches; report when reached.

## Phase 2: House (final)
1. `ruby .claude/scripts/shadcn/house_check.rb --static-all` (must be clean).
2. Full G4: for every `done` component run G2 with `--theme slate` and `--theme stone` over its `default*` scenarios, and `--dark`.
3. `bin/rubocop`, `bin/rails test` (host) and `bin/rails test:with_studio` if available. V2 is additive (`Components::V2`), so existing pages must be unaffected: any new failure is a regression from shared files (`theme/*.css`, importmap, `Components::Base`) and goes back through the fix loop (`_theme` or `_harness` owner). Migrating callers from `Ui` to `V2` is out of scope for this command.
4. Dispatch ONE `shadcn-parity-auditor` per `done` interactive component in `MODE: static` only for the `Q_*` review (parallel, 6 at a time) and attach advisories to the report; MANDATORY `Q_*` findings re-open the component through the fix loop once.
5. Catalog: confirm `app/views/design_system/index.rb` lists every `done` component (generated from state by the `_harness` task's catalog generator if present; otherwise report it as a gap, do not hand-edit).

## Phase 3: Report
Write `docs/shadcn-port/REPORT.md`: totals by status; per component: status, iterations, scenarios, deviations; blocked list with the top cause and the exact file to look at; visual-regression notes from `_theme` (see theme-contract.md, "Coexistence"); theme gate result per theme; advisories; time and dispatch counts; the command to resume (`/shadcn-run all --resume`). Final chat message: 10 lines max: counts, blocked components, where the report is.

## Rules
- You never edit app/component/scenario/oracle files. Only `docs/shadcn-port/{state.json,REPORT.md,PILOT_FAILURE.md}` (state through the script) and `tmp/shadcn-port/**`.
- Every agent prompt is self-contained: paths, component, constraints, expected JSON. Agents do not see this conversation.
- Parallel means ONE message with several Agent calls. Never more than `--concurrency` builders at once.
- A gate result you ran yourself overrides any agent claim. If a script crashes (not a diff), that is `HARNESS_ERROR`: re-run once, then stop the wave and report; do not mark components done or blocked on harness crashes.
- Do not commit or push. Leave the working tree for the user's review.
