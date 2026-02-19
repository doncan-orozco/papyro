# frozen_string_literal: true

# Badge component following shadcn/ui Radix patterns
# Uses semantic tokens for theming
# Updated: 2026-02-17 for pixel-perfect shadcn Radix UI compatibility
module Components
  module Ui
    class Badge < Components::Base
      def initialize(variant: :default, **attrs)
        @variant = variant
        @attrs = attrs
      end

      def view_template(&block)
        div(class: merged_classes, **attrs_without_class, &block)
      end

      private

      def classes
        [
          base_classes,
          variant_classes[@variant]
        ].compact.join(" ")
      end

      def base_classes
        [
          "inline-flex items-center",
          "rounded-md border",
          "px-2.5 py-0.5",
          "text-xs font-semibold",
          "transition-colors",
          "focus:outline-none focus:ring-2 focus:ring-ring focus:ring-offset-2"
        ].join(" ")
      end

      def variant_classes
        {
          default: "border-transparent bg-primary text-primary-foreground shadow hover:bg-primary/80",
          secondary: "border-transparent bg-secondary text-secondary-foreground hover:bg-secondary/80",
          destructive: "border-transparent bg-destructive text-destructive-foreground shadow hover:bg-destructive/80",
          outline: "text-foreground border-border"
        }
      end
    end
  end
end
