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
            markdown.uploads.attach(file)

            Success(markdown.reload)
          rescue ActiveRecord::RecordInvalid, ArgumentError => error
            markdown.errors.add(:base, error.message)
            fail_with_model!(markdown)
          end
        end
      end
    end
  end
end
