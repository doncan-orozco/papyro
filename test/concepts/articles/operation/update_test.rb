require "test_helper"

class Articles::Operation::UpdateTest < ActiveSupport::TestCase
  test "updates article with valid params" do
    user = users(:admin)
    article = Article.create!(
      title: "Original Title",
      slug: "original-slug",
      status: :draft,
      user: user
    )

    params = {
      id: article.id,
      title: "Updated Title",
      slug: "updated-slug",
      status: "draft",
      user_id: user.id
    }

    result = Articles::Operation::Update.call(params: params)

    assert_predicate result, :success?
    assert_equal "Updated Title", result[:model].reload.title
    assert_equal "updated-slug", result[:model].slug
  end

  test "updates article content" do
    user = users(:admin)
    article = Article.create!(
      title: "Test Article",
      slug: "test-article",
      status: :draft,
      content: "<p>Original content</p>",
      user: user
    )

    params = {
      id: article.id,
      title: "Test Article",
      slug: "test-article",
      status: "draft",
      content: "<p>Updated content</p>",
      user_id: user.id
    }

    result = Articles::Operation::Update.call(params: params)

    assert_predicate result, :success?
    assert_includes result[:model].reload.content.to_s, "Updated content"
  end

  test "fails with invalid id" do
    params = {
      id: 99999,
      title: "Test",
      slug: "test",
      status: "draft",
      user_id: users(:admin).id
    }

    result = Articles::Operation::Update.call(params: params)

    assert_predicate result, :failure?
    assert result[:errors][:base].any?
  end

  test "fails with duplicate slug" do
    user = users(:admin)
    Article.create!(
      title: "Existing Article",
      slug: "existing-slug",
      status: :draft,
      user: user
    )
    article = Article.create!(
      title: "Test Article",
      slug: "test-slug",
      status: :draft,
      user: user
    )

    params = {
      id: article.id,
      title: "Test Article",
      slug: "existing-slug",
      status: "draft",
      user_id: user.id
    }

    result = Articles::Operation::Update.call(params: params)

    assert_predicate result, :failure?
    assert result[:errors][:slug].any?
  end

  test "allows same slug for same article" do
    user = users(:admin)
    article = Article.create!(
      title: "Test Article",
      slug: "test-slug",
      status: :draft,
      user: user
    )

    params = {
      id: article.id,
      title: "Updated Title",
      slug: "test-slug",
      status: "draft",
      user_id: user.id
    }

    result = Articles::Operation::Update.call(params: params)

    assert_predicate result, :success?
  end
end
