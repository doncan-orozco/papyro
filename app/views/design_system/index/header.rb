# frozen_string_literal: true

module Views
  module DesignSystem
    class Index::Header < Views::Base
      def view_template
        header(class: "border-b border-border bg-card") do
          div(class: "max-w-7xl mx-auto px-4 py-6") do
            div(class: "flex items-center justify-between") do
              div do
                h1(class: "text-3xl font-bold") { t("design_system.catalog.title") }
                p(class: "text-muted-foreground mt-2") { t("design_system.catalog.subtitle") }
              end

              render Components::Shared::ThemeToggle.new
            end
          end
        end
      end
    end
  end
end
