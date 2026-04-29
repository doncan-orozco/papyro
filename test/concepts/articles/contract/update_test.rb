require "test_helper"

class Articles::Contract::UpdateTest < ActiveSupport::TestCase
  setup do
    @user = users(:admin)
    @article = Article.create!(title: "Original", slug: "original", status: :draft, user: @user, body: "body")
    @other_article = Article.create!(title: "Other", slug: "other", status: :draft, user: @user, body: "body")
  end

  test "succeeds when keeping the same slug for the same article" do
    result = Articles::Contract::Update.new(article_id: @article.id).call(
      title: "Updated title",
      slug: "original",
      status: "draft"
    )

    assert_predicate result, :success?
  end

  test "fails when using another article slug" do
    result = Articles::Contract::Update.new(article_id: @article.id).call(
      title: "Updated title",
      slug: @other_article.slug,
      status: "draft"
    )

    assert_predicate result, :failure?
    assert result.errors.to_h.key?(:slug)
  end

  test "fails for invalid status" do
    result = Articles::Contract::Update.new(article_id: @article.id).call(
      title: "Updated title",
      slug: @article.slug,
      status: "invalid"
    )

    assert_predicate result, :failure?
    assert result.errors.to_h.key?(:status)
  end
end
