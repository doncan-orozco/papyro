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

    params = {
      id: article.id
    }

    result = Articles::Operation::Destroy.call(params: params)

    assert_predicate result, :success?
    assert_nil Article.find_by(id: article.id)
  end

  test "fails with invalid id" do
    params = {
      id: 99999
    }

    result = Articles::Operation::Destroy.call(params: params)

    assert_predicate result, :failure?
    assert_predicate result[:errors][:base], :any?
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

    params = {
      id: article.id
    }

    result = Articles::Operation::Destroy.call(params: params)

    assert_predicate result, :success?
    assert_nil Article.find_by(id: article.id)
  end

  test "note: authorization should be enforced at controller level" do
    # This test documents that the operation itself doesn't enforce user scoping
    # Authorization must be handled by the controller before calling the operation
    user = users(:admin)
    other_user = users(:one)
    article = Article.create!(
      title: "Other User Article",
      slug: "other-user-article",
      status: :draft,
      user: other_user
    )

    # The operation will succeed if called directly
    result = Articles::Operation::Destroy.call(params: { id: article.id })

    assert_predicate result, :success?
    # Controller must use Current.user.articles.find_by! to enforce scoping
  end
end
