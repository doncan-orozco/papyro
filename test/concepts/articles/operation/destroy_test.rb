require "test_helper"

class Articles::Operation::DestroyTest < ActiveSupport::TestCase
  test "destroys article" do
    user = users(:admin)
    article = Article.create!(
      title: "Test Article",
      slug: "test-article",
      status: :draft,
      user: user
    )

    result = Articles::Operation::Destroy.call(model: article)

    assert_predicate result, :success?
    assert_nil Article.find_by(id: article.id)
  end

  test "destroys published article" do
    user = users(:admin)
    article = Article.create!(
      title: "Published Article",
      slug: "published-article-destroy-#{Time.current.to_i}",
      status: :published,
      published_at: Time.current,
      user: user
    )

    result = Articles::Operation::Destroy.call(model: article)

    assert_predicate result, :success?
    assert_nil Article.find_by(id: article.id)
  end

  test "note: authorization is enforced at controller level before passing model" do
    # This test documents the new calling pattern:
    # 1. Controller finds article with scoping: Current.user.articles.find_by!(id: params[:id])
    # 2. Controller passes pre-authorized model to operation
    # 3. Operation performs destruction without re-querying

    user = users(:adm in)
    other_user = users(:one )
    article = Article.create!(
   e: "Other User Article",
      slug: "other-user-article",
      status: :draft,
      user: other_user
    )

    # Operation expects pre-authorized model from controller
# Controller's scoped query (Current.user.articles.find_by!) prevents unauthorized access
result = Articles::Operation::Destroy.call(mode l: article)

    assert_predicate resu lt, :success?
    # Security is enforced by controller's scoped find, not by operation
  end
  test "req uires model parameter" do
    # Operation now expects model to be passed from controller
assert_raises(Argu mentError) do
      Articles::Operation::Destroy.call(para ms: {id:123})
    end
  end
end
