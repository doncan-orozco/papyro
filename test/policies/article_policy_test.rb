require "test_helper"
require "securerandom"

class ArticlePolicyTest < ActiveSupport::TestCase
  setup do
    @owner = users(:one)
    @other_user = users(:two)
    @published_article = articles(:published_article)
    @draft_article = articles(:draft_article)
  end

  # index?
  test "anyone can list articles" do
    assert_predicate ArticlePolicy.new(nil, Article), :index?
    assert_predicate ArticlePolicy.new(@owner, Article), :index?
  end

  # show?
  test "anyone can view a published article" do
    assert_predicate ArticlePolicy.new(nil, @published_article), :show?
    assert_predicate ArticlePolicy.new(@other_user, @published_article), :show?
  end

  test "owner can view their own draft article" do
    draft = Article.create!(
      title: "My Draft",
      slug: "my-draft-#{SecureRandom.hex(4)}",
      body: "Body",
      user: @owner
    )

    assert_predicate ArticlePolicy.new(@owner, draft), :show?
  end

  test "non-owner cannot view a draft article" do
    draft = Article.create!(
      title: "Other Draft",
      slug: "other-draft-#{SecureRandom.hex(4)}",
      body: "Body",
      user: @other_user
    )

    refute_predicate ArticlePolicy.new(@owner, draft), :show?
    refute_predicate ArticlePolicy.new(nil, draft), :show?
  end

  # create?
  test "authenticated user can create an article" do
    assert_predicate ArticlePolicy.new(@owner, Article.new), :create?
  end

  test "unauthenticated visitor cannot create an article" do
    refute_predicate ArticlePolicy.new(nil, Article.new), :create?
  end

  # update? / destroy?
  test "owner can update and destroy their article" do
    article = Article.create!(
      title: "Owned Article",
      slug: "owned-article-#{SecureRandom.hex(4)}",
      body: "Body",
      user: @owner
    )

    assert_predicate ArticlePolicy.new(@owner, article), :update?
    assert_predicate ArticlePolicy.new(@owner, article), :destroy?
  end

  test "non-owner cannot update or destroy an article" do
    article = Article.create!(
      title: "Another Article",
      slug: "another-article-#{SecureRandom.hex(4)}",
      body: "Body",
      user: @other_user
    )

    refute_predicate ArticlePolicy.new(@owner, article), :update?
    refute_predicate ArticlePolicy.new(@owner, article), :destroy?
  end

  # Scope
  test "scope returns only published articles for unauthenticated visitor" do
    scope = ArticlePolicy::Scope.new(nil, Article.all).resolve

    scope.each { |a| assert_predicate a, :published? }
  end

  test "scope returns the user's own articles regardless of status" do
    draft = Article.create!(
      title: "Scope Draft",
      slug: "scope-draft-#{SecureRandom.hex(4)}",
      body: "Body",
      user: @owner
    )

    scope = ArticlePolicy::Scope.new(@owner, Article.all).resolve

    assert_includes scope, draft
  end
end
