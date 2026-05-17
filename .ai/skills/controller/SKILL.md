---
name: controller
description: Golden archetype for ALL Rails controllers in Papyro. Enforces strict REST routing, operation dispatch, UI vs. content locale separation, Pundit authorization, skinny base controllers, and Turbo Stream patterns. Apply to EVERY file in `app/controllers/`. This is the single source of truth — all other skills defer to this one for controller guidance.
---

# Golden Controller Skill (Papyro)

This is the **canonical skill** for all controller code. It consolidates every controller-related rule from every domain skill. Load this skill whenever you create, edit, or review any controller file.

This skill governs the HTTP boundary only. For workflow orchestration inside `app/concepts/*/operation/`, pair it with `.ai/skills/operation-pattern/SKILL.md`.

---

## What Controllers Are For

Controllers are the **HTTP boundary layer** only. Their entire job:

1. Parse params and route to a Query (read) or Operation (write).
2. Manage session, cookies, authentication/authorization (Pundit).
3. Content negotiation — respond to HTML, Turbo Stream, or JSON.
4. Redirect and set flash messages based on Operation results.

Controllers are **NOT** for:
- Database queries — use Query Objects.
- Business logic or state mutation — use Operations.
- View presentation logic — use Phlex ViewComponents.
- Generating HTML fragments or computing display strings.

---

## RULE 1: Strict RESTful Routing (MANDATORY)

Controllers must only implement the standard 7 RESTful actions:

```
index  show  new  create  edit  update  destroy
```

**Custom verb actions are FORBIDDEN** (`publish`, `restore`, `purge`, `approve`, `archive`).

State transitions are *sub-resources* — extract them into dedicated controllers.

| Non-RESTful action | Correct controller + action |
|---|---|
| `articles#restore` | `Studio::ArticleRestorationsController#create` |
| `articles#purge` | `Studio::TrashedArticlesController#destroy` |
| `articles#publish` | `Studio::PublicationsController#create` |
| `articles#unpublish` | `Studio::PublicationsController#destroy` |
| `articles#approve_translation` | `Studio::TranslationApprovalsController#create` |

### ❌ Forbidden

```ruby
class Studio::ArticlesController < Studio::BaseController
  def restore  # FORBIDDEN
  def purge    # FORBIDDEN
  def publish  # FORBIDDEN
end
```

### ✅ Correct

```ruby
# config/routes.rb
namespace :studio do
  resources :articles, param: :uuid do
    resource :restoration, only: [:create]       # POST → #create
    resource :publication, only: [:create, :destroy]
  end
end

# app/controllers/studio/article_restorations_controller.rb
class Studio::ArticleRestorationsController < Studio::BaseController
  def create
    authorize article, :restore?, policy_class: Studio::ArticlePolicy
    result = Articles::Operation::Restore.new.call(model: article)

    if result.success?
      redirect_to studio_articles_path(tab: "trash"),
        notice: t("studio.articles.operations.restore.success"), status: :see_other
    else
      redirect_to studio_articles_path(tab: "trash"),
        alert: t("studio.articles.operations.restore.failure"), status: :see_other
    end
  end
end
```

### Mounted Engine Route Handling (Papyro Studio)

For the mounted private engine workflow used in this repository:

1. In host code, generate studio links through the mounted-engine proxy (`papyro_studio`) so URLs carry the studio subdomain boundary explicitly.
2. In engine code, prefer unscoped route helpers (`articles_path`, `article_path`) after removing route helper prefix scopes.
3. During migrations, keep temporary compatibility wrappers for legacy `studio_*` helper names in one helper module; wrappers should delegate to unscoped helpers and be removed after call sites are migrated.
4. Keep REST semantics unchanged while migrating helper names.

---

## RULE 2: No Business Logic or Guard Clauses (MANDATORY)

Controllers must **never** check model state to decide whether an action is valid. All state validation belongs in the Operation.

### ❌ Forbidden

```ruby
def update
  if @article.trashed?                           # FORBIDDEN — business rule check
    redirect_to edit_studio_article_path, alert: "Cannot update trashed article"
    return
  end
  Articles::Operation::Update.new.call(...)
end
```

