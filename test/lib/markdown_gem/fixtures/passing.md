# Developer experience: requirements for the Md gem

Fixture for `test/lib/markdown_gem/requirements_check_test.rb`: a research doc that passes
`requirements_check.rb --area DX`. The prose is short on purpose; the shape is what the tests rely on.

## Scope

How a Rails developer installs, configures and upgrades the gem. Out of scope (WON'T): a hosted docs site in 0.1.

## Questions

1. What is the shortest path from `bundle add` to a working editor?
2. Which defaults must be right so most apps never configure anything?

## Findings

Gems that install with one generator (`bin/rails generate md:install`) and one model macro are adopted fastest.
An ERB example stays in code so the checker never reads it as a template marker: `<%= form.md_editor :body %>`.

```erb
<%= form.md_editor :body, toolbar: <default> %>
```

Prose may use HTML such as <kbd>Ctrl</kbd>+<kbd>K</kbd>, a line break <br/> and an autolink <https://example.com/autolink>.

## Requirements

Requirements are grouped by the moment the developer meets them.

### Install

- **DX-01** (MUST) `bin/rails generate md:install` sets up the gem in one command. Acceptance: a new Rails app renders the
  editor after the generator and one migration-free model line.
- **DX-02** (SHOULD) The model macro is one line. Acceptance: `has_markdown :body` is the only model change in the
  quick start.

### Upgrade

1. **DX-03** (COULD) Deprecations print the replacement call. Acceptance: every deprecation warning names the new API.

## Developer experience notes

Each requirement above adds no API surface beyond one generator and one macro.

## Open decisions

- Gem name: keep `Md` until the sign-off picks one. Recommendation: decide before 0.1.

## Sources

- https://github.com/heartcombo/devise (accessed 2026-11-03)
- https://github.com/ddnexus/pagy (accessed 2026-11-03)
- https://github.com/varvet/pundit (accessed 2026-11-03)
- https://github.com/avo-hq/marksmith (accessed 2026-11-03)
- https://github.com/basecamp/lexxy (accessed 2026-11-03)
- https://github.com/basecamp/lexxy (accessed again 2026-11-03, same source)
