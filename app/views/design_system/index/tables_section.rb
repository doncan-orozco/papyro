# frozen_string_literal: true

module Views
  module DesignSystem
    class Index::TablesSection < Views::Base
      include Index::Shared::SectionHelpers

      def view_template
        section_container(id: "tables") do
          div(class: "space-y-8") do
            h2(class: "text-2xl font-bold") { t("design_system.catalog.tables.title") }
            render Index::TablesSection::BasicExamples.new
            render Index::TablesSection::RichExamples.new
            render Index::TablesSection::InteractiveExamples.new
          end
        end
      end
    end
  end
end
