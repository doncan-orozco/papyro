require "test_helper"

class CleanupEmptyDraftsJobTest < ActiveJob::TestCase
  test "deletes stale empty draft placeholders" do
    user = users(:admin)
    stale_empty_draft = Article.create!(
      title: I18n.t("studio.articles.editor.untitled"),
      slug: "cleanup-empty-aaaaaa",
      status: :draft,
      body: "",
      user: user,
      created_at: 2.days.ago,
      updated_at: 2.days.ago
    )

    assert_difference("Article.count", -1) do
      CleanupEmptyDraftsJob.perform_now
    end

    assert_nil Article.find_by(id: stale_empty_draft.id)
  end

  test "keeps stale drafts with user content" do
    user = users(:admin)
    stale_content_draft = Article.create!(
      title: I18n.t("studio.articles.editor.untitled"),
      slug: "cleanup-keep-aaaaaa",
      status: :draft,
      body: "<p>Has content</p>",
      user: user,
      created_at: 2.days.ago,
      updated_at: 2.days.ago
    )

    assert_no_difference("Article.count") do
      CleanupEmptyDraftsJob.perform_now
    end

    assert_not_nil Article.find_by(id: stale_content_draft.id)
  end

  test "keeps recent empty drafts" do
    user = users(:admin)
    recent_empty_draft = Article.create!(
      title: I18n.t("studio.articles.editor.untitled"),
      slug: "cleanup-recent-aaaaaa",
      status: :draft,
      body: "",
      user: user,
      created_at: 2.hours.ago,
      updated_at: 2.hours.ago
    )

    assert_no_difference("Article.count") do
      CleanupEmptyDraftsJob.perform_now
    end

    assert_not_nil Article.find_by(id: recent_empty_draft.id)
  end
end
