# frozen_string_literal: true

# Dialog overlay following shadcn/ui Radix patterns
# Uses semantic tokens for theming
# Note: Requires Stimulus controller for full interactivity
module Components
  module Ui
    class DialogOverlay < Components::Base
      def initialize(**attrs)
        @attrs = attrs
      end

      def view_template
        div(
          class: merged_classes,
          **attrs_without_class
        )
      end

      private

      def classes
        [
          "fixed inset-0 z-50",
          "bg-black/80",
          "transition-opacity duration-200"
        ].join(" ")
      end
    end
  end
end
