require "test_helper"

class Articles::Operation::CreateTest < ActiveSupport::TestCase
  test "creates article with valid params" do
    user = users(:admin)
    params = {
      title: "Test Article",
      slug: "test-article",
      status: "draft",
      content: "<p>Test content</p>",
      excerpt: "Test excerpt",
      user_id: user.id
    }

    result = Articles::Operation::Create.call(params: params)

    assert_predicate result, :success?
    assert_instance_of Article, result[:model]
  end

  test "sets article attributes correctly" do
    user = users(:admin)
    params = {
      title: "Test Article",
      slug: "test-article",
      status: "draft",
      body: "<p>Test content</p>",
      excerpt: "Test excerpt",
      user_id: user.id
    }

    result = Articles::Operation::Create.call(params: params)

    assert_equal "Test Article", result[:model].title
    assert_equal "test-article", result[:model].slug
    assert_predicate result[:model], :status_draft?
  end

  test "fails with invalid title" do
    user = users(:admin)
    params = {
      title: "",
      slug: "test-article",
      status: "draft",
      user_id: user.id
    }

    result = Articles::Operation::Create.call(params: params)

    assert_predicate result, :failure?
    assert_predicate result[:errors][:title], :any?
  end

  test "fails with invalid slug format" do
    user = users(:admin)
    params = {
      title: "Test Article",
      slug: "Test Article!",
      status: "draft",
      user_id: user.id
    }

    result = Articles::Operation::Create.call(params: params)

    assert_predicate result, :failure?
    assert_predicate result[:errors][:slug], :any?
  end

  test "fails with duplicate slug" do
    user = users(:admin)
    Article.create!(
      title: "Original Article",
      slug: "duplicate-slug",
      status: :draft,
      user: user
    )

    params = {
      title: "New Article",
      slug: "duplicate-slug",
      status: "draft",
      user_id: user.id
    }

    result = Articles::Operation::Create.call(params: params)

    assert_predicate result, :failure?
    assert result[:errors][:slug].any? { |msg| msg.include?("already exists") || msg.include?("taken") }
  end

  test "creates published article with published_at" do
    user = users(:admin)
    published_at = 1.day.ago
    params = {
      title: "Published Article",
      slug: "published-article-unique-#{Time.current.to_i}",
      status: "published",
      body: "<p>Published content</p>",
      published_at: published_at,
      user_id: user.id
    }

    result = Articles::Operation::Create.call(params: params)

    assert_predicate result, :success?
    assert_predicate result[:model], :status_published?
    assert_equal published_at.to_i, result[:model].published_at.to_i
  end

  test "fails when published status lacks published_at" do
    user = users(:admin)
    params = {
      title: "Published Article",
      slug: "published-article",
      status: "published",
      user_id: user.id
    }

    result = Articles::Operation::Create.call(params: params)

    assert_predicate result, :failure?
    assert_predicate result[:errors][:published_at], :any?
  end
end
