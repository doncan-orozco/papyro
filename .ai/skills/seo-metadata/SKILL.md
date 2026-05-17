---
name: rails-seo-metadata
description: Workflow for managing localized meta-tags and social sharing data. Use when implementing titles, descriptions, and OpenGraph tags that must change based on the current locale.
---

# Rails SEO Meta-Tag Architect

## 1. Helper Pattern
Create a centralized helper to manage tags. Avoid hardcoding strings in the `<head>`.

```ruby
# app/helpers/seo_helper.rb
module SeoHelper
  def meta_title(title)
    content_for(:title) { title }
  end

  def meta_description(desc)
    content_for(:description) { desc }
  end
end
```

Keep route-derived SEO helpers in this dedicated module as well. Do not leave canonical, hreflang, and x-default logic inside `ApplicationHelper`.

## 2. Default Translations
Store generic SEO strings in your YAML files so they are automatically localized.

```yaml
# config/locales/es.yml
es:
  seo:
    default_title: "Mi Blog Increíble"
    default_description: "Artículos sobre Rails y SEO."
```

## 3. Implementation in Layout
Ensure the layout falls back to defaults if a specific page hasn't defined its own tags.

```erb
<title><%= content_for(:title) || t('seo.default_title') %></title>
<meta name="description" content="<%= content_for(:description) || t('seo.default_description') %>">
```

For multilingual public pages, the layout should also render:

- a self-referencing canonical URL
- `rel="alternate"` tags for every public locale
- one `hreflang="x-default"` tag that points to the non-localized home page `/`

## 4. OpenGraph & Social
Always include `og:locale` and `og:locale:alternate` tags to match your `route_translator` setup. This ensures that when a link is shared on WhatsApp or LinkedIn, the preview appears in the correct language.

## 5. Canonical and hreflang rules

- `/` is the global fallback landing page and should be used for `x-default`.
- Localized home pages such as `/en` and `/es` should self-canonicalize.
- For resource pages, alternates must preserve the same route and identifying params across locales.
- Generate alternates from the recognized request route when possible so article, profile, and listing pages stay aligned across locales.

## 6. Test expectations

Add request or integration tests that assert:

- the canonical tag for `/` points to `/`
- localized home pages canonicalize to themselves
- article and profile pages emit locale alternates for the same resource
- the head includes `x-default` alongside locale-specific alternates
- the head includes `title`, `meta[name='description']`, `og:title`, and `og:description` with localized content
- the head includes `og:locale` and `og:locale:alternate` values consistent with the active locale set

These tests are required for new public URLs and public route changes, not optional QA coverage.
