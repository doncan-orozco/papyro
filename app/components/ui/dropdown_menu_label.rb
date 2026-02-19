# frozen_string_literal: true

# Dropdown menu label following shadcn/ui Radix patterns
module Components
  module Ui
    class DropdownMenuLabel < Components::Base
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
        "px-2 py-1.5 text-sm font-semibold"
      end
    end
  end
end
