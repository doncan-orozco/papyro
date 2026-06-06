require "test_helper"

class ActionText::Markdown::Uploads::Operation::CreateTest < ActiveSupport::TestCase
  class FakeUploads
    attr_reader :attachments

    def initialize(markdown)
      @attachments = []
      @markdown = markdown
    end

    def attach(file)
      upload = {
        io: file["tempfile"],
        filename: file["original_filename"],
        content_type: file["content_type"]
      }
      @attachments << upload

      unless @markdown.save
        raise ActiveRecord::RecordInvalid.new(@markdown)
      end

      upload
    end
  end

  class FakeMarkdown
    include ActiveModel::Model

    attr_reader :uploads

    def initialize(save_result: true)
      super()
      @save_result = save_result
      @uploads = FakeUploads.new(self)
    end

    def save
      return true if @save_result

      errors.add(:base, "upload invalid")
      false
    end

    def reload
      self
    end
  end


  test "attaches upload and returns markdown and upload payload" do
    markdown = FakeMarkdown.new(save_result: true)
    record = Article.new
    record.define_singleton_method(:safe_markdown_attribute) { |_attribute_name| markdown }

    tempfile = Tempfile.new([ "upload", ".txt" ])
    tempfile.write("payload")
    tempfile.rewind

    file = {
      "tempfile" => tempfile,
      "original_filename" => "payload.txt",
      "content_type" => "text/plain"
    }

    result = ActionText::Markdown::Uploads::Operation::Create.new.call(
      record: record,
      attribute_name: :body,
      file: file
    )

    assert_predicate result, :success?
    assert_equal markdown, result.value![:markdown]

    upload = result.value![:upload]

    assert_equal tempfile, upload[:io]
    assert_equal "payload.txt", upload[:filename]
    assert_equal "text/plain", upload[:content_type]
  ensure
    tempfile.close!
  end

  test "fails with code when markdown attribute is invalid" do
    record = Article.new
    record.define_singleton_method(:safe_markdown_attribute) { |_attribute_name| nil }

    result = ActionText::Markdown::Uploads::Operation::Create.new.call(
      record: record,
      attribute_name: :unknown,
      file: StringIO.new("payload")
    )

    assert_predicate result, :failure?
    assert_equal :invalid_markdown_attribute, result.failure[:code]
    assert_equal I18n.t("errors.messages.invalid_markdown_attribute"), result.failure[:message]
  end

  test "fails when markdown save fails" do
    markdown = FakeMarkdown.new(save_result: false)
    record = Article.new
    record.define_singleton_method(:safe_markdown_attribute) { |_attribute_name| markdown }
    tempfile = Tempfile.new([ "upload", ".txt" ])
    tempfile.write("payload")
    tempfile.rewind

    result = ActionText::Markdown::Uploads::Operation::Create.new.call(
      record: record,
      attribute_name: :body,
      file: {
        "tempfile" => tempfile,
        "original_filename" => "payload.txt",
        "content_type" => "text/plain"
      }
    )

    assert_predicate result, :failure?
    assert_equal markdown, result.failure[:model]
    assert_includes result.failure[:errors][:base], "upload invalid"
  ensure
    tempfile.close!
  end
end
