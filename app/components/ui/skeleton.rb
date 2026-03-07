# frozen_string_literal: true

# Skeleton component following shadcn/ui Radix patterns
# Uses semantic tokens for theming
# Updated: 2026-02-17 for pixel-perfect shadcn Radix UI compatibility
module Components
  module Ui
    class Skeleton < Components::Base
      def initialize(**attrs)
        @attrs = attrs
      end

      def view_template
        div(
          class: merged_classes,
          **attrs_without_class
        )
      end

      private

      def classes
        "animate-pulse rounded-md bg-primary/10"
      end
    end
  end
end
