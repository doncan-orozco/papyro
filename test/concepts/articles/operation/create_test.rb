require "test_helper"

class Articles::Operation::CreateTest < ActiveSupport::TestCase
  test "creates article with valid params" do
    user = users(:admin)
    params = {
      title: "Test Article",
      slug: "test-article",
      status: "draft",
      body: "<p>Test content</p>",
      excerpt: "Test excerpt"
    }

    result = Articles::Operation::Create.new.call(params: params, user: user)

    assert_predicate result, :success?
    assert_instance_of Article, result.value![:model]
  end

  test "sets article attributes correctly" do
    user = users(:admin)
    params = {
      title: "Test Article",
      slug: "test-article",
      status: "draft",
      body: "<p>Test content</p>",
      excerpt: "Test excerpt"
    }

    result = Articles::Operation::Create.new.call(params: params, user: user)

    assert_equal "Test Article", result.value![:model].title
    assert_equal "test-article", result.value![:model].slug
    assert_equal "<p>Test content</p>", result.value![:model].body.content.to_s
  end

  test "persists markdown body as plain content" do
    user = users(:admin)
    params = {
      title: "Markdown Article",
      slug: "markdown-article",
      status: "draft",
      body: "# Heading\n\nBody text"
    }

    result = Articles::Operation::Create.new.call(params: params, user: user)

    assert_predicate result, :success?
    assert_equal "# Heading\n\nBody text", result.value![:model].body.content.to_s
    refute_match(/#<ActionText::Markdown:/, result.value![:model].body.content.to_s)
  end

  test "fails with invalid title" do
    user = users(:admin)
    params = {
      title: "",
      slug: "test-article",
      status: "draft"
    }

    result = Articles::Operation::Create.new.call(params: params, user: user)

    assert_predicate result, :failure?
    assert_predicate result.failure[:errors][:title], :any?
  end

  test "fails with invalid slug format" do
    user = users(:admin)
    params = {
      title: "Test Article",
      slug: "Test Article!",
      status: "draft"
    }

    result = Articles::Operation::Create.new.call(params: params, user: user)

    assert_predicate result, :failure?
    assert_predicate result.failure[:errors][:slug], :any?
  end

  test "fails when published article has no published_at" do
    user = users(:admin)
    params = {
      title: "Published Article",
      slug: "published-article-no-date",
      status: "published",
      body: "<p>Published content</p>"
    }

    result = Articles::Operation::Create.new.call(params: params, user: user)

    assert_predicate result, :failure?
    assert_predicate result.failure[:errors][:published_at], :any?
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
      status: "draft"
    }

    result = Articles::Operation::Create.new.call(params: params, user: user)

    assert_predicate result, :failure?
    assert result.failure[:errors][:slug].any? { |msg| msg.include?("already exists") || msg.include?("taken") }
  end

  test "creates published article with published_at" do
    user = users(:admin)
    published_at = 1.day.ago
    params = {
      title: "Published Article",
      slug: "published-article-unique-#{Time.current.to_i}",
      status: "published",
      body: "<p>Published content</p>",
      published_at: published_at
    }

    result = Articles::Operation::Create.new.call(params: params, user: user)

    assert_predicate result, :success?
    assert_predicate result.value![:model], :status_published?
    assert_equal published_at.to_i, result.value![:model].published_at.to_i
  end

  test "auto-generates slug when blank" do
    user = users(:admin)
    params = {
      title: "How to Ship Rails Features",
      slug: "",
      status: "draft"
    }

    result = Articles::Operation::Create.new.call(params: params, user: user)

    assert_predicate result, :success?
    assert_match(/\Ahow-to-ship-rails-features-[a-z0-9]{6}\z/, result.value![:model].slug)
  end

  test "retries generated slug when collision happens" do
    user = users(:admin)
    Article.create!(title: "Existing", slug: "my-title-aaaaaa", status: :draft, user: user)

    params = {
      title: "My Title",
      slug: "",
      status: "draft"
    }

    suffix_values = [ "aaaaaa", "bbbbbb" ]
    operation_class = Class.new(Articles::Operation::Create) do
      define_method(:random_slug_suffix) { suffix_values.shift || "cccccc" }
    end

    result = operation_class.new.call(params: params, user: user)

    assert_predicate result, :success?
    assert_equal "my-title-bbbbbb", result.value![:model].slug
  end
end
