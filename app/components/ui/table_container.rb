# frozen_string_literal: true

# Table container wrapper following shadcn/ui Radix patterns
# Uses semantic tokens for theming
module Components
  module Ui
    class TableContainer < Components::Base
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
        "relative w-full overflow-auto"
      end
    end
  end
end
