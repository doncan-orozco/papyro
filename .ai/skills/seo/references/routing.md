# Localized Routing Patterns

## Configuration
In `config/initializers/route_translator.rb`:
```ruby
RouteTranslator.config do |config|
  config.force_locale = true
  config.generate_unnamed_unlocalized_routes = false
end
```

## Route Localization Boundary

**Only public, SEO-sensitive routes go inside the `localized do` block.**
Private/authenticated routes are declared OUTSIDE — they stay as static English URLs.

This is an intentional architecture decision, not an oversight. See SKILL.md for the full rationale.

## Route Definitions

```ruby
# config/routes.rb

# PUBLIC — localized for SEO
localized do
  root "home#index"
  resources :users, only: [:show]
  resources :articles, only: [:index, :show], param: :slug do
    collection { get :featured }
  end
end

# PRIVATE — intentionally NOT localized
# URL stays /studio/articles regardless of I18n.locale.
# The UI text is still translated via I18n; only the URL is static.
namespace :studio do
  resources :articles do
    resource :publication, only: [:create, :destroy]
  end
end
```

## Dictionary Structure — Public Routes Only

Only add entries for public URL segments. **Never add `studio`, `settings`, or any private segment here.**

```yaml
# config/locales/en/routes.yml
en:
  routes:
    articles: "articles"
    featured: "featured"
    users: "users"

# config/locales/es/routes.yml
es:
  routes:
    articles: "articulos"
    featured: "destacados"
    users: "usuarios"
```

## Common Mistakes

| Mistake | Correct approach |
|---|---|
| Adding `studio: estudio` to `es/routes.yml` | Do not translate studio — it lives outside `localized do` |
| Wrapping `namespace :studio` inside `localized do` | Studio must be declared outside the localized block |
| Expecting `/es/studio/articles` to work | The correct URL is `/studio/articles` regardless of locale |
| Generating studio paths with locale prefix | Use `studio_articles_path` directly — no locale argument needed |
