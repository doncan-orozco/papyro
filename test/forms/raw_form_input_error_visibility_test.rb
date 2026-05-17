# frozen_string_literal: true

require "test_helper"

class RawFormInputErrorVisibilityTest < ActiveSupport::TestCase
  RAW_INPUT_HELPERS = %w[file_field text_field text_area email_field password_field search_field url_field select].freeze

  test "raw form inputs render corresponding inline errors" do
    offenses = []

    Dir.glob(Rails.root.join("app/views/**/*.rb")).sort.each do |file_path|
      file_content = File.read(file_path)

      file_content.each_line.with_index(1) do |line, line_number|
        match = line.match(/\.(#{RAW_INPUT_HELPERS.join("|")})\s+:([a-z_][a-z0-9_]*)/)
        next if match.blank?

        helper_name = match[1]
        field_name = match[2]

        next if inline_error_rendered_for_field?(file_content, field_name)

        offenses << "#{relative_path(file_path)}:#{line_number} uses .#{helper_name} :#{field_name} without inline error rendering"
      end
    end

    assert offenses.empty?, <<~MESSAGE
      Raw form input helpers must render inline errors for the same field.

      Fix options:
      - Prefer form.field :attribute (auto-renders field_errors)
      - Or render explicit errors (for example form.field_errors(:attribute), render_field_errors(:attribute), or object.errors[:attribute])

      Offenses:
      #{offenses.join("\n")}
    MESSAGE
  end

  private

  def inline_error_rendered_for_field?(file_content, field_name)
    symbol_name = Regexp.escape(field_name)

    patterns = [
      /\.field_errors\(\s*:#{symbol_name}\s*\)/,
      /render_field_errors\(\s*:#{symbol_name}\s*\)/,
      /errors\[\s*:#{symbol_name}\s*\]/,
      /errors\[\s*[\"']#{symbol_name}[\"']\s*\]/
    ]

    patterns.any? { |pattern| file_content.match?(pattern) }
  end

  def relative_path(file_path)
    Pathname.new(file_path).relative_path_from(Rails.root).to_s
  end
end
