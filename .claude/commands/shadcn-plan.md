---
description: Prepare the whole shadcn -> Phlex port: upgrade the React catalog to latest shadcn, extract the oracle, generate themes, build the wave plan and run the per-component planners (spec + scenarios). Idempotent.
argument-hint: "[--only a,b] [--refresh] [--no-bootstrap] [--lazy] [--dry-run]"
allowed-tools: Agent, Read, Write, Edit, Grep, Glob, TodoWrite, Bash(ruby:*), Bash(node:*), Bash(npm:*), Bash(npx:*), Bash(curl:*), Bash(cd:*), Bash(mkdir:*), Bash(git status:*), Bash(git diff:*), Bash(grep:*), Bash(ls:*)
---

# /shadcn-plan: oracle + plan for the full port

Arguments: $ARGUMENTS
Parse: `--only a,b` (subset), `--refresh` (re-fetch the registry), `--no-bootstrap` (skip catalog upgrade), `--lazy` (skip Phase 5, planners run just-in-time from `/shadcn-run`), `--dry-run` (stop after Phase 3 and print the plan).

Read `.ai/skills/shadcn-port/SKILL.md`, `references/parity-gates.md` and `references/infra-tasks.md` before starting. You are the orchestrator: you run scripts and dispatch `shadcn-port-planner`; you do not write component code.

The goal of this command is that `/shadcn-run` can run end-to-end with no human input afterwards. Everything ambiguous must be decided here and written down.

## Phase 0: Preflight (no agents)
1. `git status --short | head`; note the branch. Never commit. If on `main`, warn once in the final report (suggest a feature branch); continue.
2. Check `node -v` (>= 20), `ruby -v`, network (`curl -sI https://ui.shadcn.com/r/index.json`). No network and no `docs/shadcn-port/oracle/registry`: stop with a clear message.
3. `mkdir -p docs/shadcn-port/{oracle,specs,scenarios,deviations} tmp/shadcn-port`.
4. Create `docs/shadcn-port/DEVIATIONS.md` if missing (header + empty table: component, deviation, reason, approved-by).
5. **Self-check of the tooling:** `ruby .claude/scripts/shadcn/command_lint.rb` must pass (every script, flag, subcommand, rake task, agent, slash command and reference named in the commands, agents and skills must exist). On findings STOP and report them: the docs are telling you to run something that does not exist.

## Phase 1: Oracle (script)
`ruby .claude/scripts/shadcn/oracle_extract.rb [--only ...] [--refresh]`. Expect ~60 manifests, `graph.json`, `VERSION.json`. Print the tier tally and any "skipped" lines (components absent from the style are reported, not failed). Record `docs/shadcn-port/oracle/VERSION.json` digest in the final report.

## Phase 2: React catalog = the oracle (skip with `--no-bootstrap` when already verified) **Skipped entirely with `--dry-run`** (a dry run changes nothing outside `docs/shadcn-port/` and `tmp/`).
The catalog is only a valid oracle if it runs exactly the registry source. Verify first:
`ruby .claude/scripts/shadcn/oracle_extract.rb --verify-catalog react-shadcn-catalog/src/components/ui`.
If it passes, skip to Phase 3. Otherwise (first run, or the old Tailwind 3 / React 18 catalog):
1. In `react-shadcn-catalog/`: move the current `src/components/ui` to `tmp/shadcn-port/old-catalog-ui/` (do not delete).
2. Upgrade stack to what the registry style needs: `react@19 react-dom@19 tailwindcss@4 @tailwindcss/vite tw-animate-css radix-ui lucide-react class-variance-authority clsx tailwind-merge`, dev: `shadcn typescript vite @vitejs/plugin-react @types/react @types/react-dom playwright`; remove `tailwind.config.js`, `postcss.config.js`, the per-package `@radix-ui/*` entries and `tailwindcss-animate`. Use `npm install` (not `--force`).
3. `components.json`: style `new-york`, `rsc:false`, `tailwind.css: "src/index.css"`, `baseColor: "zinc"`, `cssVariables: true`, no config path (Tailwind v4), aliases as before. `vite.config.ts` uses `@tailwindcss/vite`, alias `@` -> `src`, alias `@scenarios` -> `../docs/shadcn-port/scenarios`, `server.fs.allow: [".."]`.
4. `npx shadcn@latest init` is interactive-hostile: run `npx shadcn@latest add button --overwrite --yes` first (it creates the globals file when absent). Then REPLACE the catalog `src/index.css` body with the host-theme imports (`theme-contract.md`: tailwindcss, tw-animate-css, `@host-theme/theme.css`, `@host-theme/tokens.css`) and keep the generated file as `tmp/shadcn-port/shadcn-init-index.css`. Copy that file to `react-shadcn-catalog/src/index.css.init` so `theme_sync.rb --check-tokens` can compare `tokens.css` against it (point `CATALOG_CSS` at it). Vendor the CSS with `theme_sync.rb --vendor`.
5. `npx shadcn@latest add --all --overwrite --yes`. Items the CLI cannot install are listed in the report, not fatal.
6. Re-run `--verify-catalog`. Any `G0_CATALOG_DRIFT` => fix the catalog (re-add that item) until clean; never edit oracle files to match the catalog.
7. `npm run build` must pass (type check). Keep `App.tsx` as the visual catalog but the harness (`_harness` task) mounts under `#/parity/...`.