### ✅ Correct

```ruby
def update
  result = Articles::Operation::Update.new.call(model: article, params: article_params.to_h)

  if result.success?
    redirect_to studio_articles_path, notice: t("...")
  else
    render Views::Studio::Articles::Edit.new(article: result.failure[:model]), status: :unprocessable_entity
  end
end
```

---

## RULE 3: No View Helpers in Controllers (MANDATORY)

Controllers must not define helper methods that format data for the view (tab parsing, URL generation, badge logic).

Pass raw `params` to Phlex ViewComponents — let the view compute its own display logic.

### ❌ Forbidden

```ruby
def current_tab                                  # FORBIDDEN — view concern
  %w[all trash drafts].include?(params[:tab]) ? params[:tab] : "all"
end

def articles_index_path_for(tab)                 # FORBIDDEN — view routing helper
  tab == "all" ? studio_articles_path : studio_articles_path(tab: tab)
end
```

### ✅ Correct

```ruby
# Pass params directly; the view normalizes and uses them
render Views::Studio::Articles::Index.new(articles: articles, pagy: pagy, params: params)
```

When a layout or shared helper needs access to the same presenter object as the rendered view, assign it once to an instance variable and pass that same object through.

### ✅ Correct

```ruby
def show
  article = Articles::Query::PublishedBySlug.call({ slug: params[:slug] }).first!
  authorize article

  @presenter = ::Articles::Presenter::Show.new(article, locale: I18n.locale)

  render Views::Articles::Show.new(presenter: @presenter)
end
```

Avoid constructing the same presenter twice or building it into a local variable and then mirroring it into `@presenter` later.

---

## RULE 4: Content Locale vs. Interface Locale (MANDATORY)

**This is the most dangerous category of bug.** Always separate the App UI language from the database content language.

| Method | Effect | When to use |
|---|---|---|
| `I18n.with_locale(:es)` | Changes the **entire UI** — flash, buttons, dates | Never in per-action wrapping; set globally via `around_action` |
| `Mobility.with_locale(:es)` | Reads/writes **content rows** only; UI stays in the user's language | Always wrap Operations and View renders when targeting a content locale |

### ❌ Forbidden

```ruby
def create
  # BUG: flash message renders in Spanish if content_locale is :es
  I18n.with_locale(content_locale) do
    Articles::Operation::Create.new.call(...)
  end
end
```

### ✅ Correct

```ruby
def create
  # UI flash uses the user's I18n.locale (set globally)
  # Database write targets the content locale
  result = Mobility.with_locale(content_locale) do
    Articles::Operation::Create.new.call(params: article_params.to_h, user: Current.user)
  end

  if result.success?
    redirect_to studio_articles_path, notice: t("studio.articles.operations.create.success")
  else
    render Views::Studio::Articles::New.new(article: result.failure[:model]), status: :unprocessable_entity
  end
end
```

---

## RULE 5: Lean Base Controllers — Use Concerns (MANDATORY)

`ApplicationController` and bounded-context base controllers (`Studio::BaseController`) are **composition roots only**:
- `layout` declarations
- `rescue_from` handlers
- Core `include` statements

**Never add feature-specific private methods to `ApplicationController`.**

Extract domain logic into concerns under `app/controllers/concerns/`:

| Concern | Location | Responsibility |
|---|---|---|
| `Authentication` | `app/controllers/concerns/` | Session/cookie auth |
| `LocaleManagement` | `app/controllers/concerns/` | Global `I18n.locale` setup |
| `Studio::ContentLocaleHandling` | `app/controllers/concerns/studio/` | `studio_content_locale` parsing |

```ruby
# app/controllers/concerns/studio/content_locale_handling.rb
module Studio::ContentLocaleHandling
  extend ActiveSupport::Concern

  private

  def studio_content_locale(default: I18n.locale.to_s)
    requested = params[:content_locale].to_s
    I18n.available_locales.map(&:to_s).include?(requested) ? requested : default
  end
end

# app/controllers/studio/base_controller.rb
class Studio::BaseController < ApplicationController
  include Studio::ContentLocaleHandling
end
```

