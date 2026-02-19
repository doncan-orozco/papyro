# frozen_string_literal: true

# Dialog title following shadcn/ui Radix patterns
module Components
  module Ui
    class DialogTitle < Components::Base
      def initialize(**attrs)
        @attrs = attrs
      end

      def view_template(&block)
        h2(
          class: merged_classes,
          **attrs_without_class,
          &block
        )
      end

      private

      def classes
        "text-lg font-semibold leading-none tracking-tight"
      end
    end
  end
end
