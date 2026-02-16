# frozen_string_literal: true

module Components
  module Ui
    class CardContent < Components::Base
      def initialize(**attrs)
        @attrs = attrs
      end

      def view_template(&block)
        div(class: classes, **@attrs, &block)
      end

      private

      def classes
        "p-6 pt-0"
      end
    end
  end
end
