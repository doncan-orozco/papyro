# frozen_string_literal: true

module Components
  module Ui
    # Sheet Header - header section
    class SheetHeader < Components::Base
      def initialize(**attrs)
        @attrs = attrs
      end

      def view_template(&block)
        div(class: merged_classes, **attrs_without_class, &block)
      end

      private

      def classes
        "flex flex-col space-y-2 text-center sm:text-left"
      end
    end
  end
end
