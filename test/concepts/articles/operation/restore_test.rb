require "test_helper"

class Articles::Operation::RestoreTest < ActiveSupport::TestCase
  test "restores soft-deleted article" do
    article = Article.create!(
      title: "Restore me",
      slug: "restore-me-#{SecureRandom.hex(4)}",
      body: "Body",
      user: users(:admin),
      deleted_at: 1.day.ago
    )

    result = Articles::Operation::Restore.new.call(model: article)

    assert_predicate result, :success?
    assert_nil article.reload.deleted_at
  end

  test "returns failure when update fails" do
    article = articles(:draft_article)
    article.define_singleton_method(:update) do |_attrs|
      errors.add(:base, "cannot restore")
      false
    end

    result = Articles::Operation::Restore.new.call(model: article)

    assert_predicate result, :failure?
    assert_equal article, result.failure[:model]
    assert_includes result.failure[:errors][:base], "cannot restore"
  end
end
