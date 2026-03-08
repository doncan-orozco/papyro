# frozen_string_literal: true

# Select trigger button following shadcn/ui Radix patterns
# Note: Requires Stimulus controller for full interactivity
module Components
  module Ui
    class SelectTrigger < Components::Base
      def initialize(placeholder: nil, **attrs)
        @placeholder = placeholder
        @attrs = attrs
      end

      def view_template(&block)
        button(
          type: "button",
          role: "combobox",
          aria_expanded: "false",
          aria_haspopup: "listbox",
          class: merged_classes,
          **attrs_without_class,
          &block
        )
      end

      private

      def classes
        [
          # Layout
          "flex h-9 w-full items-center justify-between whitespace-nowrap",
          # Styling
          "rounded-md border border-input bg-transparent",
          "px-3 py-2 text-sm shadow-sm",
          # Focus ring
          "ring-offset-background",
          "focus:outline-none focus:ring-1 focus:ring-ring",
          # Disabled state
          "disabled:cursor-not-allowed disabled:opacity-50",
          # Placeholder
          "[&>span]:line-clamp-1"
        ].join(" ")
      end
    end
  end
end
