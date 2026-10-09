---
description: Regression test for the shadcn port tooling. Script tier (oracle extraction, static gate, scenario coverage) + agent tier (parity auditor on seeded bad components). Run after editing the scripts, agent prompts, skills or the gate rules.
argument-hint: "[case-id-prefix|all] [--scripts-only]"
allowed-tools: Agent, Read, Write, Glob, TodoWrite, Bash(ruby:*), Bash(ls:*), Bash(mkdir -p tmp/shadcn-port:*)
---

# /shadcn-golden: does the port pipeline still catch what it must?

Target: $ARGUMENTS (default `all`). `--scripts-only` skips the agent tier (free, offline, seconds).

Cases live in `.claude/shadcn-golden/cases/<id>/` as `files/<repo-relative path>` (seeded code, NOT part of the app) + `expected.json`. Registry fixtures for six components are checked in under `.claude/shadcn-golden/oracle-fixtures/registry/`, so the run is offline and reproducible. Never edit case files or source files from this command.

| Case | Kind | Seeded problem | Must detect |
|---|---|---|---|
| 01-button-drift | static | Snapshot of the first-attempt Button (2024 classes, no data-slot, missing sizes) | `G1_SLOT_MISSING G1_TOKEN_MISSING G1_TOKEN_EXTRA G1_VARIANT_MISSING G1_DATA_ATTR_MISSING` |
| 02-switch-api-gap | static | Faithful classes, `size` option and `data-size` missing | `G1_KWARG_MISSING G1_DATA_ATTR_MISSING` |
| 03-switch-behavior | agent | Markup passes G1; controller toggles classes, Enter toggles, leaks listener + interval | `Q_STATE_VIA_CLASS Q_CLEANUP` (+ mentions Enter) |
| 04-dialog-reimplements | agent | Controller re-implements Esc/focus trap/scroll lock though primitives exist; no focus return | `Q_PRIMITIVE_REUSE Q_CLEANUP` (+ mentions focus) |
| 05-card-hardcoded-colors | static | Palette + hex colors, old shadow, root part only | `G1_HARDCODED_COLOR G1_TOKEN_EXTRA G1_TOKEN_MISSING G1_PART_MISSING G1_SLOT_MISSING` |
| 06-clean-badge | static | Control: verbatim port of badge.tsx | nothing (no G1 finding at all) |
| 07-scenario-gap | scenario | Scenario file covers half the variants/sizes | `SC_VARIANT_UNCOVERED SC_NO_DARK_TWIN` |
| 08-oracle-extract | extract | Guards the extractor (sizes, defaults, data attrs, slots, tiers, wave order) | all assertions hold |

## Procedure
1. `TodoWrite` one item per selected case.
2. **Script tier:** `ruby .claude/scripts/shadcn/golden_run.rb <target>`; parse the JSON. These results are final for `static`, `scenario` and `extract` cases; do not re-judge them. For `agent` cases the script returns `AGENT_PENDING` after confirming the G1 side (markup passes where `static_must_pass`).
3. **Agent tier** (skip with `--scripts-only`): for every `AGENT_PENDING` case dispatch `shadcn-parity-auditor` in ONE message (parallel), with a self-contained prompt:
   - `COMPONENT`: from `expected.json`, `MODE: static`, `SERVERS_UP=false`.
   - The files to review: every file under `.claude/shadcn-golden/cases/<id>/files/` (treat the path after `files/` as the repo-relative path; the shared primitives that exist in that case are the ones under its `app/javascript/v2/primitives/`).
   - Oracle: `tmp/shadcn-port/golden/oracle` (already extracted by step 2); spec/scenarios do not exist for golden cases, so ignore `Q_SCENARIO_GAP` for them.
   - Run G1 with `--files` set to the case's component `.rb` files if any and `--oracle tmp/shadcn-port/golden/oracle`.
   Validate the JSON. **Unverified claims are downgraded by you, mechanically:** any `Q_*` finding with severity MANDATORY whose `detail` contains `did not read`, `did not open`, `not opened`, `unverified` or `UNVERIFIED` (case-insensitive) is set to ADVISORY before you count it; it never blocks a PASS and never counts toward `agent_must_find` unless the case explicitly lists it. Compare `findings[].code` with `agent_must_find`; check that the `summary`/`detail` text of the findings mentions every word in `agent_must_mention` (case-insensitive); `agent_may_find` codes are BONUS. A finding the auditor cannot back with a quote of the fixture code does not count.
4. Verdict per case: `FOUND` = every must item present; `MISSED` = absent; `FALSE POSITIVE` = a `must_not_detect` code present (for `"*"`: any G1/SC finding); `BONUS` = may-find present. PASS only if nothing missed and no false positive.
5. Output one table: `case | kind | must found/total | missed | bonus | false positives | verdict`. Finish with `GOLDEN: PASS` or `GOLDEN: FAIL (<n> cases)` and, per failure, the likely cause:
   - script case failed -> regex/heuristic bug in the named script (`oracle_extract.rb`, `static_gate.rb`, `scenario_coverage.rb`) or a changed fixture;
   - agent case missed -> auditor prompt or the `radix-stimulus`/`shadcn-port` Quick Rule is too vague, or the agent did not read the skill;
   - clean case false positive -> a gate is too strict; fix the gate, never the fixture.
6. Persist the table to `tmp/shadcn-port/golden-latest.md` with `Write`.

## When to run
After changing: any script in `.claude/scripts/shadcn/`, the three `shadcn-*` agents, `shadcn-port` / `radix-stimulus` Quick Rules, or the gate vocabulary. Not on every component run.

## Not covered here (and why)
The browser tier (`parity_run.mjs`) needs both live catalogs, so it is proven by the `_harness` self-test (`infra-tasks.md`: identical probe must pass, mutated probe must fail), not by golden fixtures.
