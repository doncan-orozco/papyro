---
description: Regression test for the audit pipeline. Runs /audit-feature on seeded bad (and one clean) files and checks it cites the expected skill rules.
argument-hint: "[case-id|all] [--no-cache]"
allowed-tools: Agent, Read, Grep, Glob, TodoWrite, Bash(git:*), Bash(shasum:*), Bash(mkdir -p tmp/audit:*), Edit(tmp/audit/**)
---

# Audit Golden Cases

Target: $ARGUMENTS (default `all`).

Purpose: after you edit an agent prompt, a skill's Quick Rules, or the router/matrix in `.claude/commands/audit-feature.md`, prove the audit still catches known violations and does not invent mandatory findings on clean code.

Cases live in `.claude/audit-golden/cases/<id>/` as `files/<repo-relative path>` (seeded code) + `expected.json` (`must_cite`, `nice_to_cite`, `must_not_have_mandatory`). The seeded files are intentionally bad (except `06-clean`) and are NOT part of the app.

## Procedure (you are the orchestrator; do not audit code yourself)
1. List the selected cases (`Glob`) and `TodoWrite` one item per case.
2. For each case, follow the `/audit-feature` pipeline (read `.claude/commands/audit-feature.md` and apply Phases 0.5, 0.7, 0.8, 1, 2, 2.5, 3 and the ledger) with these OVERRIDES:
   - Input shape is explicit files: every file under the case's `files/` folder. Route and match skills by the path RELATIVE to `files/` (e.g. `app/controllers/x.rb` is a controller), but `Read` the real file at `.claude/audit-golden/cases/<id>/files/<path>`.
   - Treat every file as `NEW_FILE` (whole file in scope). Skip git entirely (no branch resolution, no SNAP), skip Phase 0.9 mechanical checks, skip Phase 4, and do NOT write the result cache or `rule-stats.jsonl` (golden runs must not pollute real statistics).
   - Cases are independent: run all selected cases' agent calls in parallel blocks (cases in the same block).
   - Mechanical-only issues (the missing Spanish key in `05-locale-parity`) are verified by YOU with `Grep` and reported to House as `I18N_PARITY`, exactly as in Phase 0 step 6, using the case's own `config/locales` files.
3. For each case compare the final ledger with `expected.json`:
   - `FOUND`: every `must_cite` rule appears as a cited rule on an IN_SCOPE finding.
   - `MISSED`: a `must_cite` rule has no finding.
   - `BONUS`: a `nice_to_cite` rule was found (informational).
   - `FALSE POSITIVE`: a MANDATORY finding whose skill is listed in `must_not_have_mandatory`.
4. Output one table: `case | must_cite found/total | missed rules | bonus | false positives | verdict`, where verdict is PASS only if nothing is missed and there are no false positives. Finish with `GOLDEN: PASS` or `GOLDEN: FAIL (<n> cases)` and, for each failure, the likely cause (agent did not load the skill, rule too vague, router did not match the path).
5. Persist the table to `tmp/audit/golden-latest.md` with `Write`. Never edit the case files or any source file.

Keep cost in mind: this runs the whole pipeline on six small files. Use it before and after changing prompts or Quick Rules, not on every PR.
