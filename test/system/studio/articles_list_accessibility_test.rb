require "application_system_test_case"

module Studio
  class ArticlesListAccessibilityTest < ApplicationSystemTestCase
    setup do
      @user = users(:admin)
      sign_in_as(@user, with_studio_cookie: true)
    end

    test "studio index provides menu labeling and keyboard focus cues" do
      visit studio_articles_url

      user_menu_trigger = find(:testid, "studio-user-menu-trigger")
      assert_equal I18n.t("components.public.navbar.dropdown.settings"), user_menu_trigger["aria-label"]

      within("nav[aria-label]") do
        all("a").each do |link|
          assert_includes link[:class].to_s, "focus-visible:underline"
        end
      end

      assert_selector "tbody tr td a", minimum: 1
      title_link = first("tbody tr td a")
      assert_includes title_link[:class].to_s, "focus-visible:underline"

      assert_selector "button[aria-label='#{I18n.t("studio.articles.index.menu_trigger") }']", minimum: 1

      menu_trigger = first("button[aria-label='#{I18n.t("studio.articles.index.menu_trigger") }']")
      menu_trigger.click

      assert_selector "div[role='menu'][aria-label='#{I18n.t("studio.articles.index.columns.actions") }']", visible: :all
    end

    test "draft row publish action is announced as dialog trigger" do
      visit "#{studio_articles_url}?tab=drafts"

      menu_trigger = first("button[aria-label='#{I18n.t("studio.articles.index.menu_trigger") }']")
      menu_trigger.click
      assert_selector "div[role='menu'][aria-label='#{I18n.t("studio.articles.index.columns.actions") }']", visible: :all

      publish_action = find("a", text: I18n.t("studio.articles.index.publish"), exact_text: true, visible: :all)
      assert_equal "dialog", publish_action["aria-haspopup"]
      assert_equal "article-publish-sheet", publish_action["aria-controls"]
    end

    private

    def studio_articles_url
      base_uri = URI.parse(Capybara.current_session.server.base_url)
      "http://studio.lvh.me:#{base_uri.port}/articles"
    end
  end
end