### Cross-Subdomain Session Cookie Rules

When authentication uses a custom signed cookie (for example `session_id`) in addition to Rails session storage:

1. Persist the signed cookie with `domain: :all` so host and `studio` subdomain share auth state.
2. In resume-session logic, re-persist found sessions using shared-domain cookie options to upgrade legacy host-only cookies.
3. On logout, delete both shared-domain and host-only cookie variants.
4. Keep redirect fallback after successful login deterministic (for this app, localized home path) unless an explicit return URL exists.

---

## RULE 6: Authorization at the Controller Boundary (MANDATORY)

- Always authorize with Pundit **before** calling any Operation.
- Use `policy_scope` for collections (`index` actions).
- Use `authorize record` for member actions.
- **Never** authorize inside Operations.
- **Never** look up the same record in both the controller and the operation — authorize in controller, pass `model:` to operation.

```ruby
def index
  skip_policy_scope  # if using a Query Object that already scopes
  articles = Articles::OwnedQuery.call(user: Current.user, tab: params[:tab])
  pagy, articles = pagy(articles, page: parse_page, limit: 10)
  render Views::Studio::Articles::Index.new(articles: articles, pagy: pagy, params: params)
end

def update
  authorize article, policy_class: Studio::ArticlePolicy  # authorize first
  result = Articles::Operation::Update.new.call(model: article, params: article_params.to_h)
  # ...
end
```

---

## RULE 7: Operation Result Handling (MANDATORY)

Operations return `Dry::Monads::Result`. Controllers must handle both branches explicitly.

```ruby
result = Articles::Operation::Create.new.call(params: article_params.to_h, user: Current.user)

if result.success?
  created = result.value![:model]           # result.value! only in success branch
  redirect_to edit_studio_article_path(created.uuid), notice: t("...")
else
  invalid = result.failure[:model]          # result.failure only in failure branch
  render Views::Studio::Articles::New.new(article: invalid), status: :unprocessable_entity
end
```

**Rules:**
- Never use `result[:model]` (transition shim).
- `result.value!` only in the `if result.success?` branch.
- `result.failure` only in the `else` branch.
- Extract tiny helpers only for HTTP concerns such as param normalization or response routing. Good controller helpers remove clutter like `params[:article].present?` checks or `respond_to` branching; they must not hide business logic.
- If one user action needs multiple mutation steps, dispatch one higher-level operation and route on `failure[:code]`. Do not choreograph sibling operations in the controller.
- On failure with `:model`, render with `status: :unprocessable_entity` — **never redirect** — so validation errors stay attached to the form.
- For Turbo Stream responses, render a dedicated Phlex view/component — never build HTML in the controller.

### Failure-Code Router Pattern

Controllers should route outcomes, not explain them.

```ruby
def create
  content_locale = studio_content_locale(default: studio_article.original_locale)

  result = Mobility.with_locale(content_locale) do
    Articles::Operation::Publish.new.call(
      model: studio_article,
      settings_params: publish_settings_params_for_create,
      locale: content_locale
    )
  end

  if result.success?
    handle_successful_publish
  else
    handle_failed_publish(failure: result.failure, content_locale: content_locale)
  end
end

def publish_settings_params_for_create
  return {} unless params[:article].present?

  publish_settings_params.to_h
end

def handle_failed_publish(failure:, content_locale:)
  case failure[:code]
  when :already_published
    redirect_to edit_studio_article_path(studio_article.uuid), notice: t("studio.articles.operations.update.success")
  when :trashed
    redirect_to edit_studio_article_path(studio_article.uuid), alert: failure[:message]
  else
    Mobility.with_locale(content_locale) do
      render Views::Studio::Articles::Edit.new(article: failure[:model] || studio_article, content_locale: content_locale),
        status: :unprocessable_entity
    end
  end
end
```

The controller does not decide whether publish requires a settings update first. That orchestration belongs in the operation.

