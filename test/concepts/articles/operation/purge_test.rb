require "test_helper"

class Articles::Operation::PurgeTest < ActiveSupport::TestCase
  test "purges article record" do
    article = Article.create!(
      title: "Purge me",
      slug: "purge-me-#{SecureRandom.hex(4)}",
      body: "Body",
      user: users(:admin)
    )

    result = Articles::Operation::Purge.new.call(model: article)

    assert_predicate result, :success?
    assert_nil Article.find_by(id: article.id)
  end

  test "returns failure when destroy fails" do
    article = articles(:draft_article)
    article.define_singleton_method(:destroy) do
      errors.add(:base, "cannot purge")
      false
    end

    result = Articles::Operation::Purge.new.call(model: article)

    assert_predicate result, :failure?
    assert_equal article, result.failure[:model]
    assert_includes result.failure[:errors][:base], "cannot purge"
  end
end
