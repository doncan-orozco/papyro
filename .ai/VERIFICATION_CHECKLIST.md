# Papyro Guidelines Verification Checklist

Use this checklist before committing code to ensure full compliance with Papyro standards.

## 🏗️ Architecture & Organization

### Phlex Components (CRITICAL for UI Components)
- [ ] **EVERY component class that accepts keyword arguments MUST have `initialize(**attrs)` method** (including child/nested classes)
- [ ] Apply pattern to root component AND all child components (e.g., if building `Tabs.rb`, both `TabsList` and `TabsTrigger` need initialize)
- [ ] Without this, instantiation like `Component.new(data: {...})` causes ArgumentError
- [ ] Pattern: `def initialize(**attrs); @attrs = attrs; end` at minimum
- [ ] Pass keyword arguments when instantiating: `Calendar.new(mode: :single, data: {...})`

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
- [ ] Fully-qualified i18n keys: `t("articles.index.title")`

### Components

**Base Setup:**
- [ ] Inherit from `Components::Base`
- [ ] Live in `app/components/{domain}/` or `app/components/ui/` for design system
- [ ] Module namespace: `Components::{Domain}::{Name}` or `Components::Ui::{Name}`
- [ ] All components have `initialize(**attrs)` with `@attrs = attrs`
- [ ] Pure functions (no side effects)
- [ ] All data via constructor arguments
- [ ] Support `**attrs` for Stimulus data attributes
- [ ] If component sets internal `data-*` attributes, merge with caller `data` hash and preserve required internal keys

**Compound Components (MANDATORY for All Multi-Part Components):**
- [ ] Applies to: Accordion, Alert, AlertDialog, Avatar, Breadcrumb, Calendar, Card, Carousel, Collapsible, Command, ContextMenu, DataTable, Dialog, Dropdown, Form, HoverCard, MenuBar, NavigationMenu, Pagination, Popover, RadioGroup, Resizable, ScrollArea, Sheet, Table, Tabs, Toast, ToggleGroup
- [ ] Parent yields itself: `div { yield self if block }`
- [ ] Each child part has a helper method on parent: `def list(**attrs, &block); render List.new(**attrs, &block); end`
- [ ] Each child is a nested class: `class List < Components::Base`
- [ ] EVERY nested child class has `initialize(**attrs)` storing to `@attrs`
- [ ] EVERY nested child class has private `classes` method with the styles
- [ ] Default Stimulus controller injected in parent's `initialize` if interactive (e.g., `DropdownMenu`, `Dialog`)
  ```ruby
  def initialize(**attrs)
    @attrs = attrs
    @attrs[:data] ||= {}
    @attrs[:data][:controller] = "ui--dropdown" unless @attrs[:data][:controller]
  end
  ```
- [ ] Interactive child helper methods set required `data-*` defaults and merge caller data (do not force repetition in views)
  ```ruby
  # Parent helper method should inject required target/action defaults
  def trigger(**attrs, &block)
    render Trigger.new(**with_required_data(attrs, target: "trigger", required_action: "click->ui--dropdown#toggle"), &block)
  end
  ```
- [ ] For DropdownMenu specifically, defaults are enforced in component helpers:
  - `trigger` includes `data: { ui__dropdown_target: "trigger", action: "click->ui--dropdown#toggle" }`
  - `content` includes `data: { ui__dropdown_target: "content", action: "keydown->ui--dropdown#navigate" }`
  - `item` includes `data: { ui__dropdown_target: "item", action: "click->ui--dropdown#select keydown->ui--dropdown#itemKeydown" }`
- [ ] For Switch specifically, defaults are enforced in component helpers:
  - parent includes `data: { controller: "ui--switch", action: "click->ui--switch#toggle keydown->ui--switch#keydown" }`
  - `checked:` prop maps to `data: { ui__switch_checked_value: ... }` unless caller already set it
  - `thumb` includes `data: { ui__switch_target: "thumb" }`
- [ ] For Tabs specifically, defaults are enforced in component helpers:
  - parent includes `data: { controller: "ui--tabs" }`
  - `trigger` includes `data: { ui__tabs_target: "trigger", action: "click->ui--tabs#select keydown->ui--tabs#keydown" }`
  - `content` includes `data: { ui__tabs_target: "content" }`
- [ ] For Select specifically, defaults are enforced in component helpers:
  - parent `Select` includes `data: { controller: "ui--select" }` and supports `default_value:`/`value:` plus `placeholder:` defaults
  - `select.trigger` includes `data: { ui__select_target: "trigger", action: "click->ui--select#toggle keydown->ui--select#navigate" }`
  - `select.content` includes `data: { ui__select_target: "content" }`
  - `select.item` includes `data: { ui__select_target: "item", action: "click->ui--select#selectItem" }`
  - `select.value` includes `data: { ui__select_target: "valueDisplay" }`
