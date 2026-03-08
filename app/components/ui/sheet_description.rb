# frozen_string_literal: true

module Components
  module Ui
    # Sheet Description - description text
    class SheetDescription < Components::Base
      def initialize(**attrs)
        @attrs = attrs
      end

      def view_template(&block)
        p(class: merged_classes, **attrs_without_class, &block)
      end

      private

      def classes
        "text-sm text-muted-foreground"
      end
    end
  end
end
