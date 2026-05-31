require "application_system_test_case"

module Studio
  class ArticleEditorAccessibilityTest < ApplicationSystemTestCase
    setup do
      @user = users(:admin)
      @article = articles(:published_article)
      sign_in_as(@user, with_studio_cookie: true)
    end

    test "editor top bar links expose readable contrast and focus parity" do
      visit studio_edit_article_url(@article)

      back_link = find("a", text: I18n.t("studio.articles.edit.back_to_articles"), exact_text: true)
      assert_includes back_link[:class].to_s, "text-foreground/80"
      assert_includes back_link[:class].to_s, "focus-visible:underline"
      assert_includes back_link[:class].to_s, "focus-visible:ring-2"

      live_link = find("a", text: I18n.t("studio.articles.edit.view_live"), exact_text: true)
      assert_includes live_link[:class].to_s, "text-foreground/80"
      assert_includes live_link[:class].to_s, "focus-visible:underline"
      assert_includes live_link[:class].to_s, "focus-visible:ring-2"

      title_field = find(:testid, "article-title-field")
      assert_includes title_field[:class].to_s, "placeholder:text-muted-foreground/80"

      locale_selector = find(:testid, "locale-selector")
      assert_equal I18n.t("studio.articles.edit.locale_selector_label"), locale_selector["aria-label"]

      autosave_status = find(:testid, "autosave-status")
      assert_equal "status", autosave_status["role"]
      assert_equal "polite", autosave_status["aria-live"]

      settings_button = find(:testid, "settings-button")
      assert_equal "dialog", settings_button["aria-haspopup"]
      assert_equal "article-settings-sheet", settings_button["aria-controls"]
      assert_selector "#article-settings-sheet", visible: :all
    end

    private

    def studio_edit_article_url(article)
      base_uri = URI.parse(Capybara.current_session.server.base_url)
      "http://studio.lvh.me:#{base_uri.port}/articles/#{article.uuid}/edit?content_locale=en"
    end
  end
end
