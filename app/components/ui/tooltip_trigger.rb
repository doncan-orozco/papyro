# frozen_string_literal: true

# Tooltip trigger wrapper following shadcn/ui Radix patterns
# Note: Requires Stimulus controller or JavaScript library for full positioning
module Components
  module Ui
    class TooltipTrigger < Components::Base
      def initialize(**attrs)
        @attrs = attrs
      end

      def view_template(&block)
        div(
          class: merged_classes,
          **attrs_without_class,
          &block
        )
      end

      private

      def classes
        "inline-block"
      end
    end
  end
end
