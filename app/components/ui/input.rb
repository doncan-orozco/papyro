# frozen_string_literal: true

# Input component following shadcn/ui Radix patterns
# Uses semantic tokens for theming
# Updated: 2026-02-17 for pixel-perfect shadcn Radix UI compatibility
module Components
  module Ui
    class Input < Components::Base
      def initialize(type: :text, **attrs)
        @type = type
        @attrs = attrs
      end

      def view_template
        input(
          type: @type,
          class: merged_classes,
          **attrs_without_class
        )
      end

      private

      def classes
        [
          # Layout
          "flex h-9 w-full",
          # Styling
          "rounded-lg border border-input bg-background",
          "px-3 py-1 text-sm",
          # Shadows and transitions
          "shadow-sm transition-all",
          # Focus state
          "focus-visible:outline-none focus-visible:ring-3 focus-visible:ring-ring/20",
          # File input styling
          "file:border-0 file:bg-transparent file:text-sm file:font-medium file:text-foreground",
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
