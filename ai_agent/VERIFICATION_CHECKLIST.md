# Papyro Guidelines Verification Checklist

Use this checklist before committing code to ensure full compliance with Papyro standards.

## 🏗️ Architecture & Organization

### Controllers
- [ ] Thin controller (request → Operation/Service → response)
- [ ] No business logic
- [ ] Explicit data passed to view/component

### Operations (Trailblazer)
- [ ] Live in `app/concepts/{domain}/operation/`
- [ ] Railway flow: Model → Contract::Build → Validate → Logic → Persist → Broadcast
- [ ] Return Result monads (Success/Failure)

### Models
- [ ] Persistence only
- [ ] NO validations
- [ ] NO callbacks
- [ ] NO business logic

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
- [ ] Domain-based: `config/locales/{en,es}/{file}.yml`
- [ ] Separate files: `app.yml`, `pages.yml`, `components.yml`, `models.yml`, etc.
- [ ] Both English and Spanish translations

### Key Naming
- **Views**: Scoped keys `t(".title")`
- **Components**: Full path `t("components.domain.section.key")`
- **Models**: `t("activerecord.models.model_name")`
- **Contract Error Messages**: `I18n.t('errors.messages.key_name')` in `config/locales/{en,es}/errors.yml`

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
   - [ ] No validations in models
   - [ ] No callbacks in models
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

## 🚀 Common Patterns

### Adding a Page
1. Create `app/controllers/{domain}_controller.rb`
2. Create `app/views/{domain}/action.rb` (inherit from `Views::Base`)
3. Create route in `config/routes.rb`
4. Create `config/locales/{en,es}/{file}.yml`
5. Use scoped keys: `t(".title")`

### Adding a Component
1. Create `app/components/{domain}/name.rb` (inherit from `Components::Base`)
2. Create locale keys in `config/locales/{en,es}/components.yml`
3. Use full path keys: `t("components.domain.section.key")`
4. Include `**attrs` for Stimulus support

### Adding a Frame
1. Create `app/controllers/{domain}_controller.rb` with action
2. Create `app/views/{domain}/action.rb` with `turbo_frame_tag`
3. Add route: `get "path", to: "{domain}#{action}", as: :route_name`
4. In main view: `turbo_frame_tag("id", src: route_name_path, loading: :lazy)`
5. Add i18n translations

### Adding Stimulus Interaction
1. Create `app/javascript/controllers/{domain}/{feature}_controller.js`
2. Add data attributes to component: `data: { controller: "domain--feature", ... }`
3. Use `static targets`, `values` for data binding
4. Dispatch custom events for communication
