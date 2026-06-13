require "test_helper"

class ArticlesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:admin)
    @published_article = Article.create!(
      title: "Published Article",
      slug: "published-article-ctrl-#{Time.current.to_i}",
      excerpt: "Published summary",
      body: "<p>Published content</p>",
      user: @user
    )
    publish_article!(@published_article)
    @draft_article = Article.create!(
      title: "Draft Article",
      slug: "draft-article-ctrl-#{Time.current.to_i}",
      body: "<p>Draft content</p>",
      user: @user
    )
  end

  test "index is accessible without authentication" do
    get root_path

    assert_response :success
    assert_includes @response.body, "Find your next deep read"
    assert_includes @response.body, "Search across essays, notes, and topics"
  end

  test "index lists only published articles" do
    hidden_article = Article.create!(
      title: "Hidden Published Article",
      slug: "hidden-published-article-ctrl-#{Time.current.to_i}",
      excerpt: "Hidden summary",
      body: "<p>Hidden published content</p>",
      user: @user
    )
    publish_article!(hidden_article, published_at: 6.hours.ago)

    6.times do |index|
      article = Article.create!(
        title: "Extra Published Article #{index}",
        slug: "extra-published-article-#{index}-#{Time.current.to_i}",
        excerpt: "Extra summary #{index}",
        body: "<p>Extra published content #{index}</p>",
        user: @user
      )
      publish_article!(article, published_at: (index + 1).hours.ago)
    end

    get root_path

    assert_includes @response.body, @published_article.title
    assert_not_includes @response.body, @draft_article.title
    assert_includes @response.body, hidden_article.title
  end

  test "show renders published article" do
    get article_path(@published_article.slug)

    assert_response :success
  end

  test "show renders refined metadata with author display name and no status" do
    get article_path(@published_article.slug)

    assert_response :success
    assert_includes response.body, I18n.t("articles.show.written_by")
    assert_includes response.body, @user.author_display_name
    assert_includes response.body, I18n.l(@published_article.published_at.to_date, format: :short)
    assert_includes response.body, "1 min read"
    assert_includes response.body, I18n.t("articles.show.view_profile")
    assert_not_includes response.body, @user.email_address
    assert_not_includes response.body, I18n.t("articles.show.content_length")
  end

  test "show redirects for draft article" do
    get article_path(@draft_article.slug)

    assert_response :not_found
    assert_select "meta[name='robots'][content='noindex']", 1
    assert_select "link[rel='canonical']", 0
    assert_select "link[rel='alternate'][hreflang='en']", 0
    assert_select "link[rel='alternate'][hreflang='es']", 0
    assert_select "link[rel='alternate'][hreflang='x-default']", 0
  end

  test "owner can view own draft article" do
    sign_in_as @user

    get article_path(@draft_article.slug)

    assert_response :success
    assert_includes response.body, @draft_article.title
  end

  test "non-owner cannot view another user's draft article" do
    sign_in_as users(:two)

    get article_path(@draft_article.slug)

    assert_response :not_found
  end

  test "show redirects for non-existent article" do
    get article_path("non-existent-slug")

    assert_response :not_found
    assert_select "meta[name='robots'][content='noindex']", 1
    assert_select "link[rel='canonical']", 0
    assert_select "link[rel='alternate'][hreflang='en']", 0
    assert_select "link[rel='alternate'][hreflang='es']", 0
    assert_select "link[rel='alternate'][hreflang='x-default']", 0
  end

  test "show does not require authentication" do
    get article_path(@published_article.slug)

    assert_response :success
  end

  test "show renders more from author section when author has other published articles" do
    author = users(:one)
    article = Article.create!(
      title: "Isolated Published Article",
      slug: "isolated-published-article-ctrl-#{Time.current.to_i}",
      excerpt: "Isolated summary",
      body: "<p>Published content</p>",
      user: author
    )
    publish_article!(article)

    older_article = Article.create!(
      title: "Older Published Article",
      slug: "older-published-article-ctrl-#{Time.current.to_i}",
      excerpt: "Older summary",
      body: "<p>Older published content</p>",
      user: author
    )
    publish_article!(older_article, published_at: 2.days.ago)

    newer_article = Article.create!(
      title: "Newer Published Article",
      slug: "newer-published-article-ctrl-#{Time.current.to_i}",
      excerpt: "Newer summary",
      body: "<p>Newer published content</p>",
      user: author
    )
    publish_article!(newer_article, published_at: 1.hour.ago)

    get article_path(article.slug)

    assert_response :success
    assert_includes response.body, I18n.t("articles.show.more_from_author", author: author.author_display_name)
    assert_includes response.body, newer_article.title
    assert_includes response.body, older_article.title
    assert_not_includes response.body, I18n.t("articles.show.more_from_platform")
  end

  test "show falls back to platform articles when author has no other published articles" do
    solo_author = users(:two)
    solo_article = Article.create!(
      title: "Solo Published Article",
      slug: "solo-published-article-ctrl-#{Time.current.to_i}",
      excerpt: "Solo summary",
      body: "<p>Solo published content</p>",
      user: solo_author
    )
    publish_article!(solo_article)

    platform_article = Article.create!(
      title: "Platform Published Article",
      slug: "platform-published-article-ctrl-#{Time.current.to_i}",
      excerpt: "Platform summary",
      body: "<p>Platform published content</p>",
      user: users(:admin)
    )
    publish_article!(platform_article, published_at: 1.hour.ago)

    get article_path(solo_article.slug)

    assert_response :success
    assert_includes response.body, I18n.t("articles.show.more_from_platform")
    assert_includes response.body, platform_article.title
  end

  test "index renders welcome hero for unauthenticated guest" do
    get root_path

    assert_response :success
    assert_includes response.body, I18n.t("components.public.welcome_hero.eyebrow")
    assert_includes response.body, I18n.t("components.public.welcome_hero.primary_cta")
  end

  test "index does not render welcome hero for authenticated user" do
    sign_in_as @user

    get root_path

    assert_response :success
    assert_not_includes response.body, I18n.t("components.public.welcome_hero.eyebrow")
  end
end
