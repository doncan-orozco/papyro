# frozen_string_literal: true

module Views
  module DesignSystem
    class Index::CategoryNav < Views::Base
      def view_template
        div(class: "border-b border-border bg-card/50") do
          div(class: "max-w-7xl mx-auto px-4 py-4") do
            div(class: "flex gap-2 flex-wrap") do
              category_button(id: "foundation", label: t("design_system.catalog.categories.foundation"), active: true)
              category_button(id: "forms", label: t("design_system.catalog.categories.forms"))
              category_button(id: "feedback", label: t("design_system.catalog.categories.feedback"))
              category_button(id: "overlays", label: t("design_system.catalog.categories.overlays"))
              category_button(id: "tables", label: t("design_system.catalog.categories.tables"))
              category_button(id: "complex", label: t("design_system.catalog.categories.complex"))
            end
          end
        end
      end

      private

      def category_button(id:, label:, active: false)
        render Components::Ui::Button.new(
          variant: :ghost,
          size: :sm,
          class: "data-[state=active]:bg-primary data-[state=active]:text-primary-foreground",
          data: {
            action: "click->design-system#select",
            design_system_target: "tab",
            category: id,
            state: active ? "active" : "inactive"
          }
        ) { label }
      end
    end
  end
end
