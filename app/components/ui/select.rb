# frozen_string_literal: true

# Select component following shadcn/ui Radix patterns
# Uses semantic tokens for theming
# Updated: 2026-02-17 for pixel-perfect shadcn Radix UI compatibility
module Components
  module Ui
    class Select < Components::Base
      def initialize(**attrs)
        @attrs = attrs
      end

      def view_template(&block)
        select(class: merged_classes, **attrs_without_class, &block)
      end

      private

      def classes
        [
          # Layout
          "flex h-9 w-full items-center justify-between",
          # Styling
          "rounded-lg border border-input bg-background",
          "px-3 py-1 text-sm",
          # Shadows and transitions
          "shadow-sm transition-all",
          # Focus state
          "focus-visible:outline-none focus-visible:ring-3 focus-visible:ring-ring/20",
          # Disabled state
          "disabled:cursor-not-allowed disabled:opacity-50",
          # ARIA states
          "aria-invalid:ring-3 aria-invalid:ring-destructive/20 dark:aria-invalid:ring-destructive/40",
          "aria-invalid:border-destructive dark:aria-invalid:border-destructive/50",
          # Chevron icon styling
          "[&>span]:line-clamp-1"
        ].join(" ")
      end
    end
  end
end
