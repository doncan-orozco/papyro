---
name: rails-seo-sitemap-expert
description: Advanced sitemap configuration for multilingual Rails apps using sitemap-generator and route_translator. Automates xhtml:link (hreflang) clusters and x-default implementation while respecting translation approval workflows.
license: MIT
---

# Rails Multilingual Sitemap Expert

This skill automates the creation of "Language Tree" sitemaps. It ensures that every localized URL is cross-referenced with its alternates, preventing duplicate content penalties and improving international search visibility.

## Core Principles

1.  **Hreflang Reciprocity**: Every URL in the sitemap must point to all its translated versions (including itself).
2.  **Workflow Sensitivity**: Only include URLs where the content is explicitly `approved?` for that locale.
3.  **Route Integration**: Leverage `route_translator` helpers to automatically generate localized paths (e.g., `/es/articulos` vs `/en/articles`).

## Implementation Workflow

### 1. The Sitemap Configuration (`config/sitemap.rb`)
The logic must iterate through locales to build the "Alternate Cluster" before adding the paths.

```ruby
SitemapGenerator::Sitemap.default_host = "[https://yourdomain.com](https://yourdomain.com)"

SitemapGenerator::Sitemap.create do
  # 1. Dynamic Content (e.g., Articles)
  Article.find_each do |article|
    # Build the cluster of approved translations
    approved_locales = I18n.available_locales.select { |l| article.approved?(l) }
    
    alternates = approved_locales.map do |l|
      { lang: l, href: article_url(article, locale: l) }
    end
    
    # Add x-default (usually the original language)
    alternates << { lang: 'x-default', href: article_url(article, locale: article.original_locale) }

    # Add each approved version to the sitemap
    approved_locales.each do |locale|
      I18n.with_locale(locale) do
        add article_path(article), 
            lastmod: article.updated_at,
            alternates: alternates,
            priority: 0.8
      end
    end
  end
end
```

### 2. The Output Structure
The skill ensures the generated XML follows the Google-mandated structure for multilingual discovery:



```xml
<url>
  <loc>[https://domain.com/es/articulos/mi-post](https://domain.com/es/articulos/mi-post)</loc>
  <xhtml:link rel="alternate" hreflang="es" href="[https://domain.com/es/articulos/mi-post](https://domain.com/es/articulos/mi-post)"/>
  <xhtml:link rel="alternate" hreflang="en" href="[https://domain.com/en/articles/my-post](https://domain.com/en/articles/my-post)"/>
  <xhtml:link rel="alternate" hreflang="x-default" href="[https://domain.com/en/articles/my-post](https://domain.com/en/articles/my-post)"/>
</url>
```

## Best Practices

* **Host Consistency**: Ensure `default_host` matches your production SSL setting (https).
* **Approval Gate**: Always use `next unless model.approved?(locale)` to prevent indexing "thin" or unfinished AI translations.
* **Automation**: Trigger `rake sitemap:refresh` via a post-deployment hook or a daily CRON job to keep the index fresh.
* **Search Console**: Once generated, submit the `sitemap.xml` to Google Search Console and monitor the "International Targeting" report for hreflang validation.

## Constraints
- **URL Helpers**: Always use `_url` for alternates (absolute paths) and `_path` for the primary `add` call (relative).
- **Memory**: For massive datasets, use `find_in_batches` instead of `find_each` to keep the sitemap generation memory-efficient.
