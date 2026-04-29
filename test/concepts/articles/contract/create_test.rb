require "test_helper"

class Articles::Contract::CreateTest < ActiveSupport::TestCase
  setup do
    @user = users(:admin)
  end

  test "succeeds with valid attributes" do
    result = Articles::Contract::Create.new.call(
      title: "Valid title",
      slug: "valid-title",
      status: "draft",
      body: "body",
      user_id: @user.id
    )

    assert_predicate result, :success?
  end

  test "fails for invalid slug format" do
    result = Articles::Contract::Create.new.call(
      title: "Valid title",
      slug: "Invalid Slug!",
      status: "draft",
      user_id: @user.id
    )

    assert_predicate result, :failure?
    assert result.errors.to_h.key?(:slug)
  end

  test "fails for duplicate slug" do
    Article.create!(title: "Original", slug: "duplicate", status: :draft, user: @user, body: "body")

    result = Articles::Contract::Create.new.call(
      title: "Another",
      slug: "duplicate",
      status: "draft",
      user_id: @user.id
    )

    assert_predicate result, :failure?
    assert result.errors.to_h.key?(:slug)
  end

  test "fails when published article has no published_at" do
    result = Articles::Contract::Create.new.call(
      title: "Published article",
      slug: "published-article",
      status: "published",
      user_id: @user.id
    )

    assert_predicate result, :failure?
    assert result.errors.to_h.key?(:published_at)
  end
end