---

## RULE 8: Pagination is a Controller Concern

Never paginate inside Query Objects or Models. Query objects return unpaginated `ActiveRecord::Relation`s.

```ruby
def index
  skip_policy_scope
  articles_relation = Articles::OwnedQuery.call(user: Current.user, tab: params[:tab])
  pagy, articles = pagy(articles_relation, page: parse_page, limit: 10)
  render Views::Studio::Articles::Index.new(articles: articles, pagy: pagy, params: params)
end
```

`parse_page` and `parse_per_page` live in `ApplicationController` (Pagy concern). Never define them in individual controllers.

---

## RULE 9: I18n Keys (MANDATORY)

- All user-facing text (flash, alerts) uses **fully-qualified translation keys** — never relative keys or hardcoded strings.
- Add translations in both English and Spanish.
- Use `I18n.l` for dates/times; Rails number helpers for currency.

```ruby
# ✅
redirect_to studio_articles_path, notice: t("studio.articles.operations.create.success")

# ❌
redirect_to studio_articles_path, notice: "Article created successfully"
redirect_to studio_articles_path, notice: t(".success")  # relative key
```

---

## RULE 10: No HTML Generation in Controllers

Controllers must **never** build HTML markup, including Turbo Stream fragment markup.

```ruby
# ❌ FORBIDDEN
render turbo_stream: turbo_stream.replace("article", view_context.tag.div(article.title))

# ✅ Render a dedicated view artifact
render "studio/articles/update_success", locals: { article: updated_article }
# or render a Phlex component
```

---

## Turbo Stream Pattern

When an action must respond to both HTML and Turbo Stream:

```ruby
def update
  result = Mobility.with_locale(content_locale) do
    Articles::Operation::Update.new.call(model: article, params: article_params.to_h, locale: content_locale)
  end

  if result.success?
    updated_article = result.value![:model]
    respond_to do |format|
      format.html { redirect_to studio_articles_path, notice: t("studio.articles.operations.update.success") }
      format.turbo_stream { render "studio/articles/update_success", locals: { updated_article:, content_locale: } }
    end
  else
    invalid_article = result.failure[:model]
    respond_to do |format|
      format.html do
        Mobility.with_locale(content_locale) do
          render Views::Studio::Articles::Edit.new(article: invalid_article, content_locale:), status: :unprocessable_entity
        end
      end
      format.turbo_stream do
        render "studio/articles/update_autosave_status", locals: { status: :failed }, status: :unprocessable_entity
      end
    end
  end
end
```

---

## Full RESTful Controller Template

```ruby
# frozen_string_literal: true

class Studio::ArticlesController < Studio::BaseController
  before_action :authorize_article, only: %i[edit update destroy]

  def index
    skip_policy_scope
    articles = Articles::OwnedQuery.call(user: Current.user, tab: params[:tab])
    pagy, articles = pagy(articles, page: parse_page, limit: 10)
    render Views::Studio::Articles::Index.new(articles: articles, pagy: pagy, params: params)
  end

  def create
    authorize Article, policy_class: Studio::ArticlePolicy
    result = Mobility.with_locale(studio_content_locale) do
      Articles::Operation::Create.new.call(
        params: { title: t("studio.articles.editor.untitled"), status: "draft" },
        user: Current.user
      )
    end
    if result.success?
      redirect_to edit_studio_article_path(result.value![:model].uuid),
        notice: t("studio.articles.operations.create.success")
    else
      render Views::Studio::Articles::New.new(article: result.failure[:model]), status: :unprocessable_entity
    end
  end

  def edit
    content_locale = studio_content_locale(default: article.original_locale)
    Mobility.with_locale(content_locale) do
      render Views::Studio::Articles::Edit.new(article: article, content_locale: content_locale)
    end
  end

  def update
    content_locale = studio_content_locale(default: article.original_locale)
    result = Mobility.with_locale(content_locale) do
      Articles::Operation::Update.new.call(model: article, params: article_params.to_h, locale: content_locale)
    end
    if result.success?
      respond_to do |format|
        format.html { redirect_to studio_articles_path, notice: t("studio.articles.operations.update.success") }
        format.turbo_stream { render "studio/articles/update_success", locals: { updated_article: result.value![:model], content_locale: } }
      end
    else
      respond_to do |format|
        format.html do
          Mobility.with_locale(content_locale) do
            render Views::Studio::Articles::Edit.new(article: result.failure[:model], content_locale:), status: :unprocessable_entity
          end
        end
        format.turbo_stream { render "studio/articles/update_autosave_status", locals: { status: :failed }, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    content_locale = studio_content_locale(default: article.original_locale)
    result = Articles::Operation::Destroy.new.call(model: article)
    if result.success?
      redirect_to studio_articles_path, notice: t("studio.articles.operations.destroy.success"), status: :see_other
    else
      Mobility.with_locale(content_locale) do
        render Views::Studio::Articles::Edit.new(article: result.failure[:model], content_locale:), status: :unprocessable_entity
      end
    end
  end

  private

  def article
    @article ||= Current.user.articles.find_by!(uuid: params[:uuid])
  end

  def authorize_article
    authorize article, policy_class: Studio::ArticlePolicy
  end

  def article_params
    params.require(:article).permit(:title, :slug, :body, :excerpt, :status, :published_at)
  end
end
```

