---
name: linting
description: RuboCop linting standards and configuration for Rails applications. Use when setting up or configuring linting, reviewing code style, or ensuring code quality standards. Covers RuboCop dependencies, safe Rails patterns, guard clauses, performance optimizations, and test clarity.
---

# Linting (RuboCop)

## Dependencies
- rubocop
- rubocop-rails
- rubocop-performance
- rubocop-minitest
- rubocop-rake
- rubocop-capybara (if system tests)
- rubocop-factory_bot (if FactoryBot)

## Focus Areas (Examples)
- Safe Rails patterns (`Rails/SaveBang`, `Rails/SkipsModelValidations`)
- Guard clauses to avoid deep nesting
- Performance cops for collections and string operations
- Minitest cops for test clarity

## Suggested Workflow

```bash
bin/rubocop
bin/rails test
```

See [Lint and test examples](examples/lint-and-tests.md) for common fixes.

If style violations exist, try:

```bash
bin/rubocop -A
```

See [Lint and test examples](examples/lint-and-tests.md) for common fixes.
