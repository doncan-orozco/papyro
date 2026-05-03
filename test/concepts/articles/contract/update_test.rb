require "test_helper"

class Articles::Contract::UpdateTest < ActiveSupport::TestCase
  setup do
    @user = users(:admin)
    @article = Article.create!(title: "Original", slug: "original", status: :draft, user: @user, body: "body")
    @other_article = Article.create!(title: "Other", slug: "other", status: :draft, user: @user, body: "body")
  end

  test "succeeds with all fields provided" do
    result = Articles::Contract::Update.new.call(
      title: "Updated title",
      slug: "original",
      status: "draft"
    )

    assert_predicate result, :success?
  end

  test "succeeds with partial params (title only)" do
    result = Articles::Contract::Update.new.call(title: "New Title")

    assert_predicate result, :success?
    assert_equal "New Title", result.to_h[:title]
  end

  test "succeeds with empty params" do
    result = Articles::Contract::Update.new.call({})

    assert_predicate result, :success?
  end

  test "allows another article slug at contract layer" do
    result = Articles::Contract::Update.new.call(
      title: "Updated title",
      slug: @other_article.slug,
      status: "draft"
    )

    assert_predicate result, :success?
  end

  test "succeeds for invalid status at contract layer" do
    result = Articles::Contract::Update.new.call(
      title: "Updated title",
      slug: @article.slug,
      status: "invalid"
    )

    assert_predicate result, :success?
  end
end
