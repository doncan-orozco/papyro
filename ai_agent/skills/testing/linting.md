# Linting Skill (RuboCop)

## Dependencies
- rubocop
- rubocop-rails
- rubocop-performance
- rubocop-minitest
- rubocop-rake
- rubocop-capybara (if system tests)
- rubocop-factory_bot (if FactoryBot)

## Rules
- Prefer safe Rails patterns (`Rails/SaveBang`, `Rails/SkipsModelValidations`).
- Favor guard clauses; avoid deep nesting.
- Use performance cops for collections and string operations.
- Enforce Minitest cops for test clarity; no focused tests.

## Output
- Generated code must be RuboCop-compliant.
- Refactor to comply; avoid disabling cops.
- Only use `rubocop:disable` with a short justification; avoid `rubocop:todo`.
