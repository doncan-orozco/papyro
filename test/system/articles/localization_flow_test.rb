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
      @article.article_translations.find_by!(locale: "en").update!(status: :published, published_at: Time.current)
      @article.update!(published_at: Time.current)

      I18n.with_locale(:es) do
        @article.update!(
          title: "Título en Español",
          slug: "titulo-en-espanol-localizacion",
          excerpt: "Extracto en español"
        )
      end
      @article.article_translations.find_by!(locale: "es").update!(content: "**Contenido en español**")
      @article.article_translations.find_by!(locale: "es").update!(status: :published, published_at: Time.current)
    end

    test "user can read article in English and Spanish with correct localization" do
      visit article_path(@article, locale: :en)
      assert_text "English Title"
      assert_text "English excerpt"
      assert_text "English content", exact: false

      find("button[aria-label='#{I18n.t("components.shared.language_toggle.toggle_label", locale: :en)}']").click
      find("[role='menuitem']", text: I18n.t("components.shared.language_toggle.spanish", locale: :en), visible: :all).click
      assert_current_path(%r{/es/articulos/}, url: true)
      assert_text "Título en Español"
      assert_text "Extracto en español"
      assert_text "Contenido en español", exact: false

      find("button[aria-label='#{I18n.t("components.shared.language_toggle.toggle_label", locale: :es)}']").click
      find("[role='menuitem']", text: I18n.t("components.shared.language_toggle.english", locale: :es), visible: :all).click
      assert_current_path(%r{/en/articles/}, url: true)
      assert_text "English Title"
      assert_text "English excerpt"
      assert_text "English content"
    end
  end
end
