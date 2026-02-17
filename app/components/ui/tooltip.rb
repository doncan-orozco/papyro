# frozen_string_literal: true

# Tooltip component following shadcn/ui Radix patterns
# Uses semantic tokens for theming
# Updated: 2026-02-17 for pixel-perfect shadcn Radix UI compatibility
# Note: Requires Stimulus controller or JavaScript library for full positioning
module Components
  module Ui
    # Tooltip trigger wrapper
    class TooltipTrigger < Components::Base
      def initialize(**attrs)
        @attrs = attrs
      end

      def view_template(&block)
        div(
          class: merged_classes,
          **attrs_without_class,
          &block
        )
      end

      private

      def classes
        "inline-block"
      end
    end

    # Tooltip content
    class TooltipContent < Components::Base
      def initialize(**attrs)
        @attrs = attrs
      end

      def view_template(&block)
        div(
          role: :tooltip,
          class: merged_classes,
          **attrs_without_class,
          &block
        )
      end

      private

      def classes
        [
          "z-50",
          "overflow-hidden",
          "rounded-lg border border-border bg-popover px-3 py-1.5",
          "text-sm text-popover-foreground shadow-md",
          "transition-all duration-200"
        ].join(" ")
      end
    end
  end
end
