# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

Papyro is a Rails 8.1 / Ruby 4.0 editorial publishing app (Hotwire, Tailwind, Phlex, SQLite with the Solid stack). The product is **two repos of ours that are often changed together**:

- **Host `papyro`** (this repo): public site, auth/session, models, schema/migrations, fixtures, ALL locale files, skills (`.ai/skills`), CI.
- **Engine `papyro_studio`** (sibling `../papyro_studio`, `/Users/doncan/Documents/papyro_studio`): the Studio authoring UI, a mounted Rails engine on the `studio` subdomain (`PapyroStudio::*Controller`, `Studio::` concepts/components/policies, Stimulus under `controllers/studio/`). It has no dummy app; its tests boot the host. It never adds migrations or models.

The host Gemfile fetches the engine from GitHub, but `.bundle/config` (`BUNDLE_LOCAL__PAPYRO_STUDIO`) points Bundler at the local sibling, so engine edits are live in the host. Both repos are readable/editable from sessions started here (`.claude/settings.local.json` grants the engine directory). Details: `.ai/skills/architecture/references/host-coupled-engine-pattern.md`.

## Commands

```bash
bin/setup                  # install deps, prepare DB
bin/rails server           # http://localhost:3000 (Procfile.dev also runs tailwindcss:watch)
bin/dev-ssl [port]         # HTTPS on :3030; needs certs in config/ssl (see DEVELOPMENT.md)
bin/ci                     # full CI: rubocop, bundler-audit, importmap audit, brakeman, tests, system tests, seeds replant, database_consistency
bin/rubocop                # lint (rubocop-rails-omakase + rails/performance/minitest/capybara/rake)
bin/rails test             # unit/integration tests (Minitest)
bin/rails test test/path/to_test.rb:LINE   # single test
bin/rails test ../papyro_studio/test/controllers/studio/articles_controller_test.rb   # ENGINE tests run from the host root
bin/rails test:with_studio # host + engine tests (no system tests); test:system_with_studio for system tests
(cd ../papyro_studio && bin/rubocop)           # engine lint (its CI runs lint only)
bin/rails test:system      # system tests (Capybara + Cuprite)
bundle exec database_consistency
```

Subdomains matter locally: public site vs. `studio.`.

## Architecture

- **Routing**: Public routes are constrained to subdomain `""`/`www`; `studio` subdomain is the mounted `PapyroStudio::Engine` (whose own routes live in `papyro_studio/config/routes.rb`). Public routes sit inside `localized do … end` (route_translator); `/@:username` and `/settings/*` are intentionally non-localized. `root_router#route` is the smart root dispatcher.
- **Mutations go through operations**, not controllers/models: `app/concepts/<domain>/{operation,contract,validator,query,presenter,service}` (domains: articles, authors, users, admin, action_text, core, maintenance, studio). Operations use `dry-operation`/`dry-monads`/`dry-validation`; `call` returns a plain payload hash, takes explicit deps (`user:`, `locale:`…) rather than reading `Current`/HTTP state, and wraps multi-write flows in a transaction. One operation per intent (e.g. Publish vs Unpublish). Controllers only orchestrate: dispatch operation, authorize with Pundit (`app/policies`), render. On invalid model, re-render with `:unprocessable_entity`.
- **Views are Phlex** (`app/components/{ui,public,shared,landing,…}`, base in `app/components/base.rb`, `app/views`). Keep views dumb: display logic goes in presenters (SimpleDelegator), no HTML/CSS class decisions in controllers (Turbo Stream fragments render a Phlex component). `ui/` is a shadcn-style design system (catalog at `/design-system`); Tailwind via `tailwindcss-rails` with `tailwind_merge`.
- **Frontend**: importmap + Stimulus (`app/javascript/controllers`), Turbo Frames/Streams. Styles organized by domain (see `.ai/skills/phlex-view-pattern/references/stylesheet-organization.md`).
- **i18n**: Mobility (translated attributes, friendly_id-mobility slugs) + route_translator. Every user-facing string needs **English and Spanish** entries.
- **Auth**: has_secure_password sessions plus Google OAuth (omniauth); roles via Pundit.
- **Jobs/cache/cable**: Solid Queue/Cache/Cable on SQLite; Mission Control UI mounted at `/jobs`. `strong_migrations` and `bullet` are active — keep migrations safe and avoid N+1s.

## Project conventions live in `.ai/skills/`

`.github/copilot-instructions.md` is the review checklist and points to detailed per-domain guides at `.ai/skills/<domain>/SKILL.md` (controller, operation-pattern, models, query-object-pattern, presenter-pattern, phlex-view-pattern, stimulus, jobs-and-mailers, pundit-auth, i18n, seo, sqlite, testing, …). They are exposed to Claude Code via the `.claude/skills` symlink; each skill keeps a short `SKILL.md` and loads long examples from its `references/` folder on demand. Read the relevant SKILL.md before working in that area. Don't put implementation notes/docs in the repo root; they belong under `.ai/skills/<domain>/references/`.

## Slash commands and agents (`.claude/`)

- `/audit-feature [branch|range|files] [--fix] [--wide] [ticket]`: Map-Reduce audit (Bricks → Rooms/Stimulus → Slices → House) over the diff of the host AND the engine; `--fix` runs the Actor-Critic loop (max 3 iterations). Findings must cite skills as `<skill> R<n>`.
- `/plan-feature <ticket> [--epic …] [--dry-run]`: Top-Down blueprint + greenfield scaffolds, each file tagged `repo: host|studio`; writes `docs/features/<slug>/ARCHITECTURE.md`.
- `/audit-golden [case|all]`: regression test for the audit (seeded bad files in `.claude/audit-golden/`); run it after editing agent prompts, Quick Rules or the router. `ruby .claude/scripts/audit_rule_coverage.rb` reports rules never cited. Audit output lands in `tmp/audit/<slug>/` (report, ledger, optional PR comment).
- Agents live in `.claude/agents/`. Every skill starts with numbered `## Quick Rules` (R1…) that the audit cites; keep that section when editing skills.