- [ ] For Tooltip specifically, defaults are enforced in component helpers:
  - parent `Tooltip` includes `data: { controller: "ui--tooltip" }` and supports `delay:`/`placement:`/`offset:` defaults
  - `tooltip.trigger` includes `data: { ui__tooltip_target: "trigger", action: "mouseenter->ui--tooltip#show mouseleave->ui--tooltip#hide focus->ui--tooltip#show blur->ui--tooltip#hide" }`
  - `tooltip.content` includes `data: { ui__tooltip_target: "content" }`
- [ ] For Popover specifically, defaults are enforced in component helpers:
  - parent `Popover` includes `data: { controller: "ui--popover", ui__popover_open_value: false }` and supports `placement:`/`offset:` defaults
  - `popover.trigger` includes `data: { ui__popover_target: "trigger", action: "click->ui--popover#toggle" }`
  - `popover.content` includes `data: { ui__popover_target: "content" }`
- [ ] For HoverCard specifically, defaults are enforced in component helpers:
  - parent `HoverCard` includes `data: { controller: "ui--hover-card", ui__hover_card_open_value: false }` and supports `delay:`/`placement:`/`offset:` defaults
  - `hover_card.trigger` includes `data: { ui__hover_card_target: "trigger", action: "mouseenter->ui--hover-card#show mouseleave->ui--hover-card#hide focusin->ui--hover-card#show focusout->ui--hover-card#hide" }`
  - `hover_card.content` includes `data: { ui__hover_card_target: "content", action: "mouseenter->ui--hover-card#show mouseleave->ui--hover-card#hide focusin->ui--hover-card#show focusout->ui--hover-card#hide" }`
- [ ] For Sheet specifically, defaults are enforced in component helpers:
  - parent `Sheet` includes `data: { controller: "ui--dialog", ui__dialog_open_value: false }`
  - `sheet.trigger` includes `data: { action: "click->ui--dialog#open" }`
  - `sheet.content` includes `data: { ui__dialog_target: "content", dialog_transition: "slide" }` and renders overlay with `data: { ui__dialog_target: "overlay" }`
- [ ] For Dialog specifically, defaults are enforced in component helpers:
  - parent `Dialog` includes `data: { controller: "ui--dialog", ui__dialog_open_value: false }`
  - `dialog.trigger` includes `data: { action: "click->ui--dialog#open" }`
  - `dialog.content` includes `data: { ui__dialog_target: "content" }` and renders overlay with `data: { ui__dialog_target: "overlay" }`
- [ ] For AlertDialog specifically, defaults are enforced in component helpers:
  - parent `AlertDialog` includes `data: { controller: "ui--dialog", ui__dialog_open_value: false }`
  - `alert_dialog.trigger` includes `data: { action: "click->ui--dialog#open" }`
  - `alert_dialog.content` includes `data: { ui__dialog_target: "content" }` and renders overlay with `data: { ui__dialog_target: "overlay" }`
  - `alert_dialog.cancel` and `alert_dialog.action` include `data: { action: "click->ui--dialog#close" }`
- [ ] Legacy compatibility aliases at end of parent class: `DropdownMenuTrigger = Trigger`
- [ ] Views use only helper methods (no child `.new` calls): `dropdown.trigger { ... }` NOT `Components::Ui::DropdownMenuTrigger.new`

**Design System:**
- [ ] Design system catalog (`app/views/design_system/index.rb`) updated for new UI components
- [ ] English + Spanish translations added in `config/locales/{en,es}/design_system.yml`
- [ ] New component or variant tested in catalog with interactive demo

### Stimulus
- [ ] Live in `app/javascript/controllers/{domain}/`
- [ ] Named as `domain--feature_controller.js`
- [ ] Use `static targets`, `values`, `outlets`
- [ ] Dispatch custom events (loose coupling)
- [ ] Organized by domain
- [ ] Avoid calling close handlers on initial connect when the component is closed; do not restore focus or scroll on first render
- [ ] Only return focus to triggers after the component has actually been opened at least once
- [ ] Overlay components (Dropdown/Select/Tooltip) use stable positioning (`strategy: 'fixed'`) and remain hidden until coordinates are applied
- [ ] Remove debug `console.log` statements before finalizing

### Styling
- [ ] Tailwind utility classes only
- [ ] No custom CSS (unless absolutely required)
- [ ] Use shadcn/ui Radix patterns (see [skills/design-system/](skills/design-system/))
- [ ] Semantic color tokens (NOT hardcoded colors): `bg-primary`, `text-destructive`
- [ ] OKLCH color space for CSS variables (see [skills/design-system/references/css-variables-guide.md](skills/design-system/references/css-variables-guide.md))
- [ ] When converting shadcn components, follow [skills/design-system/references/shadcn-conversion-guide.md](skills/design-system/references/shadcn-conversion-guide.md)

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

