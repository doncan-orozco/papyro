# frozen_string_literal: true

# Dropdown menu trigger following shadcn/ui Radix patterns
# Note: Requires Stimulus controller for full interactivity
module Components
  module Ui
    class DropdownMenuTrigger < Components::Base
      def initialize(**attrs)
        @attrs = attrs
      end

      def view_template(&block)
        button(
          type: :button,
          class: merged_classes,
          **attrs_without_class,
          &block
        )
      end

      private

      def classes
        [
          "inline-flex items-center justify-center",
          "rounded-lg px-3 py-2",
          "text-sm font-medium",
          "transition-colors",
          "hover:bg-muted",
          "focus-visible:outline-none focus-visible:ring-3 focus-visible:ring-ring/20",
          "disabled:pointer-events-none disabled:opacity-50"
        ].join(" ")
      end
    end
  end
end
