require "test_helper"

class ActionText::MarkdownTest < ActiveSupport::TestCase
  test "requires a name" do
    markdown = ActionText::Markdown.new(content: "hello")

    assert_not markdown.valid?
    assert_includes markdown.errors[:name], "can't be blank"
  end

  test "valid when name is present" do
    # we'll supply the minimal association required by the belongs_to
    # (polymorphic) so that record_type/record_id non‑null constraints are
    # satisfied. Article is a convenient model for this test.
    article = Article.create!(title: "X", slug: "x", status: :draft, user: users(:admin))
    markdown = ActionText::Markdown.new(name: "body", record: article, content: "foo")
    assert markdown.valid?
  end
end
