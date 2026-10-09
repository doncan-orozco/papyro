---
name: seo
description: "Multilingual SEO for Papyro: localized routes (route_translator), translated slugs (friendly_id + Mobility), hreflang/canonical, localized meta tags and OpenGraph, and the hreflang sitemap (sitemap_generator). Use when touching `app/helpers/seo_helper.rb`, `config/sitemap.rb`, layout head tags, route translations or slugs."
license: MIT
---

# Rails Multilingual SEO & Routing Expert

This skill provides a standardized workflow for internationalizing Rails applications without polluting the database schema or compromising search engine rankings.

## Quick Rules

Cite as `seo R<n>`. Detail and examples follow below / in references/.

R1. **Localize public routes only.** Only public routes go inside `localized do`; studio, settings, API and admin routes stay static and untranslated. → detail: Route Localization Boundary
R2. **No private paths in routes.yml.** `studio`, `settings` or other private segments are never added to `config/locales/*/routes.yml`. → detail: Route Localization Boundary
R3. **Translated slugs with history.** Slugs use `translates :slug` with `friendly_id ..., use: [:history, :mobility]` so old localized slugs redirect. → detail: Workflow
R4. **No locale bleeding.** `force_locale = true` is set in the `route_translator` initializer. → detail: Quality Standards
R5. **Self-referencing canonical.** Every public page emits a canonical pointing to itself; localized home pages (`/en`, `/es`) do not canonicalize to `/`. → detail: Home route canonical policy
R6. **hreflang with x-default.** Public pages emit `rel="alternate"` for every public locale plus one `hreflang="x-default"` (home: bare `/`). → detail: references/metadata.md
R7. **Alternates keep the resource.** Alternate URLs are derived from the recognized route and params so show pages point to the same record per locale, never to home or index. → detail: Route-aware alternate URL generation
R8. **SeoHelper placement.** SEO head logic (meta, canonical, hreflang) lives in `SeoHelper`, not `ApplicationHelper`; no hardcoded strings in `<head>`. → detail: references/metadata.md
R9. **Default meta translations.** Layout falls back to `t('seo.default_title')` / `t('seo.default_description')` when a page sets none. → detail: references/metadata.md
R10. **OpenGraph locale tags.** Public pages include `og:title`, `og:description`, `og:locale` and `og:locale:alternate` consistent with the active locale set. → detail: references/metadata.md
R11. **Noindex private surfaces.** Studio and account pages carry a `noindex` meta tag and are excluded from the sitemap. → detail: Quality Standards
R12. **Sitemap approval gate.** `config/sitemap.rb` includes only locales where `approved?(locale)` is true. → detail: references/sitemap.md
R13. **Sitemap alternates cluster.** Each sitemap entry lists alternates for all approved locales (including itself) plus `x-default`, referencing the same record. → detail: references/sitemap.md
R14. **Sitemap URL helpers.** Sitemap alternates use `_url` (absolute) and the primary `add` call uses `_path`. → detail: references/sitemap.md
R15. **SEO integration tests.** New public URLs or route changes add integration tests for canonical, hreflang, `x-default`, title, description and og tags. → detail: Quality Standards

## Core Principles

