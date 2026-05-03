require "test_helper"

class Articles::Operation::UnpublishTest < ActiveSupport::TestCase
  test "unpublishes published article" do
    user = users(:admin)
    article = Article.create!(
      title: "Test Article",
      slug: "test-article-unpublish",
      status: :published,
      body: "<p>Test content</p>",
      published_at: Time.current,
      user: user
    )

    result = Articles::Operation::Unpublish.new.call(model: article)

    assert_predicate result, :success?
    assert_predicate result.value![:model].reload, :status_draft?
    assert_nil result.value![:model].published_at
  end

  test "fails to unpublish draft article" do
    user = users(:admin)
    article = Article.create!(
      title: "Test Article",
      slug: "test-article-draft",
      status: :draft,
      body: "<p>Test content</p>",
      user: user
    )

    result = Articles::Operation::Unpublish.new.call(model: article)

    assert_predicate result, :failure?
    assert_predicate result.failure[:errors][:base], :any?
  end

  test "requires model parameter" do
    assert_raises(ArgumentError) do
      Articles::Operation::Unpublish.new.call
    end
  end
end
