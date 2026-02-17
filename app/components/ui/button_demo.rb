module Components
  module Ui
    # Demo component showing all button variants and configurations
    # Remove this file when no longer needed for reference
    class ButtonDemo < Components::Base
      def view_template
        div(class: "space-y-8 p-8") do
          # Variants Section
          section do
            h2(class: "text-2xl font-bold mb-4") { "Button Variants" }
            div(class: "flex flex-wrap gap-3") do
              render Button.new(variant: :default) { "Default" }
              render Button.new(variant: :secondary) { "Secondary" }
              render Button.new(variant: :outline) { "Outline" }
              render Button.new(variant: :ghost) { "Ghost" }
              render Button.new(variant: :destructive) { "Destructive" }
              render Button.new(variant: :link) { "Link" }
            end
          end

          # Sizes Section
          section do
            h2(class: "text-2xl font-bold mb-4") { "Sizes" }
            div(class: "flex flex-wrap gap-3 items-center") do
              render Button.new(size: :xs) { "Extra Small" }
              render Button.new(size: :sm) { "Small" }
              render Button.new(size: :default) { "Default" }
              render Button.new(size: :lg) { "Large" }
            end
          end

          # States Section
          section do
            h2(class: "text-2xl font-bold mb-4") { "States" }
            div(class: "flex flex-wrap gap-3") do
              render Button.new(disabled: true) { "Disabled" }
              render Button.new("aria-invalid": "true") { "Invalid" }
              render Button.new("aria-expanded": "true") { "Expanded" }
              render Button.new("aria-expanded": "false") { "Collapsed" }
            end
          end

          # Complete Examples
          section do
            h2(class: "text-2xl font-bold mb-4") { "Real-world Examples" }

            # Form controls
            div(class: "bg-gray-50 dark:bg-gray-900 p-6 rounded-lg mb-4") do
              h3(class: "text-lg font-semibold mb-4") { "Form Actions" }
              div(class: "flex gap-3") do
                render Button.new(type: "submit", variant: :default) { "Save" }
                render Button.new(type: "reset", variant: :outline) { "Cancel" }
              end
            end

            # Destructive action
            div(class: "bg-gray-50 dark:bg-gray-900 p-6 rounded-lg") do
              h3(class: "text-lg font-semibold mb-4") { "Destructive Action" }
              render Button.new(variant: :destructive, data: { confirm: "This action cannot be undone" }) { "Delete Article" }
            end
          end
        end
      end
    end
  end
end
