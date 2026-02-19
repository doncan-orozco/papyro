# frozen_string_literal: true

# Dropdown menu separator following shadcn/ui Radix patterns
module Components
  module Ui
    class DropdownMenuSeparator < Components::Base
      def initialize(**attrs)
        @attrs = attrs
      end

      def view_template
        div(
          role: :separator,
          class: merged_classes,
          **attrs_without_class
        )
      end

      private

      def classes
        "-mx-1 my-1 h-px bg-border"
      end
    end
  end
end
