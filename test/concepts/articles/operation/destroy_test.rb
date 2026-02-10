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
    assert result[:errors][:base].any?
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
end
