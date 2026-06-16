require "application_system_test_case"

module Articles
  class SeoHeadDeduplicationTest < ApplicationSystemTestCase
    setup do
      @article = Article.create!(
        user: users(:admin),
        title: "Tech Horizons",
        slug: "tech-horizons-system-seo",
        excerpt: "English SEO excerpt",
        body: "English SEO body"
      )

      @article.translations.find_by!(locale: "en").update!(status: :published, published_at: Time.current)
      @article.update!(published_at: Time.current)

      I18n.with_locale(:es) do
        @article.update!(
          title: "Horizontes Tecnologicos",
          slug: "horizontes-tecnologicos-system-seo",
          excerpt: "Resumen SEO en espanol",
          body: "Contenido SEO en espanol"
        )
      end
      @article.translations.find_by!(locale: "es").update!(status: :published, published_at: Time.current)
    end

    test "article page keeps single SEO head tags after locale toggles" do
      # Visit English version
      visit article_path(@article, locale: :en)

      assert_selector "button", text: "EN", visible: true

      assert_head_tag_counts(
        canonical_pattern: %r{/en/articles/},
        og_locale: "en_US"
      )

      # Navigate directly to Spanish version (avoids dropdown menu timing issues)
      visit article_path(@article, locale: :es)

      assert_current_path(%r{/es/articulos/}, url: true)
      assert_selector "button", text: "ES", visible: true

      assert_head_tag_counts(
        canonical_pattern: %r{/es/articulos/},
        og_locale: "es_ES"
      )

      # Navigate back to English version
      visit article_path(@article, locale: :en)

      assert_current_path(%r{/en/articles/}, url: true)
      assert_selector "button", text: "EN", visible: true

      assert_head_tag_counts(
        canonical_pattern: %r{/en/articles/},
        og_locale: "en_US"
      )
    end

    private

    def assert_head_tag_counts(canonical_pattern:, og_locale:)
      assert_equal 1, page.evaluate_script("document.head.querySelectorAll('title').length")
      assert_equal 1, page.evaluate_script("document.head.querySelectorAll('link[rel=\"canonical\"]').length")
      assert_equal 1, page.evaluate_script("document.head.querySelectorAll('meta[property=\"og:image\"]').length")
      assert_equal 1, page.evaluate_script("document.head.querySelectorAll('meta[name=\"twitter:card\"]').length")
      assert_equal 1, page.evaluate_script("document.head.querySelectorAll('meta[property=\"og:locale\"]').length")
      # JSON-LD must appear only in the body, never in the head (Turbo-safe)
      assert_equal 0, page.evaluate_script("document.head.querySelectorAll('script#article-json-ld[type=\"application/ld+json\"]').length"), "JSON-LD should not be in <head>"
      assert_equal 1, page.evaluate_script("document.body.querySelectorAll('script#article-json-ld[type=\"application/ld+json\"]').length"), "JSON-LD should be in <body>"
      canonical_href = page.evaluate_script("document.head.querySelector('link[rel=\"canonical\"]').href")

      assert_match canonical_pattern, canonical_href
      assert_equal og_locale, page.evaluate_script("document.head.querySelector('meta[property=\"og:locale\"]').content")
    end
  end
end