## Phase 3: Theme + plan state (scripts)
1. Presets exist already; regenerate only with `--refresh`: `ruby .claude/scripts/shadcn/theme_sync.rb --emit-presets`. Run `bin/rails theme:check`-equivalent `ruby -Ilib -rshadcn/theme -e 'p Shadcn::Theme.check'` and report warnings (the host `theme.css` must be zinc at this point unless the user changed it).
2. `ruby .claude/scripts/shadcn/port_state.rb init [--only ...]` (keeps existing statuses when re-run with the same oracle digest; if the digest changed, mark every component whose `source_sha` changed as `pending`, and say which).
3. `ruby .claude/scripts/shadcn/port_state.rb summary` and show the wave table. Wave 0 infra, then pilot (button, switch, tooltip, dropdown-menu, select; then dialog), then fan-out waves in dependency order.
`--dry-run`: stop here and print: waves, tier tally, third-party libraries needed (union of manifests' `third_party`) and which are already pinned in `config/importmap.rb` (flag the missing ones as pin tasks for the matching components).

## Phase 4: Migration map of the legacy components (no agents, informational)
The port is from scratch in `app/components/v2/`; legacy `app/components/ui/*` stays untouched. For every legacy `app/components/ui/*.rb` that has a manifest, count callers (`grep -rln "Components::Ui::<Class>" app test ../papyro_studio/app ../papyro_studio/test`) and write `docs/shadcn-port/CALLERS.md` (component, legacy file, caller count, top 5 callers). It is only for the later Ui -> V2 migration and is NOT given to planners or builders.

## Phase 5: Per-component planning (agents, skipped with `--lazy`)
Dispatch `shadcn-port-planner` for every component in state `pending`, in parallel blocks of at most 6, ordered by wave (pilot first so problems surface early). Prompt per component (self-contained, include):
- `COMPONENT`, manifest path, src path, `TIER`, `registry_dependencies` already planned/DONE (names only), existing primitives list, and the instruction that `app/components/ui/*` must not be read.
Collect each JSON receipt, then **validate the output yourself, never trust the receipt**: `ruby .claude/scripts/shadcn/planner_check.rb --component <name>` (spec sections, every part and data-slot named, scenario JSON shape, React-named props, valid steps, enough scenarios, full variant/state coverage, deviations with a reason). On findings, send them back verbatim (max 30) to the planner ONCE; if still failing keep the component `pending` with `--note "planner_check: <codes>"`. Only a passing check -> `port_state.rb set <name> planned`. On `blockers` -> keep `pending` with `--note`. Re-dispatch a planner once if its receipt is malformed. Never re-plan `planned/built/done` unless `--refresh` changed its `source_sha`.

## Phase 6: Plan report
Write `docs/shadcn-port/PORT_PLAN.md`: oracle version/digest; wave table (from `port_state.rb summary`); per component: tier, #scenarios, planned deviations, third-party libs; the blockers list; estimated run size (components x average scenarios). End with the exact next command: `/shadcn-run all`.

## Rules
- Idempotent: running twice changes nothing unless the oracle changed.
- Planners only write spec/scenarios/deviations; verify with `git status` that no other files changed after Phase 5.
- Do not start servers here; do not build components here.
