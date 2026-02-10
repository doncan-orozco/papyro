require "test_helper"

class Articles::Operation::PublishTest < ActiveSupport::TestCase
  test "publishes draft article" do
    user = users(:admin)
    article = Article.create!(
      title: "Test Article",
      slug: "test-article",
      status: :draft,
      content: "<p>Test content</p>",
      user: user
    )

    params = {
      id: article.id,
      action: "publish"
    }

    result = Articles::Operation::Publish.call(params: params)

    assert_predicate result, :success?
    assert_predicate result[:model].reload, :status_published?
    assert_not_nil result[:model].published_at
  end

  test "unpublishes published article" do
    user = users(:admin)
    article = Article.create!(
      title: "Test Article",
      slug: "test-article",
      status: :published,
      content: "<p>Test content</p>",
      published_at: Time.current,
      user: user
    )

    params = {
      id: article.id,
      action: "unpublish"
    }

    result = Articles::Operation::Publish.call(params: params)

    assert_predicate result, :success?
    assert_predicate result[:model].reload, :status_draft?
    assert_nil result[:model].published_at
  end

  test "fails to publish already published article" do
    user = users(:admin)
    article = Article.create!(
      title: "Test Article",
      slug: "test-article",
      status: :published,
      content: "<p>Test content</p>",
      published_at: Time.current,
      user: user
    )

    params = {
      id: article.id,
      action: "publish"
    }

    result = Articles::Operation::Publish.call(params: params)

    assert_predicate result, :failure?
    assert_predicate result[:errors][:base], :any?
  end

  test "fails to publish incomplete article" do
    user = users(:admin)
    article = Article.create!(
      title: "Test Article",
      slug: "test-article",
      status: :draft,
      user: user
    )

    params = {
      id: article.id,
      action: "publish"
    }

    result = Articles::Operation::Publish.call(params: params)

    assert_predicate result, :failure?
    assert_predicate result[:errors][:base], :any?
  end

  test "fails to unpublish draft article" do
    user = users(:admin)
    article = Article.create!(
      title: "Test Article",
      slug: "test-article",
      status: :draft,
      user: user
    )

    params = {
      id: article.id,
      action: "unpublish"
    }

    result = Articles::Operation::Publish.call(params: params)

    assert_predicate result, :failure?
    assert_predicate result[:errors][:base], :any?
  end

  test "fails with invalid article id" do
    params = {
      id: 99999,
      action: "publish"
    }

    result = Articles::Operation::Publish.call(params: params)

    assert_predicate result, :failure?
    assert_predicate result[:errors][:base], :any?
  end

  test "fails with invalid action" do
    user = users(:admin)
    article = Article.create!(
      title: "Test Article",
      slug: "test-article-invalid",
      status: :draft,
      content: "<p>Test content</p>",
      user: user
    )

    params = {
      id: article.id,
      action: "invalid_action"
    }

    result = Articles::Operation::Publish.call(params: params)

    assert_predicate result, :failure?
    assert_predicate result[:errors][:base], :any?
  end

  test "note: authorization should be enforced at controller level" do
    # This test documents that the operation itself doesn't enforce user scoping
    # Authorization must be handled by the controller before calling the operation
    user = users(:admin)
    other_user = users(:one)
    article = Article.create!(
      title: "Other User Article",
      slug: "other-user-publish",
      status: :draft,
      content: "<p>Test content</p>",
      user: other_user
    )

    # The operation will succeed if called directly
    result = Articles::Operation::Publish.call(params: { id: article.id, action: "publish" })

    assert_predicate result, :success?
    # Controller must use Current.user.articles.find_by! to enforce scoping
  end
end
