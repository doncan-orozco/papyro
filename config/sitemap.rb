SitemapGenerator::Sitemap.default_host = ENV.fetch("APP_HOST", "https://papyro.net")

SitemapGenerator::Sitemap.create do
  locales = I18n.available_locales
  x_default_home_url = "#{SitemapGenerator::Sitemap.default_host}/"

  locales.each do |locale|
    alternates = locales.map { |alt| { lang: alt.to_s, href: root_url(locale: alt) } }
    alternates << { lang: "x-default", href: x_default_home_url }

    add root_path(locale: locale),
      changefreq: "daily",
      priority: 0.8,
      alternates: alternates
  end

  Article.where(status: :published).find_each do |article|
    alternates = locales.map { |alt| { lang: alt.to_s, href: article_url(article, locale: alt) } }
    alternates << { lang: "x-default", href: article_url(article, locale: I18n.default_locale) }

    locales.each do |locale|
      add article_path(article, locale: locale),
        lastmod: article.updated_at,
        priority: 0.7,
        alternates: alternates
    end
  end
end
