# frozen_string_literal: true

# Progress component following shadcn/ui Radix patterns
# Uses semantic tokens for theming
# Updated: 2026-02-17 for pixel-perfect shadcn Radix UI compatibility
module Components
  module Ui
    # Progress container
    class Progress < Components::Base
      def initialize(value: 0, max: 100, **attrs)
        @value = value
        @max = max
        @attrs = attrs
      end

      def view_template
        div(
          role: :progressbar,
          aria: { valuemin: 0, valuemax: @max, valuenow: @value },
          class: merged_classes,
          **attrs_without_class
        ) do
          render ProgressIndicator.new(value: @value, max: @max)
        end
      end

      private

      def classes
        "relative h-2 w-full overflow-hidden rounded-full bg-primary/20"
      end
    end

    # Progress indicator (the filled part)
    class ProgressIndicator < Components::Base
      def initialize(value: 0, max: 100, **attrs)
        @value = value
        @max = max
        @attrs = attrs
      end

      def view_template
        div(
          class: merged_classes,
          style: "transform: translateX(-#{100 - percentage}%)",
          **attrs_without_class
        )
      end

      private

      def classes
        "h-full w-full flex-1 bg-primary transition-all"
      end

      def percentage
        return 0 if @max.zero?

        [(@value.to_f / @max * 100).round(2), 100].min
      end
    end
  end
end
