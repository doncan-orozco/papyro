require "test_helper"

class Articles::Contract::CreateTest < ActiveSupport::TestCase
  test "succeeds with valid attributes" do
    result = Articles::Contract::Create.new.call(
      title: "Valid title",
      slug: "valid-title",
      status: "draft",
      body: "body"
    )

    assert_predicate result, :success?
  end

  test "succeeds with invalid slug format at contract layer" do
    result = Articles::Contract::Create.new.call(
      title: "Valid title",
      slug: "Invalid Slug!",
      status: "draft"
    )

    assert_predicate result, :success?
  end

  test "allows duplicate slug at contract layer" do
    user = users(:admin)
    Article.create!(title: "Original", slug: "duplicate", status: :draft, user: user, body: "body")

    result = Articles::Contract::Create.new.call(
      title: "Another",
      slug: "duplicate",
      status: "draft"
    )

    assert_predicate result, :success?
  end

  test "succeeds when published article has no published_at at contract layer" do
    result = Articles::Contract::Create.new.call(
      title: "Published article",
      slug: "published-article",
      status: "published"
    )

    assert_predicate result, :success?
  end

  test "succeeds without slug so operation can auto-generate it" do
    result = Articles::Contract::Create.new.call(
      title: "Generated slug article",
      status: "draft"
    )

    assert_predicate result, :success?
  end
end
