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
      title: "Updated Title",
      slug: "updated-slug",
      status: "draft"
    }

    result = Articles::Operation::Update.new.call(model: article, params: params)

    assert_predicate result, :success?
    assert_equal "Updated Title", result.value![:model].reload.title
    assert_equal "updated-slug", result.value![:model].slug
  end

  test "updates article content" do
    user = users(:admin)
    article = Article.create!(
      title: "Test Article",
      slug: "test-article",
      status: :draft,
      body: "<p>Original content</p>",
      user: user
    )

    params = {
      title: "Test Article",
      slug: "test-article",
      status: "draft",
      body: "<p>Updated content</p>"
    }

    result = Articles::Operation::Update.new.call(model: article, params: params)

    assert_predicate result, :success?
    assert_includes result.value![:model].reload.body.to_html, "Updated content"
    assert_equal "<p>Updated content</p>", result.value![:model].reload.body.content.to_s
  end

  test "updates markdown body via legacy content param" do
    user = users(:admin)
    article = Article.create!(
      title: "Legacy Content Article",
      slug: "legacy-content-article",
      status: :draft,
      body: "Old body",
      user: user
    )

    params = {
      title: "Legacy Content Article",
      slug: "legacy-content-article",
      status: "draft",
      content: "# New Markdown"
    }

    result = Articles::Operation::Update.new.call(model: article, params: params)

    assert_predicate result, :success?
    assert_equal "# New Markdown", result.value![:model].reload.body.content.to_s
  end

  test "keeps existing markdown content when body param is omitted" do
    user = users(:admin)
    article = Article.create!(
      title: "Article With Body",
      slug: "article-with-body",
      status: :draft,
      body: "# Existing Body",
      user: user
    )

    params = {
      title: "Renamed Article",
      slug: "article-with-body",
      status: "draft"
    }

    result = Articles::Operation::Update.new.call(model: article, params: params)

    assert_predicate result, :success?
    assert_equal "# Existing Body", result.value![:model].reload.body.content.to_s
    refute_match(/#<ActionText::Markdown:/, result.value![:model].reload.body.content.to_s)
  end

  test "fails with invalid id" do
    user = users(:admin)
    article = Article.create!(
      title: "Test Article",
      slug: "test-article",
      status: :draft,
      user: user
    )

    params = {
      title: "",  # Invalid - title blank
      slug: "test",
      status: "draft"
    }

    result = Articles::Operation::Update.new.call(model: article, params: params)

    assert_predicate result, :failure?
    assert_predicate result.failure[:errors], :present?
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
      title: "Test Article",
      slug: "existing-slug",
      status: "draft"
    }

    result = Articles::Operation::Update.new.call(model: article, params: params)

    assert_predicate result, :failure?
    assert_predicate result.failure[:errors][:slug], :any?
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
      title: "Updated Title",
      slug: "test-slug",
      status: "draft"
    }

    result = Articles::Operation::Update.new.call(model: article, params: params)

    assert_predicate result, :success?
  end

  test "fails when trying to reassign user_id" do
    user = users(:admin)
    other_user = users(:one)
    article = Article.create!(
      title: "Test Article",
      slug: "test-slug-reassign",
      status: :draft,
      user: user
    )

    params = {
      title: "Test Article",
      slug: "test-slug-reassign",
      status: "draft",
      user_id: other_user.id # Attempting to change ownership
    }

    result = Articles::Operation::Update.new.call(model: article, params: params)

    assert_predicate result, :success?
    # user_id should remain unchanged (excluded by operation)
    assert_equal user.id, article.reload.user_id
  end
end
