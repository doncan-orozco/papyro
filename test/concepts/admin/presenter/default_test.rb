require "test_helper"

class Admin::Presenter::DefaultTest < ActiveSupport::TestCase
  test "wrap builds presenter collection" do
    records = [ articles(:draft_article), articles(:published_article) ]

    presenters = assert_wraps_collection(Admin::Presenter::Default, records)

    assert_equal records.map(&:id), presenters.map(&:id)
  end

  test "status variant maps draft published and archived" do
    draft = Admin::Presenter::Default.new(articles(:draft_article))
    published = Admin::Presenter::Default.new(articles(:published_article))
    archived = Admin::Presenter::Default.new(articles(:archived_article))

    assert_equal :secondary, draft.status_variant
    assert_equal :default, published.status_variant
    assert_equal :outline, archived.status_variant
  end

  test "published label falls back when unpublished" do
    presenter = Admin::Presenter::Default.new(articles(:draft_article))

    assert_equal I18n.t("admin.articles.index.not_published"), presenter.published_label
  end

  test "published label uses localized date when published" do
    article = articles(:published_article)
    presenter = Admin::Presenter::Default.new(article)

    assert_equal I18n.l(article.published_at, format: :short), presenter.published_label
  end

  test "excerpt helpers expose excerpt state and text" do
    article = Article.create!(
      title: "Excerpt article",
      slug: "excerpt-article-#{SecureRandom.hex(4)}",
      excerpt: "Short excerpt",
      body: "Body",
      user: users(:admin)
    )
    presenter = Admin::Presenter::Default.new(article)

    assert_predicate presenter, :has_excerpt?
    assert_equal "Short excerpt", presenter.excerpt_text
  end
end
