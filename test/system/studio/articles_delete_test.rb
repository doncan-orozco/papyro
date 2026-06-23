require "application_system_test_case"

module Studio
  class ArticlesDeleteTest < ApplicationSystemTestCase
    setup do
      @user = users(:admin)
      sign_in_as(@user, with_studio_cookie: true)
    end

    test "draft article can be soft-deleted from the list" do
      @draft_article = articles(:draft_article)

      visit studio_articles_url

      # Open the action menu for the draft article
      within_row_for(@draft_article) do
        find("button[aria-label='#{I18n.t("studio.articles.index.menu_trigger")}']").click
      end

      # Verify the delete option is visible in the menu
      assert_selector "a", text: I18n.t("studio.articles.index.delete"), visible: :all

      # Accept the confirmation dialog and click delete
      page.accept_confirm I18n.t("studio.articles.index.confirm_delete") do
        find("a", text: I18n.t("studio.articles.index.delete"), exact_text: true).click
      end

      # After redirect, the article should no longer appear in the All list
      assert_no_selector "a", text: @draft_article.title

      # Navigate to the Trash tab
      visit studio_articles_url(tab: "trash")

      # The article should appear in the trash
      assert_selector "a", text: @draft_article.title
    end

    test "published article does not show delete action" do
      @published_article = articles(:published_article)

      visit studio_articles_url

      # Open the action menu for the published article
      within_row_for(@published_article) do
        find("button[aria-label='#{I18n.t("studio.articles.index.menu_trigger")}']").click
      end

      # The delete option must NOT be present — it is only rendered for non-published articles
      assert_no_selector "a", text: I18n.t("studio.articles.index.delete")
    end

    test "deleting article redirects back to current tab" do
      @draft_article = articles(:draft_article)

      visit studio_articles_url(tab: "drafts")

      # Open the action menu
      within_row_for(@draft_article) do
        find("button[aria-label='#{I18n.t("studio.articles.index.menu_trigger")}']").click
      end

      # Accept confirm and click delete
      page.accept_confirm I18n.t("studio.articles.index.confirm_delete") do
        find("a", text: I18n.t("studio.articles.index.delete"), exact_text: true).click
      end

      # Verify the URL still includes the original tab
      assert_current_path %r{/articles\?tab=drafts}
    end

    private

    def studio_articles_url(tab: nil)
      base_uri = URI.parse(Capybara.current_session.server.base_url)
      url = "http://studio.lvh.me:#{base_uri.port}/articles"
      url += "?tab=#{tab}" if tab
      url
    end

    def within_row_for(article)
      title_link = find("a", text: article.title)
      row = title_link.ancestor("tr")
      within(row) { yield }
    end
  end
end
