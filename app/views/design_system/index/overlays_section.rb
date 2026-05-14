# frozen_string_literal: true

module Views
  module DesignSystem
    class Index::OverlaysSection < Views::Base
      include Index::Shared::SectionHelpers

      def view_template
        section_container(id: "overlays") do
          div(class: "space-y-8") do
            h2(class: "text-2xl font-bold") { t("design_system.catalog.overlays.title") }
            render Index::OverlaysSection::QuickCards.new
            render Index::OverlaysSection::ModalCards.new
          end
        end
      end
    end
  end
end
