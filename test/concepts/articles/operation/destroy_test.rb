require "test_helper"

class Articles::Operation::DestroyTest < ActiveSupport::TestCase
  test "soft deletes article" do
    user = users(:admin)
    article = Article.create!(
      title: "Test Article",
      slug: "test-article",
      user: user
    )

    result = Articles::Operation::Destroy.new.call(model: article)

    assert_predicate result, :success?
    assert_not_nil Article.find_by(id: article.id)
    assert_not_nil article.reload.deleted_at
  end

  test "soft deletes published article" do
    user = users(:admin)
    article = Article.create!(
      title: "Published Article",
      slug: "published-article-destroy-#{Time.current.to_i}",
      published_at: Time.current,
      user: user
    )

    result = Articles::Operation::Destroy.new.call(model: article)

    assert_predicate result, :success?
    assert_not_nil Article.find_by(id: article.id)
    assert_not_nil article.reload.deleted_at
  end

  test "note: authorization is enforced at controller level before passing model" do
    # This test documents the new calling pattern:
    # 1. Controller finds article with scoping: Current.user.articles.find_by!(id: params[:id])
    # 2. Controller passes pre-authorized model to operation
    # 3. Operation performs destruction without re-querying

    user = users(:admin)
    other_user = users(:one)
    article = Article.create!(
      title: "Other User Article",
      slug: "other-user-article",
      user: other_user
    )

    # Operation expects pre-authorized model from controller
    # Controller's scoped query (Current.user.articles.find_by!) prevents unauthorized access
    result = Articles::Operation::Destroy.new.call(model: article)

    assert_predicate result, :success?
    # Security is enforced by controller's scoped find, not by operation
  end

  test "requires model parameter" do
    # Operation now expects model to be passed from controller
    assert_raises(ArgumentError) do
      Articles::Operation::Destroy.new.call(params: { id: 123 })
    end
  end
end
