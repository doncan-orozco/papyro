# frozen_string_literal: true

# Tooltip provider wrapper to mirror shadcn TooltipProvider API
module Components
  module Ui
    class TooltipProvider < Components::Base
      def initialize(**attrs)
        @attrs = attrs
      end

      def view_template(&block)
        div(class: merged_classes, **attrs_without_class) do
          yield self if block
        end
      end

      def tooltip(**attrs, &block)
        render Components::Ui::Tooltip.new(**attrs), &block
      end

      private

      def classes
        ""
      end
    end
  end
end
