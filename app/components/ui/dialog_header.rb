# frozen_string_literal: true

# Dialog header following shadcn/ui Radix patterns
module Components
  module Ui
    class DialogHeader < Components::Base
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
        "flex flex-col space-y-1.5 text-center sm:text-left"
      end
    end
  end
end
