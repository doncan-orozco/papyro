# frozen_string_literal: true

# Dropdown menu content container following shadcn/ui Radix patterns
# Note: Requires Stimulus controller for full interactivity
module Components
  module Ui
    class DropdownMenuContent < Components::Base
      def initialize(align: :start, **attrs)
        @align = align
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
          "text-popover-foreground shadow-md",
          alignment_classes
        ].join(" ")
      end

      def alignment_classes
        case @align
        when :end
          nil
        else
          nil
        end
      end
    end
  end
end
