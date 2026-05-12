require "test_helper"

module Articles
  class EmptyTrashJobTest < ActiveJob::TestCase
    test "purges only articles trashed more than 30 days ago" do
      user = users(:admin)

      stale_article = Article.create!(
        title: "Stale trashed article",
        slug: "stale-trashed-article",
        body: "Body",
        user: user,
        deleted_at: 31.days.ago
      )

      recent_article = Article.create!(
        title: "Recent trashed article",
        slug: "recent-trashed-article",
        body: "Body",
        user: user,
        deleted_at: 5.days.ago
      )

      kept_article = Article.create!(
        title: "Kept article",
        slug: "kept-article-for-trash-job",
        body: "Body",
        user: user
      )

      assert_difference("Article.count", -1) do
        Articles::EmptyTrashJob.perform_now
      end

      assert_nil Article.find_by(id: stale_article.id)
      assert_not_nil Article.find_by(id: recent_article.id)
      assert_not_nil Article.find_by(id: kept_article.id)
    end
  end
end
