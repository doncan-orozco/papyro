require "test_helper"

class Articles::Service::ContentAnalysisTest < ActiveSupport::TestCase
  test "extracts plain and searchable text from markdown body" do
    article = Article.create!(
      title: "Analysis",
      slug: "analysis-#{SecureRandom.hex(4)}",
      body: "Hello **world**\n\nThis is _markdown_.",
      user: users(:admin)
    )

    service = Articles::Service::ContentAnalysis.new(article)

    assert_includes service.searchable_content, "Hello"
    assert_includes service.plain_text_body, "This is markdown."
  end

  test "counts unicode words and computes minimum reading time" do
    article = Article.create!(
      title: "Unicode",
      slug: "unicode-#{SecureRandom.hex(4)}",
      body: "L'été d'aujourd'hui est tres beau.",
      user: users(:admin)
    )

    service = Articles::Service::ContentAnalysis.new(article)

    assert_operator service.content_word_count, :>, 0
    assert_equal 1, service.estimated_reading_time_minutes
  end

  test "returns zero reading time when body has no words" do
    article = Article.create!(
      title: "Empty",
      slug: "empty-reading-#{SecureRandom.hex(4)}",
      body: "",
      user: users(:admin)
    )

    service = Articles::Service::ContentAnalysis.new(article)

    assert_equal 0, service.content_word_count
    assert_equal 0, service.estimated_reading_time_minutes
  end
end
