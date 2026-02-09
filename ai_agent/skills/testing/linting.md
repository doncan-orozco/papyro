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

## Rules
- Prefer safe Rails patterns (`Rails/SaveBang`, `Rails/SkipsModelValidations`).
- Favor guard clauses; avoid deep nesting.
- Use performance cops for collections and string operations.
- Enforce Minitest cops for test clarity; no focused tests.

## Output
- Generated code must be RuboCop-compliant.
- Refactor to comply; avoid disabling cops.
- Only use `rubocop:disable` with a short justification; avoid `rubocop:todo`.

## AI Agent Workflow

**CRITICAL: When making code changes, ALWAYS run RuboCop before tests:**

```bash
bin/rubocop && bin/rails test
```

**Workflow:**
1. Make code changes
2. Run `bin/rubocop` to check for style violations
3. If violations exist, run `bin/rubocop -A` to auto-fix
4. Run `bin/rails test` to verify functionality
5. Only report success if both RuboCop and tests pass

**Note:** Users can run `bin/rails test` directly without RuboCop, but AI agents must always ensure code quality by running both.
