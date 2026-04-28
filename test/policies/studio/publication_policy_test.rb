require "test_helper"
require "securerandom"

module Studio
  class PublicationPolicyTest < ActiveSupport::TestCase
    setup do
      @owner = users(:admin)
      @other_user = users(:one)
      @article = Article.create!(
        title: "Publishable",
        slug: "publishable-policy-#{SecureRandom.hex(4)}",
        status: :draft,
        body: "Body",
        user: @owner
      )
    end

    test "create? requires owner and article title presence" do
      assert_predicate PublicationPolicy.new(@owner, @article), :create?

      @article.title = ""

      refute_predicate PublicationPolicy.new(@owner, @article), :create?

      refute_predicate PublicationPolicy.new(@other_user, @article), :create?
    end

    test "destroy? is owner only" do
      assert_predicate PublicationPolicy.new(@owner, @article), :destroy?
      refute_predicate PublicationPolicy.new(@other_user, @article), :destroy?
    end
  end
end
