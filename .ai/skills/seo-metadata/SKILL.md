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

## 4. OpenGraph & Social
Always include `og:locale` and `og:locale:alternate` tags to match your `route_translator` setup. This ensures that when a link is shared on WhatsApp or LinkedIn, the preview appears in the correct language.
