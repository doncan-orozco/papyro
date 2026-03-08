# frozen_string_literal: true

# Checkbox component following shadcn/ui Radix patterns
# Uses semantic tokens for theming
# Updated: 2026-02-17 for pixel-perfect shadcn Radix UI compatibility
module Components
  module Ui
    class Checkbox < Components::Base
      def initialize(**attrs)
        @attrs = attrs
      end

      def view_template
        # wrap input so we can position a custom SVG checkmark
        span(class: "relative inline-flex items-center") do
          input(
            type: :checkbox,
            class: "#{merged_classes} appearance-none peer",
            **attrs_without_class
          )

          # white tick icon, shown only when peer (the input) is checked
          # use same check icon sizing as React (h-4 w-4) so it feels identical
          svg(
            xmlns: "http://www.w3.org/2000/svg",
            viewBox: "0 0 24 24",
            fill: "none",
            stroke: "currentColor",
            class: "pointer-events-none absolute inset-0 m-auto h-4 w-4 text-primary-foreground opacity-0 peer-checked:opacity-100"
          ) do |s|
            # lucide-react Check path (same as before) with stroke width 2
            s.path(d: "M5 13l4 4L19 7", stroke_width: 2, stroke_linecap: "round", stroke_linejoin: "round")
          end
        end
      end

      private

      def classes
        [
          # Size and shape
          "peer h-4 w-4 shrink-0 rounded-sm",
          # Border and background
          "border border-primary bg-transparent",
          # Ring on focus
          "ring-offset-background",
          "focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2",
          # Disabled state
          "disabled:cursor-not-allowed disabled:opacity-50",
          # Checked state styling: blue fill + white tick
          "checked:bg-primary checked:text-primary-foreground checked:border-primary",
          # ARIA states
          "aria-invalid:border-destructive aria-invalid:ring-destructive/20"
        ].join(" ")
      end
    end
  end
end
