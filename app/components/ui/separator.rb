# frozen_string_literal: true

module Components
  module Ui
    # Horizontal/vertical divider matching shadcn/ui React Separator
    # https://github.com/shadcn/ui/blob/main/components/separator.tsx
    # Supports orientation and decorative flag for accessibility.
    class Separator < Components::Base
      # @param orientation [Symbol,String] :horizontal or :vertical
      # @param decorative [Boolean] whether the separator is purely visual
      # @param attrs [Hash] additional HTML attributes
      def initialize(orientation: :horizontal, decorative: true, **attrs)
        @orientation = orientation.to_s
        @decorative = decorative
        @attrs = attrs
      end

      def view_template
        attrs = attrs_without_class.dup

        unless @decorative
          attrs[:role] = "separator"
          attrs["aria-orientation"] = "vertical" if @orientation == "vertical"
        end

        div(class: merged_classes, **attrs)
      end

      private

      def classes
        # avoid mutating a frozen literal by constructing a new string
        if @orientation == "horizontal"
          "shrink-0 bg-border h-[1px] w-full"
        else
          "shrink-0 bg-border h-full w-[1px]"
        end
      end
    end
  end
end
