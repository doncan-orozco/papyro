# frozen_string_literal: true

module Views
  module DesignSystem
    class Index::StatusPanel < Views::Base
      def view_template
        div(class: "mt-12 p-6 bg-muted rounded-lg") do
          h3(class: "font-bold mb-2") { t("design_system.catalog.status.title") }
          ul(class: "text-sm text-muted-foreground space-y-1") do
            t("design_system.catalog.status.items").each do |item|
              li { item }
            end
          end
        end
      end
    end
  end
end
