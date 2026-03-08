# frozen_string_literal: true

# Dropdown menu content container following shadcn/ui Radix patterns
# Note: Requires Stimulus controller for full interactivity
module Components
  module Ui
    class DropdownMenuContent < Components::Base
      def initialize(**attrs)
        @attrs = attrs
      end

      def view_template(&block)
        div(
          role: :menu,
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
          "overflow-hidden",
          "rounded-lg border border-border bg-popover p-1",
          "text-popover-foreground shadow-md"
        ].join(" ")
      end
    end
  end
end
