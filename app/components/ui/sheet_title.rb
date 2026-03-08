# frozen_string_literal: true

module Components
  module Ui
    # Sheet Title - title element
    class SheetTitle < Components::Base
      def initialize(**attrs)
        @attrs = attrs
      end

      def view_template(&block)
        h2(class: merged_classes, **attrs_without_class, &block)
      end

      private

      def classes
        "text-lg font-semibold text-foreground"
      end
    end
  end
end