1. **Clean Schema**: Avoid `column_en`, `column_es` patterns. Use `mobility` for a scalable translation backend.
2. **Deterministic Routing**: Every *public* locale must have a unique, translated URL path.
3. **Technical SEO**: Mandatory inclusion of self-referencing canonicals and `x-default` hreflang tags.
4. **Public/Private Route Boundary**: Only public routes are localized. Translating private/authenticated routes is an anti-pattern — it creates technical debt with zero SEO return. See the [Route Localization Boundary](#route-localization-boundary) section.

### Home route canonical policy

- Keep a non-localized `/` route for the marketing home page.
- Treat `/` as the `x-default` URL.
- Localized home pages such as `/en` and `/es` must self-canonicalize; they should not canonicalize back to `/`.
- Emit a full hreflang cluster for home pages, including both public locales and `x-default`.

## Route Localization Boundary

**This is the most important architectural rule for multilingual Rails apps.**

Only routes that benefit SEO or reader shareability should be localized. Private/authenticated routes must remain static English URLs regardless of the UI locale.

| Route Type | Localize? | Reason |
|---|---|---|
| Public article index/show | **YES** | SEO ranking, reader experience |
| Public user profiles | **YES** | SEO, shareability, localized keyword ranking |
| Studio / writer area (`/studio/articles`) | **NO** | Stability, analytics tracking, developer experience |
| Account settings (`/studio/settings`) | **NO** | Security, predictable routing |
| API routes | **NO** | Contract stability |
| Admin/ops routes | **NO** | Internal tooling, zero SEO value |

### Why translating private routes is an anti-pattern

- **Zero ROI**: Search engines never index authenticated routes. No user discovers your app via `/studio/mis-articulos`.
- **Tracking instability**: Analytics, error monitoring, and feature flags all reference URL patterns. Translated private URLs fragment your data.
- **Developer friction**: Every engineer must know both English and Spanish variants. Refactoring doubles the test surface.
- **The UI locale already handles the user experience**: A writer visiting `/studio/articles` with `I18n.locale = :es` sees all labels, headings, and flash messages in Spanish. The URL does not need to change.

### Rails implementation

Declare studio routes **outside** the `localized do` block:

```ruby
# config/routes.rb

# Localized — public, SEO-sensitive
localized do
  root "home#index"
  resources :users, only: [:show]
  resources :articles, only: [:index, :show], param: :slug do
    collection { get :featured }
  end
end

# Static — private, authenticated (intentionally NOT localized)
# URL stays /studio/articles regardless of I18n.locale.
# The UI text is translated via I18n; only the URL is static.
namespace :studio do
  resources :articles do
    resource :publication, only: [:create, :destroy]
  end
end
```

**Never add `studio`, `settings`, or any private path segment to `config/locales/*/routes.yml`.** Those YAML files are only for translating public URL segments.

## Workflow

### 1. Route Translation
Wrap public routes in a `localized` block. Never localize studio, admin, or API namespaces.
- **Reference**: See [routing.md](references/routing.md) for configuration and YAML structure.

### 2. Localized Slugs
Integrate `friendly_id` with `mobility` to handle unique slugs across multiple languages.
- **Implementation**:
  ```ruby
  extend Mobility
  translates :title, :slug, type: :string
  extend FriendlyId
  friendly_id :title, use: [:history, :mobility]
  ```
- **Details**: See [models.md](references/models.md) for indexing and migration patterns.

### 3. SEO Metadata
Implement automated hreflang and canonical tag generation in the application layout.
- **Requirement**: Must include `x-default`.
- **Template**: See [seo-tags.md](references/seo-tags.md) for the ERB partial.

### 4. Route-aware alternate URL generation

Alternate URLs must preserve the current resource, not merely switch locale.

- For article show pages, alternates must point to the same article slug in each locale.
- Derive alternates from the recognized current route and its params instead of hardcoding controller branches.
- Normalize route names generated by `route_translator` so both suffixed and prefixed localized helpers resolve correctly.
- Fall back conservatively only when the current route cannot be regenerated for another locale.

This pattern prevents a common regression where localized show pages emit hreflang links to the home page or index page instead of the equivalent translated resource.

## Quality Standards

- **Slug History**: Always use the `:history` module to ensure old localized slugs redirect to new ones.
- **No Locale Bleeding**: Ensure `force_locale = true` is set in the `route_translator` initializer.
- **Index Performance**: Ensure JSONB or translation tables are indexed for slug lookups.
- **Noindex private surfaces**: Studio and account pages must carry a `noindex` meta tag and be excluded from the sitemap.
- **Helper placement**: Keep SEO head logic in a dedicated helper such as `SeoHelper`, not mixed into `ApplicationHelper`.
- **Coverage**: Add integration coverage for canonical, hreflang, `x-default`, `title`, `description`, `og:title`, `og:description`, `og:locale`, and `og:locale:alternate` on each public SEO surface: home, listing pages, show pages, and public profiles.
