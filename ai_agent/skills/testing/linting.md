# Linting Skill (RuboCop)

**Reference: [VERIFICATION_CHECKLIST.md](../../VERIFICATION_CHECKLIST.md)**

This skill provides RuboCop standards. For complete project guidelines, see the verification checklist.

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

See [Lint and test examples](../../examples/lint-and-tests.md) for common fixes.

If style violations exist, try:

```bash
bin/rubocop -A
```

See [Lint and test examples](../../examples/lint-and-tests.md) for common fixes.
