# frozen_string_literal: true

# Label component following shadcn/ui Radix patterns
# Uses semantic tokens for theming
# Updated: 2026-02-17 for pixel-perfect shadcn Radix UI compatibility
module Components
  module Ui
    class Label < Components::Base
      def initialize(**attrs)
        @attrs = attrs
      end

      def view_template(&block)
        label(class: merged_classes, **attrs_without_class, &block)
      end

      private

      def classes
        [
          "text-sm font-medium leading-none",
          "peer-disabled:cursor-not-allowed peer-disabled:opacity-70"
        ].join(" ")
      end
    end
  end
end
