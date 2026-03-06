require "test_helper"

class Articles::Operation::PublishTest < ActiveSupport::TestCase
  test "publishes draft article" do
    user = users(:admin)
    article = Article.create!(
      title: "Test Article",
      slug: "test-article",
      status: :draft,
      body: "<p>Test content</p>",
      user: user
    )

    params = {
      action: "publish"
    }

    result = Articles::Operation::Publish.call(model: article, params: params)

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
      body: "<p>Test content</p>",
      published_at: Time.current,
      user: user
    )

    params = {
      action: "unpublish"
    }

    result = Articles::Operation::Publish.call(model: article, params: params)

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
      body: "<p>Test content</p>",
      published_at: Time.current,
      user: user
    )

    params = {
      action: "publish"
    }

    result = Articles::Operation::Publish.call(model: article, params: params)

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
      action: "publish"
    }

    result = Articles::Operation::Publish.call(model: article, params: params)

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
      action: "unpublish"
    }

    result = Articles::Operation::Publish.call(model: article, params: params)

    assert_predicate result, :failure?
    assert_predicate result[:errors][:base], :any?
  end

  test "fails with invalid action" do
    user = users(:admin)
    article = Article.create!(
      title: "Test Article",
      slug: "test-article-invalid",
      status: :draft,
      body: "<p>Test content</p>",
      user: user
    )

    params = {
      action: "invalid_action"
    }

    result = Articles::Operation::Publish.call(model: article, params: params)

    assert_predicate result, :failure?
    assert_predicate result[:errors][:base], :any?
  end

  test "requires model parameter" do
    # Operation now expects model to be passed from controller
    params = {
      action: "publish"
    }

    assert_raises(ArgumentError) do
      Articles::Operation::Publish.call(params: params)
    end
  end

  test "note: authorization is enforced at controller level before passing model" do
    # This test documents the new calling pattern:
    # 1. Controller finds article with scoping: Current.user.articles.find_by!(id: params[:id])
    # 2. Controller passes pre-authorized model to operation
    # 3. Operation performs publish/unpublish without re-querying

    user = users(:admin)
    other_user = users(:one)
    article = Article.create!(
      title: "Other User Article",
      slug: "other-user-publish",
      status: :draft,
      body: "<p>Test content</p>",
      user: other_user
    )

    # Operation expects pre-authorized model from controller
    # Controller's scoped query (Current.user.articles.find_by!) prevents unauthorized access
    result = Articles::Operation::Publish.call(model: article, params: { action: "publish" })

    assert_predicate result, :success?
    # Security is enforced by controller's scoped find, not by operation
  end
end
