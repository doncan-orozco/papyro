# frozen_string_literal: true

# Radio component following shadcn/ui Radix patterns
# Uses semantic tokens for theming
# Updated: 2026-02-17 for pixel-perfect shadcn Radix UI compatibility
module Components
  module Ui
    class Radio < Components::Base
      def initialize(**attrs)
        @attrs = attrs
      end

      def view_template
        input(
          type: :radio,
          class: merged_classes,
          **attrs_without_class
        )
      end

      private

      def classes
        [
          # Size and shape
          "peer h-4 w-4 shrink-0 rounded-full",
          # Border and background
          "border border-primary bg-background",
          # Ring on focus
          "ring-offset-background",
          "focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2",
          # Disabled state
          "disabled:cursor-not-allowed disabled:opacity-50",
          # Checked state styling
          "checked:bg-primary checked:text-primary-foreground checked:border-primary",
          # ARIA states
          "aria-invalid:border-destructive aria-invalid:ring-destructive/20"
        ].join(" ")
      end
    end
  end
end
