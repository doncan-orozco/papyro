# Papyro Guidelines Verification Checklist

Use this checklist before committing code to ensure full compliance with Papyro standards.

## 🏗️ Architecture & Organization

### Controllers
- [ ] Thin controller (request → Operation/Service → response)
- [ ] No business logic
- [ ] Explicit data passed to view/component
- [ ] Handle Operation results using `result.success?` / `result.failure?` (Trailblazer returns `Trailblazer::Operation::Result`, not Dry::Monads)
- [ ] Authorization checks BEFORE calling Operation (find with scope: `Current.user.articles.find_by!`)
- [ ] Format validation errors from Operation failures for display
- [ ] **For Create**: Pass params with ownership: `Op::Create.call(params: params.merge(user_id: user.id))`
- [ ] **For Update/Destroy**: Pass pre-authorized model: `Op::Update.call(model: article, params: params)`
- [ ] Never pass `user_id` in update params (ownership doesn't change)

### Operations (Trailblazer)
- [ ] Live in `app/concepts/{domain}/operation/`
- [ ] Railway flow: Model → Contract::Build → Validate → Logic → Persist → Broadcast
- [ ] Return Result monads (Success/Failure)
- [ ] Always set `ctx[:errors]` on failure (as Hash with field keys)
- [ ] Always set `ctx[:model]` on success (for main domain object)
- [ ] For chained operations: call first Op, check result, pass ctx to next Op
- [ ] No hardcoded error messages (use I18n from contracts)
- [ ] **For Update/Destroy**: Receive pre-authorized `model:` param from controller (no find step)
- [ ] **For Create**: Build new model from params
- [ ] Never update ownership fields (`user_id`) in update operations

### Models
- [ ] Persistence only
- [ ] Database constraints in migrations (null: false, unique indexes, foreign keys)
- [ ] NO ActiveRecord validations for business logic (use Contracts instead)
- [ ] Optional: Safety-net validations for data integrity (paranoid mode, should never trigger)
- [ ] Safety-net validations apply in all environments
- [ ] NO callbacks
- [ ] NO business logic
- [ ] NO scopes or query methods in models (use Query Objects)

### Services
- [ ] Single responsibility and focused scope
- [ ] Stateless when possible
- [ ] Injected into Operations (no global dependencies)
- [ ] Return Result objects or raise specific exceptions

### Queries (Read Model)
- [ ] Live in `app/queries/`
- [ ] Use query objects for read logic (no model scopes)
- [ ] Keep queries focused and composable
- [ ] Return ActiveRecord relations (chainable) or arrays
- [ ] Name queries by intent: `{Domain}::{Purpose}Query`

### Contracts (Dry-Validation)
- [ ] Live in `app/concepts/{domain}/contract/`
- [ ] ALL validations here
- [ ] Schema-based validation
- [ ] Error messages use I18n: `key.failure(I18n.t('errors.messages.key_name'))`
- [ ] All error messages translated in both English and Spanish

## 🎨 Frontend

### Views
- [ ] Inherit from `Views::Base`
- [ ] Live in `app/views/{domain}/`
- [ ] Module namespace: `Views::{Domain}::{Action}`
- [ ] Phlex only (no ERB/HAML)
- [ ] Scoped i18n keys: `t(".title")`

### Components
- [ ] Inherit from `Components::Base`
- [ ] Live in `app/components/{domain}/`
- [ ] Module namespace: `Components::{Domain}::{Name}`
- [ ] Pure functions (no side effects)
- [ ] All data via constructor arguments
- [ ] Support `**attrs` for Stimulus

### Stimulus
- [ ] Live in `app/javascript/controllers/{domain}/`
- [ ] Named as `domain--feature_controller.js`
- [ ] Use `static targets`, `values`, `outlets`
- [ ] Dispatch custom events (loose coupling)
- [ ] Organized by domain

### Styling
- [ ] Tailwind utility classes only
- [ ] No custom CSS (unless absolutely required)
- [ ] Use shadcn/ui patterns

## 🌐 Internationalization (I18n)

### File Structure
- [ ] Domain-based: `config/locales/{en,es}/{domain}.yml`
- [ ] Separate files: `app.yml` (shared), `{domain}.yml`, `components.yml`, `models.yml`
- [ ] Both English and Spanish translations required

### Key Naming (Fully-Qualified)
- **Views**: `t("articles.show.title")` — always fully-qualified, NO relative keys like `t(".title")`
- **Components**: `t("components.ui.button.submit")` — full path from components namespace
- **Operations**: `t("articles.operations.create.success")` — grouped under domain
- **Errors**: `t("articles.errors.title_blank")` — domain-scoped for context-specific messages
- **Models**: `Article.model_name.human` or `Article.human_attribute_name(:title)`

### Date/Time Formatting
- [ ] Use `I18n.l(date, format: :long)` — NEVER use `strftime`
- [ ] Define formats in `config/locales/{en,es}/app.yml`
- [ ] Use named formats: `:short`, `:long`, `:month_year`, `:time_only`

### Number/Currency Formatting
- [ ] Use `number_to_currency(price)` — NEVER manually format with `"$#{price}"`
- [ ] Use `number_with_delimiter(count)` for large numbers
- [ ] Define currency formats in `config/locales/{en,es}/app.yml`

### Translation Structure
```yaml
# config/locales/en/articles.yml
en:
  articles:
    show:                    # View translations
      title: "Article"
    operations:              # Operation messages
      create:
        success: "Created"
    errors:                  # Domain-scoped errors
      title_blank: "Title cannot be blank"
    attributes:              # Field names
      title: "Title"
```

See [skills/frontend/i18n.md](skills/frontend/i18n.md) for complete patterns and examples.

## 🔄 Turbo Frames

### Frame Design
- [ ] Represents complete **domain concept** (not just UI)
- [ ] Has dedicated **controller action**
- [ ] Wrapped in matching `turbo-frame_tag` with same ID
- [ ] Response contains `turbo_frame_tag` with content

### Loading Strategy
- **Eager-loading**: No `loading` attribute (loads immediately)
  - [ ] Critical content
  - [ ] Above the fold
- **Lazy-loading**: `loading: :lazy`
  - [ ] Below the fold
  - [ ] Optional sections

### Routes
- [ ] Named route: `get "articles/featured", to: "articles#featured", as: :featured_articles`
- [ ] Route helper used in view: `featured_articles_path`

## 📡 Channels (Action Cable)

- [ ] Authorize in `subscribed`
- [ ] Use `stream_for` with domain model instances
- [ ] Keep channels minimal; delegate logic to Operations
- [ ] Broadcast from Operations after successful changes
- [ ] Handle Operation failures with `if result.failure?` checks

## 🧰 Background Jobs (Solid Queue)

- [ ] Use Solid Queue (no Redis)
- [ ] Jobs are idempotent
- [ ] Pass IDs, not ActiveRecord objects
- [ ] Use `limits_concurrency` for resource control when needed
- [ ] Use `discard_on` for non-retryable errors

## 🗄️ Database (SQLite)

- [ ] Migrations follow strong_migrations patterns (see [skills/database/sqlite.md](skills/database/sqlite.md#safe-migration-patterns-strong_migrations))
- [ ] NO direct column changes (type, rename, removal → multi-step)
- [ ] NO `safety_assured` without 3-deploy strategy
- [ ] Backfills use `disable_ddl_transaction!` + batching + sleep
- [ ] **MANDATORY: Run `bundle exec database_consistency` after all migrations**
- [ ] Use SQLite production optimizations (WAL, busy_timeout)
- [ ] Add indexes for frequent queries
- [ ] Use transactions for multi-step operations
- [ ] Database constraints in migrations (null: false, unique indexes, foreign keys)
- [ ] Foreign keys validated: `validate: false` then separate validation migration

## 🧠 Caching (Solid Cache)

- [ ] Use Solid Cache for caching (no Redis)

## 🚚 Deployment (Kamal)

- [ ] Use Kamal 2 for deployment
- [ ] Use SQLite with volumes for persistence
- [ ] Configure healthchecks

## Task/Issue Requirements

- [ ] List the exact file paths to create or edit
- [ ] Specify route helpers, HTTP verbs, and paths when routes change
- [ ] Specify Turbo Frame IDs and ensure responses wrap matching `turbo_frame_tag`

## ⚡ Error Handling & Authorization

See [skills/backend/error-handling.md](skills/backend/error-handling.md) for patterns on:
- Authorization at controller level
- Handling Operation failures (controllers, channels, jobs)
- Result extraction patterns
- Required context keys (`ctx[:model]`, `ctx[:errors]`)

## 🚫 Anti-Patterns

**Backend patterns:** See [skills/backend/anti-patterns.md](skills/backend/anti-patterns.md) for what NOT to do:
- [ ] NO business logic in models → [See examples](skills/backend/anti-patterns.md#model-anti-patterns)
- [ ] NO validations in models (use Contracts) → [See examples](skills/backend/anti-patterns.md#-dont-validations-in-models)
- [ ] NO callbacks in models → [See examples](skills/backend/anti-patterns.md#-dont-callbacks-in-models)
- [ ] NO hardcoded error messages (use I18n) → [See examples](skills/backend/anti-patterns.md#-dont-hardcoded-error-messages)
- [ ] NO passing ActiveRecord objects to jobs → [See examples](skills/backend/anti-patterns.md#-dont-passing-activerecord-objects-to-jobs)
- [ ] NO query scopes in models (use Query Objects) → [See examples](skills/backend/anti-patterns.md#-dont-query-logic-in-models-scopes)
- [ ] NO implicit dependencies → [See examples](skills/backend/anti-patterns.md#-dont-implicit-dependencies)
- [ ] NO accessing internal Operation ctx keys → [See examples](skills/backend/anti-patterns.md#-dont-accessing-internal-operation-context)
- [ ] NO missing Turbo Frame wrapping → [See examples](skills/backend/anti-patterns.md#-dont-missing-turbo-frame-wrapping)
- [ ] NO hardcoded strings in views (use i18n) → [See examples](skills/backend/anti-patterns.md#-dont-hardcoded-strings-in-views)

**Database patterns:** See [skills/database/anti-patterns.md](skills/database/anti-patterns.md) - Migration safety:
- [ ] NO direct column removals (use 3-step rollout) → [See examples](skills/database/anti-patterns.md#-dont-remove-columns-directly)
- [ ] NO single-step column type changes (6-step migration) → [See examples](skills/database/anti-patterns.md#-dont-change-column-type-in-single-step)
- [ ] NO backfills in transactions (batch + sleep) → [See examples](skills/database/anti-patterns.md#-dont-backfill-data-in-transaction-with-column-addition)
- [ ] NO direct NOT NULL on existing columns (check constraint strategy) → [See examples](skills/database/anti-patterns.md#-dont-set-not-null-on-existing-column)

## 🏗️ Common Development Patterns

See [skills/backend/architecture.md](skills/backend/architecture.md#common-development-patterns) for step-by-step guides:
- Adding a page (controller + view + route + i18n)
- Adding a component (Phlex component + i18n + **attrs)
- Adding a Turbo Frame (frame + route + lazy loading)
- Adding Stimulus interaction (controller + data attributes)

## ✅ Pre-Commit Verification

Before committing:

1. **Files Created/Modified**
   - [ ] All views inherit from `Views::Base`
   - [ ] All components inherit from `Components::Base`
   - [ ] Proper namespaces used
   - [ ] Files in correct directories

2. **I18n**
   - [ ] All hardcoded user text has translation keys
   - [ ] English and Spanish versions provided
   - [ ] Domain-based file structure
   - [ ] Keys follow naming conventions

3. **Business Logic**
   - [ ] No business validations in models (only safety-net validations allowed)
   - [ ] Safety-net validations apply in all environments
   - [ ] Database constraints defined in migrations
   - [ ] All business validations in Contracts
   - [ ] No callbacks in models
   - [ ] No scopes or query methods in models (use Query Objects)
   - [ ] No business logic in controllers
   - [ ] Logic in Operations/Services

4. **Code Quality**
   - [ ] No implicit dependencies
   - [ ] All data passed explicitly
   - [ ] Pure components (no side effects)
   - [ ] Thin controllers
   - [ ] Clear, explicit flow

5. **Architecture**
   - [ ] Domain concepts properly separated
   - [ ] Turbo Frames have clear purpose
   - [ ] Stimulus controllers scoped to features
   - [ ] Routes named and documented

## 🧹 Lint & Code Quality (RuboCop)

All code MUST pass RuboCop linting.

### Run locally before committing:
```bash
bin/rubocop                    # Check all files
bin/rubocop --fix-layout       # Auto-fix formatting issues
bin/rubocop app/controllers/   # Check specific directory
```

### Common RuboCop rules to watch:
- [ ] Line length ≤ 120 characters
- [ ] Proper indentation (2 spaces)
- [ ] No trailing whitespace
- [ ] Method/variable names use snake_case
- [ ] Classes use PascalCase
- [ ] No unnecessary parentheses: `method(arg)` not `method arg`
- [ ] Use double quotes for strings (unless string contains quotes)
- [ ] No commented-out code
- [ ] Comments explain WHY, not WHAT (Ruby is self-documenting; see [anti-patterns](skills/backend/anti-patterns.md#code-commenting-anti-patterns))
- [ ] Proper spacing around operators: `a = b`, not `a=b`
- [ ] Empty lines between methods
- [ ] Block parameters properly formatted: `{ |x| x }` not `{|x|x}`

### Rails + Minitest specific:
- [ ] No `test_` prefix in describe blocks (use `describe` syntax)
- [ ] Factory Bot syntax correct: `create(:user)` not `FactoryBot.create(:user)`
- [ ] Assertions use proper syntax: `assert_equal`, `assert_predicate`, not `assert` with manual comparisons

## ✅ Testing Requirements

All new features MUST have tests.

### Types of tests:
- **Unit tests**: Model validations, Contract schemas, Operation logic
- **Integration tests**: Controller → Operation → Database flow
- **System tests**: User workflows, JavaScript interactions, Turbo behavior

### Test organization:
```
test/
├── models/          # Unit tests for models
├── concepts/        # Operation + Contract tests
├── controllers/     # Controller integration tests
├── system/          # Full user journey tests
└── test_helpers/    # Shared test utilities
```

### Before committing - run all tests:
```bash
rake test                        # Run all tests
rake test TEST=test/models/      # Run specific test directory
bin/rails test test/models/user_test.rb  # Run specific file
```

### Test expectations:
- [ ] All new code has corresponding tests
- [ ] Tests verify both success and failure paths
- [ ] Fixtures used for test data (see `test/fixtures/`)
- [ ] Tests use proper assertions: `assert`, `assert_equal`, `assert_match`
- [ ] System tests verify user interactions with JavaScript/Turbo
- [ ] No hardcoded test data (use factories or fixtures)
- [ ] Tests are isolated (no dependencies between tests)
- [ ] Test database is clean before each test

## 🔒 Security Scanning

Project includes automated security checks (run in CI):

### Local pre-commit checks:
```bash
bin/brakeman --no-pager          # Rails security vulnerabilities
bin/bundler-audit                # Gem security vulnerabilities
bin/importmap audit              # JavaScript dependency vulnerabilities
```

### Security checklist:
- [ ] No SQL injection risks (use parameterized queries)
- [ ] No hardcoded credentials (use credentials.yml.enc)
- [ ] No password exposure in logs
- [ ] CSRF protection enabled (Rails default)
- [ ] Authentication required for admin routes
- [ ] User input validated and escaped
- [ ] No vulnerable gem versions (checked by bundler-audit)

## 🚀 Common Patterns

For detailed implementation patterns and examples, see:

- **[skills/backend/error-handling.md](skills/backend/error-handling.md)** - Authorization & error handling patterns
- **[skills/backend/anti-patterns.md](skills/backend/anti-patterns.md)** - ❌ What NOT to do / ✅ What to do
- **[skills/backend/architecture.md](skills/backend/architecture.md)** - Step-by-step development guides
- **[examples/](examples/)** - Code examples and tutorials

---

**Remember:** This checklist verifies compliance. For learning and detailed patterns, dive into the skill files above.