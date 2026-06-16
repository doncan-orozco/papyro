require "application_system_test_case"

module Articles
  class LightboxModalTest < ApplicationSystemTestCase
    setup do
      @article = Article.create!(
        user: users(:admin),
        title: "Lightbox Story",
        slug: "lightbox-story",
        excerpt: "Lightbox behavior coverage",
        body: "![Cloud image](/u/token123)"
      )
      @article.translations.find_by!(locale: "en").update!(status: :published, published_at: Time.current)
      @article.update!(published_at: Time.current)
    end

    test "clicking article image opens lightbox without navigation" do
      visit article_path(@article, locale: :en)

      assert_selector "body[data-lightbox-ready='true']"
      starting_url = page.current_url

      first("a[data-action='lightbox#open:prevent']").click

      assert_selector "dialog.lightbox[open]"
      assert_selector "dialog.lightbox .lightbox__image[src*='/u/token123']"
      assert_selector "dialog.lightbox .lightbox__btn[aria-label='Close image']"
      assert_selector "html.lightbox-open"
      assert_selector "body.lightbox-open"
      assert_equal starting_url, page.current_url
    end

    test "close button closes lightbox" do
      visit article_path(@article, locale: :en)

      assert_selector "body[data-lightbox-ready='true']"

      first("a[data-action='lightbox#open:prevent']").click

      assert_selector "dialog.lightbox[open]"

      find("dialog.lightbox .lightbox__btn[aria-label='Close image']").click

      assert_no_selector "dialog.lightbox[open]"
      assert_no_selector "html.lightbox-open"
      assert_no_selector "body.lightbox-open"
    end

    test "escape closes lightbox" do
      visit article_path(@article, locale: :en)

      assert_selector "body[data-lightbox-ready='true']"

      first("a[data-action='lightbox#open:prevent']").click

      assert_selector "dialog.lightbox[open]"

      find("body").send_keys(:escape)

      assert_no_selector "dialog.lightbox[open]"
    end
  end
end
