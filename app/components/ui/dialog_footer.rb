# frozen_string_literal: true

# Dialog footer following shadcn/ui Radix patterns
module Components
  module Ui
    class DialogFooter < Components::Base
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
        "flex flex-col-reverse sm:flex-row sm:justify-end sm:space-x-2"
      end
    end
  end
end