### Reform + Dry-Schema Messages
- [ ] `Dry::Schema.config.messages.backend = :i18n` configured in initializer when using Reform dry validations
- [ ] Keep predicate fallback messages generic in `dry_schema.errors.*` (shared across forms)
- [ ] Avoid domain-specific copy under `dry_schema.errors.rules.<field>.*` (field name collisions across forms)
- [ ] Use form/domain-scoped keys for business/context rules, e.g. `articles.forms.validation.*`
- [ ] In Reform `rule(...)` blocks, use explicit `key.failure(I18n.t("...") )` for model-specific messages
- [ ] If a setter normalizes input (e.g. `title.strip`), prefer schema `filled?` for blank checks and avoid redundant whitespace-only predicates

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

See [skills/i18n/SKILL.md](skills/i18n/SKILL.md) for complete patterns and examples.

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

- [ ] Migrations follow strong_migrations patterns (see [skills/sqlite/SKILL.md](skills/sqlite/SKILL.md#safe-migration-patterns-strong_migrations))
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

See [skills/error-handling/SKILL.md](skills/error-handling/SKILL.md) for patterns on:
- Authorization at controller level
- Handling Operation failures (controllers, channels, jobs)
- Result extraction patterns
- Required context keys (`ctx[:model]`, `ctx[:errors]`)

## 🚫 Anti-Patterns

**Backend patterns:** See [skills/backend-anti-patterns/SKILL.md](skills/backend-anti-patterns/SKILL.md) for what NOT to do:
- [ ] NO business logic in models → [See examples](skills/backend-anti-patterns/SKILL.md#model-anti-patterns)
- [ ] NO validations in models (use Contracts) → [See examples](skills/backend-anti-patterns/SKILL.md#-dont-validations-in-models)
- [ ] NO callbacks in models → [See examples](skills/backend-anti-patterns/SKILL.md#-dont-callbacks-in-models)
- [ ] NO hardcoded error messages (use I18n) → [See examples](skills/backend-anti-patterns/SKILL.md#-dont-hardcoded-error-messages)
- [ ] NO passing ActiveRecord objects to jobs → [See examples](skills/backend-anti-patterns/SKILL.md#-dont-passing-activerecord-objects-to-jobs)
- [ ] NO query scopes in models (use Query Objects) → [See examples](skills/backend-anti-patterns/SKILL.md#-dont-query-logic-in-models-scopes)
- [ ] NO implicit dependencies → [See examples](skills/backend-anti-patterns/SKILL.md#-dont-implicit-dependencies)
- [ ] NO accessing internal Operation ctx keys → [See examples](skills/backend-anti-patterns/SKILL.md#-dont-accessing-internal-operation-context)
- [ ] NO missing Turbo Frame wrapping → [See examples](skills/backend-anti-patterns/SKILL.md#-dont-missing-turbo-frame-wrapping)
- [ ] NO hardcoded strings in views (use i18n) → [See examples](skills/backend-anti-patterns/SKILL.md#-dont-hardcoded-strings-in-views)

**Database patterns:** See [skills/database-anti-patterns/SKILL.md](skills/database-anti-patterns/SKILL.md) - Migration safety:
- [ ] NO direct column removals (use 3-step rollout) → [See examples](skills/database-anti-patterns/SKILL.md#-dont-remove-columns-directly)
- [ ] NO single-step column type changes (6-step migration) → [See examples](skills/database-anti-patterns/SKILL.md#-dont-change-column-type-in-single-step)
- [ ] NO backfills in transactions (batch + sleep) → [See examples](skills/database-anti-patterns/SKILL.md#-dont-backfill-data-in-transaction-with-column-addition)
- [ ] NO direct NOT NULL on existing columns (check constraint strategy) → [See examples](skills/database-anti-patterns/SKILL.md#-dont-set-not-null-on-existing-column)

## 🏗️ Common Development Patterns

See [skills/architecture/SKILL.md](skills/architecture/SKILL.md#common-development-patterns) for step-by-step guides:
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
- [ ] Comments explain WHY, not WHAT (Ruby is self-documenting; see [anti-patterns](skills/backend-anti-patterns/SKILL.md#code-commenting-anti-patterns))
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

- **[skills/error-handling/SKILL.md](skills/error-handling/SKILL.md)** - Authorization & error handling patterns
- **[skills/backend-anti-patterns/SKILL.md](skills/backend-anti-patterns/SKILL.md)** - ❌ What NOT to do / ✅ What to do
- **[skills/architecture/SKILL.md](skills/architecture/SKILL.md)** - Step-by-step development guides
- **Each skill folder contains examples/** - Code examples and tutorials

---

**Remember:** This checklist verifies compliance. For learning and detailed patterns, dive into the skill files above.