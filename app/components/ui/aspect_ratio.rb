# frozen_string_literal: true

# Aspect Ratio - maintains consistent aspect ratio for media content
# Following shadcn/ui Radix patterns
module Components
  module Ui
    class AspectRatio < Components::Base
      def initialize(ratio: "16/9", **attrs)
        @ratio = sanitize_ratio(ratio)
        @attrs = attrs
      end

      def view_template(&block)
        div(class: "relative w-full", style: "padding-bottom: calc(100% / (#{@ratio}))") do
          div(class: merged_classes, **attrs_without_class, &block)
        end
      end

      private

      # Sanitize ratio to prevent XSS
      def sanitize_ratio(ratio)
        # Only allow numbers, forward slash, decimal point, and colon
        return "16/9" unless ratio.to_s.match?(/\A[\d.\/: ]+\z/)
        ratio
      end

      def classes
        "absolute inset-0"
      end
    end
  end
end
