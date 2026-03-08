# frozen_string_literal: true

require "test_helper"

class Articles::Contract::CreateTest < ActiveSupport::TestCase
  setup do
    @user = users(:admin)
  end

  test "accepts valid article data" do
    contract = Articles::Contract::Create.new
    result = contract.call(
      title: "Valid Article",
      slug: "valid-article",
      status: "draft",
      body: "<p>Content</p>",
      user_id: @user.id
    )

    assert_predicate result, :success?
  end

  test "rejects blank title" do
    contract = Articles::Contract::Create.new
    result = contract.call(
      title: "",
      slug: "test-blank-title",
      status: "draft",
      user_id: @user.id
    )

    assert_predicate result, :failure?
    assert_predicate result.errors[:title], :present?
  end

  test "rejects title longer than 255 characters" do
    contract = Articles::Contract::Create.new
    result = contract.call(
      title: "a" * 256,
      slug: "test-long-title",
      status: "draft",
      user_id: @user.id
    )

    assert_predicate result, :failure?
    assert result.errors[:title].any? { |e| e.include?("too long") }
  end

  test "rejects invalid slug format" do
    contract = Articles::Contract::Create.new
    result = contract.call(
      title: "Test",
      slug: "Invalid_Slug-123", # Has underscore and uppercase
      status: "draft",
      user_id: @user.id
    )

    assert_predicate result, :failure?
    assert result.errors[:slug].any? { |e| e.include?("must contain only lowercase") }
  end

  test "rejects duplicate slug" do
    Article.create!(
      user: @user,
      title: "Existing",
      slug: "existing-article",
      status: :draft
    )

    contract = Articles::Contract::Create.new
    result = contract.call(
      title: "New Article",
      slug: "existing-article", # Already taken
      status: "draft",
      user_id: @user.id
    )

    assert_predicate result, :failure?
    assert result.errors[:slug].any? { |e| e.include?("already been taken") }
  end

  test "rejects invalid status" do
    contract = Articles::Contract::Create.new
    result = contract.call(
      title: "Test",
      slug: "test-invalid-status",
      status: "invalid_status",
      user_id: @user.id
    )

    assert_predicate result, :failure?
    assert_predicate result.errors[:status], :present?
  end

  test "requires published_at when status is published" do
    contract = Articles::Contract::Create.new
    result = contract.call(
      title: "Test",
      slug: "test-requires-published-at",
      status: "published",
      published_at: nil,
      user_id: @user.id
    )

    assert_predicate result, :failure?
    assert_predicate result.errors[:published_at], :present?
  end

  test "rejects future published_at date" do
    contract = Articles::Contract::Create.new
    result = contract.call(
      title: "Test",
      slug: "test-future-date",
      status: "published",
      published_at: 1.day.from_now,
      user_id: @user.id
    )

    assert_predicate result, :failure?
    assert_predicate result.errors[:published_at], :present?
  end

  test "rejects non-existent user" do
    contract = Articles::Contract::Create.new
    result = contract.call(
      title: "Test",
      slug: "test-nonexistent-user",
      status: "draft",
      user_id: 99999 # Non-existent ID
    )

    assert_predicate result, :failure?
    assert_predicate result.errors[:user_id], :present?
  end

  test "accepts optional content and excerpt" do
    contract = Articles::Contract::Create.new
    result = contract.call(
      title: "Test",
      slug: "test-optional-fields",
      status: "draft",
      body: nil,
      excerpt: nil,
      user_id: @user.id
    )

    assert_predicate result, :success?
  end

  test "rejects content longer than 100,000 characters" do
    contract = Articles::Contract::Create.new
    result = contract.call(
      title: "Test",
      slug: "test-long-content",
      status: "draft",
      body: "a" * 100_001,
      user_id: @user.id
    )

    assert_predicate result, :failure?
    assert result.errors[:body].any? { |e| e.include?("too long") }
  end

  test "rejects excerpt longer than 500 characters" do
    contract = Articles::Contract::Create.new
    result = contract.call(
      title: "Test",
      slug: "test-long-excerpt",
      status: "draft",
      excerpt: "a" * 501,
      user_id: @user.id
    )

    assert_predicate result, :failure?
    assert result.errors[:excerpt].any? { |e| e.include?("too long") }
  end

  test "rejects slug longer than 255 characters" do
    contract = Articles::Contract::Create.new
    result = contract.call(
      title: "Test",
      slug: "a" * 256,
      status: "draft",
      user_id: @user.id
    )

    assert_predicate result, :failure?
    assert result.errors[:slug].any? { |e| e.include?("too long") }
  end

  test "accepts valid slug formats" do
    contract = Articles::Contract::Create.new

    # Test lowercase with hyphens
    result = contract.call(
      title: "Test",
      slug: "valid-slug-123",
      status: "draft",
      user_id: @user.id
    )

    assert_predicate result, :success?

    # Test all lowercase
    result = contract.call(
      title: "Test",
      slug: "validslug",
      status: "draft",
      user_id: @user.id
    )

    assert_predicate result, :success?

    # Test with numbers
    result = contract.call(
      title: "Test",
      slug: "slug123",
      status: "draft",
      user_id: @user.id
    )

    assert_predicate result, :success?
  end

  test "accepts published status with valid published_at" do
    contract = Articles::Contract::Create.new
    result = contract.call(
      title: "Test",
      slug: "test-published-article",
      status: "published",
      published_at: 1.day.ago,
      user_id: @user.id
    )

    assert_predicate result, :success?
  end

  test "accepts archived status" do
    contract = Articles::Contract::Create.new
    result = contract.call(
      title: "Test",
      slug: "test-archived",
      status: "archived",
      user_id: @user.id
    )

    assert_predicate result, :success?
  end
end

class Articles::Contract::UpdateTest < ActiveSupport::TestCase
  setup do
    @user = users(:admin)
    @article = @user.articles.create!(
      title: "Original",
      slug: "original-article",
      status: :draft
    )
  end

  test "allows slug to remain unchanged" do
    contract = Articles::Contract::Update.new
    result = contract.call(
      id: @article.id,
      title: "Updated",
      slug: "original-article", # Same slug
      status: "draft",
      user_id: @user.id
    )

    assert_predicate result, :success?
  end

  test "rejects duplicate slug from other articles" do
    other = @user.articles.create!(
      title: "Other",
      slug: "other-article",
      status: :draft
    )

    contract = Articles::Contract::Update.new
    result = contract.call(
      id: @article.id,
      title: "Updated",
      slug: "other-article", # Already used by other article
      status: "draft",
      user_id: @user.id
    )

    assert_predicate result, :failure?
    assert_predicate result.errors[:slug], :present?
  end

  test "accepts new unique slug" do
    contract = Articles::Contract::Update.new
    result = contract.call(
      id: @article.id,
      title: "Updated",
      slug: "new-unique-slug",
      status: "draft",
      user_id: @user.id
    )

    assert_predicate result, :success?
  end
end
