# frozen_string_literal: true

# Textarea component following shadcn/ui Radix patterns
# Uses semantic tokens for theming
# Updated: 2026-02-17 for pixel-perfect shadcn Radix UI compatibility
module Components
  module Ui
    class Textarea < Components::Base
      def initialize(**attrs)
        @attrs = attrs
      end

      def view_template(&block)
        textarea(class: merged_classes, **attrs_without_class, &block)
      end

      private

      def classes
        [
          # Layout
          "flex min-h-[60px] w-full",
          # Styling
          "rounded-lg border border-input bg-background",
          "px-3 py-2 text-sm",
          # Shadows and transitions
          "shadow-sm transition-all",
          # Focus state
          "focus-visible:outline-none focus-visible:ring-3 focus-visible:ring-ring/20",
          # Placeholder
          "placeholder:text-muted-foreground",
          # Disabled state
          "disabled:cursor-not-allowed disabled:opacity-50",
          # ARIA states
          "aria-invalid:ring-3 aria-invalid:ring-destructive/20 dark:aria-invalid:ring-destructive/40",
          "aria-invalid:border-destructive dark:aria-invalid:border-destructive/50"
        ].join(" ")
      end
    end
  end
end
