require "test_helper"
require "securerandom"

module Studio
  class ArticlePolicyTest < ActiveSupport::TestCase
    setup do
      @owner = users(:admin)
      @other_user = users(:one)
      @article = Article.create!(
        title: "Policy Article",
        slug: "policy-article-#{SecureRandom.hex(4)}",
        status: :draft,
        body: "Body",
        user: @owner
      )
    end

    test "new? and create? require authenticated user" do
      assert_predicate ArticlePolicy.new(@owner, Article.new), :new?
      assert_predicate ArticlePolicy.new(@owner, Article.new), :create?

      refute_predicate ArticlePolicy.new(nil, Article.new), :new?
      refute_predicate ArticlePolicy.new(nil, Article.new), :create?
    end

    test "edit/update/destroy are owner only" do
      owner_policy = ArticlePolicy.new(@owner, @article)
      other_policy = ArticlePolicy.new(@other_user, @article)

      assert_predicate owner_policy, :edit?
      assert_predicate owner_policy, :update?
      assert_predicate owner_policy, :destroy?

      refute_predicate other_policy, :edit?
      refute_predicate other_policy, :update?
      refute_predicate other_policy, :destroy?
    end

    test "scope resolves only current user's articles" do
      other_article = Article.create!(
        title: "Other Article",
        slug: "other-policy-article-#{SecureRandom.hex(4)}",
        status: :draft,
        body: "Body",
        user: @other_user
      )

      scope = ArticlePolicy::Scope.new(@owner, Article.all).resolve

      assert_includes scope, @article
      assert_not_includes scope, other_article
    end
  end
end
