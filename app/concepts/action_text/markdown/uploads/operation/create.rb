# frozen_string_literal: true

module ActionText
  class Markdown
    module Uploads
      module Operation
        class Create < Core::Operation
          def call(record:, attribute_name:, file:)
            markdown = step find_markdown(record: record, attribute_name: attribute_name)
            persisted_markdown = step attach_upload(markdown: markdown, file: file)

            { markdown: persisted_markdown, upload: persisted_markdown.uploads.attachments.last }
          end

          private

          def find_markdown(record:, attribute_name:)
            markdown = record.safe_markdown_attribute(attribute_name)
            return Success(markdown) if markdown.present?

            fail_with_code!(
              record,
              :invalid_markdown_attribute,
              message: I18n.t("errors.messages.invalid_markdown_attribute")
            )
          end

          def attach_upload(markdown:, file:)
            markdown.uploads.attach([ normalize_attachable(file) ])

            return Success(markdown) if markdown.save

            fail_with_model!(markdown)
          end

          def normalize_attachable(file)
            return file unless file.respond_to?(:to_h)

            file_hash = if file.respond_to?(:to_unsafe_h)
              file.to_unsafe_h
            else
              file.to_h
            end

            {
              io: file_hash.fetch("tempfile"),
              filename: file_hash.fetch("original_filename"),
              content_type: file_hash.fetch("content_type")
            }
          end
        end
      end
    end
  end
end
