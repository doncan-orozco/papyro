---
description: Show the board of an epic: counts per state, who holds what, stale claims, ready items, items waiting for a human.
argument-hint: "--epic <slug> [--reap]"
allowed-tools: Bash(ruby:*)
---

# /work-status

Arguments: $ARGUMENTS
Read-only unless `--reap` is given. Never touch `gh` directly (epic-flow R2).

1. `ruby .claude/scripts/epic/work_board.rb status --epic S`. Print counts and one table: `#`, title, wave, stage, state (`done`, `in-progress`, `ready`, `waiting`, `blocked`), holder, lease expiry. Mark rows with `stale_claim: true` as STALE.
2. For every `blocked` item print its last `blocker` note: `ruby .claude/scripts/epic/work_board.rb show N --epic S` (the `notes` array).
3. With `--reap`: `ruby .claude/scripts/epic/work_board.rb reap --epic S` and print what was freed.
4. End with the single most useful next step: `/work --epic S` if something is ready, which items a human must unblock, or `epic done`.