---

## Non-RESTful State Transition Controller Template

```ruby
# frozen_string_literal: true

# POST /studio/articles/:article_uuid/restoration
class Studio::ArticleRestorationsController < Studio::BaseController
  def create
    authorize article, :restore?, policy_class: Studio::ArticlePolicy
    result = Articles::Operation::Restore.new.call(model: article)
    if result.success?
      redirect_to studio_articles_path(tab: "trash"),
        notice: t("studio.articles.operations.restore.success"), status: :see_other
    else
      redirect_to studio_articles_path(tab: "trash"),
        alert: t("studio.articles.operations.restore.failure"), status: :see_other
    end
  end

  private

  def article
    @article ||= Current.user.articles.find_by!(uuid: params[:article_uuid])
  end
end
```

---

## Verification Checklist

Before committing any controller, verify:

- [ ] Only RESTful actions present — no custom verbs
- [ ] State transitions extracted to dedicated sub-resource controllers
- [ ] No model state checks or business logic guard clauses
- [ ] No view helpers or display formatting methods
- [ ] All reads delegated to Query Objects
- [ ] All writes delegated to Operations
- [ ] `Mobility.with_locale` used for content locale wrapping (never `I18n.with_locale` in actions)
- [ ] Authorization via Pundit before any operation call
- [ ] Result extraction uses `result.value!` / `result.failure` — no shims
- [ ] On failure with model errors: renders with `status: :unprocessable_entity` (no redirect)
- [ ] Turbo Stream responses render dedicated view artifacts (no inline HTML)
- [ ] All user-facing strings use fully-qualified `t("...")` keys
- [ ] Pagination applied in controller, not in Query Object
- [ ] Base controller is lean; domain helpers in concerns
- [ ] No HTML generation in controller actions

## Related Skills

- **[../architecture/SKILL.md](../architecture/SKILL.md)** — Layer responsibilities, Operation structure
- **[../error-handling/SKILL.md](../error-handling/SKILL.md)** — `Dry::Monads::Result` payload contract
- **[../pundit-auth/SKILL.md](../pundit-auth/SKILL.md)** — Policy patterns, `policy_scope`, `authorize`
- **[../restful-controllers/SKILL.md](../restful-controllers/SKILL.md)** — Refactoring patterns for non-RESTful extractions
- **[../backend-anti-patterns/SKILL.md](../backend-anti-patterns/SKILL.md)** — Full anti-pattern reject list
- **[../turbo/SKILL.md](../turbo/SKILL.md)** — Turbo Frame and Stream patterns
- **[../pagination-pagy/SKILL.md](../pagination-pagy/SKILL.md)** — Pagy setup and limits
- **[../i18n/SKILL.md](../i18n/SKILL.md)** — Translation key structure

