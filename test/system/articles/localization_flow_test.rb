require "application_system_test_case"

module Articles
  class LocalizationFlowTest < ApplicationSystemTestCase
    setup do
      @article = Article.create!(
        user: users(:admin),
        title: "English Title",
        slug: "english-title-localization",
        excerpt: "English excerpt",
        body: "**English content**"
      )
      @article.translations.find_by!(locale: "en").update!(status: :published, published_at: Time.current)
      @article.update!(published_at: Time.current)

      I18n.with_locale(:es) do
        @article.update!(
          title: "Título en Español",
          slug: "titulo-en-espanol-localizacion",
          excerpt: "Extracto en español"
        )
      end
      @article.translations.find_by!(locale: "es").update!(content: "**Contenido en español**")
      @article.translations.find_by!(locale: "es").update!(status: :published, published_at: Time.current)
    end

    test "user can read article in English and Spanish with correct localization" do
      visit article_path(@article, locale: :en)

      assert_text "English Title"
      assert_text "English excerpt"
      assert_text "English content", exact: false

      visit article_path(@article, locale: :es)

      assert_current_path(%r{/es/articulos/}, url: true)
      assert_text "Título en Español"
      assert_text "Extracto en español"
      assert_text "Contenido en español", exact: false

      visit article_path(@article, locale: :en)

      assert_current_path(%r{/en/articles/}, url: true)
      assert_text "English Title"
      assert_text "English excerpt"
      assert_text "English content"
    end

    test "unpublished spanish translation falls back to english content" do
      @article.translations.find_by!(locale: "es").update!(status: :draft, published_at: nil)

      visit article_path(@article, locale: :es)

      assert_text I18n.t("articles.show.translation_fallback_notice", locale: :es,
                         original_language: I18n.t("language.name", locale: :en))

      assert_text "English Title"
      assert_text "English excerpt"
      assert_text "English content", exact: false

      assert_no_text "Título en Español"
      assert_no_text "Extracto en español"
      assert_no_text "Contenido en español", exact: false
    end
  end
end
