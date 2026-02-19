# frozen_string_literal: true

# Aspect Ratio - maintains consistent aspect ratio for media content
# Following shadcn/ui Radix patterns
module Components
  module Ui
    class AspectRatio < Components::Base
      def initialize(ratio: "16/9", **attrs)
        @ratio = ratio
        @attrs = attrs
      end

      def view_template(&block)
        div(class: "relative w-full", style: "padding-bottom: calc(100% / (#{@ratio}))") do
          div(class: merged_classes, **attrs_without_class, &block)
        end
      end

      private

      def classes
        "absolute inset-0"
      end
    end
  end
end
