# frozen_string_literal: true

module Views
  module DesignSystem
    class Index::ComplexSection < Views::Base
      include Index::Shared::SectionHelpers

      def view_template
        section_container(id: "complex") do
          div(class: "space-y-8") do
            h2(class: "text-2xl font-bold") { t("design_system.catalog.complex.title") }

            render Components::Ui::Card.new do |card|
              card.header do
                card.title { t("design_system.catalog.complex.card_title") }
                card.description do
                  t("design_system.catalog.complex.card_description")
                end
              end

              card.content do
                p(class: "text-muted-foreground") { t("design_system.catalog.complex.body") }

                div(class: "mt-4 grid grid-cols-2 gap-2 text-sm") do
                  complex_components.each do |component_name|
                    div(class: "px-3 py-2 rounded-md border border-border bg-muted/40") { component_name }
                  end
                end
              end
            end
          end
        end
      end

      private

      def complex_components
        [
          "accordion",
          "calendar",
          "carousel",
          "command",
          "context-menu",
          "navigation-menu",
          "pagination",
          "popover",
          "progress",
          "scroll-area",
          "slider",
          "sonner",
          "toggle-group"
        ]
      end
    end
  end
end
