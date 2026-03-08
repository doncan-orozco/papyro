# frozen_string_literal: true

# Select content container following shadcn/ui Radix patterns
# Note: Requires Stimulus controller for full interactivity
module Components
  module Ui
    class SelectContent < Components::Base
      def initialize(**attrs)
        @attrs = attrs
      end

      def view_template(&block)
        div(
          role: :listbox,
          class: merged_classes,
          **attrs_without_class,
          &block
        )
      end

      private

      def classes
        [
          "!fixed",
          "z-50 min-w-[8rem]",
          "max-h-96 overflow-y-auto overflow-x-hidden",
          "rounded-md border border-border bg-popover p-1",
          "text-popover-foreground shadow-md"
        ].join(" ")
      end
    end
  end
end
