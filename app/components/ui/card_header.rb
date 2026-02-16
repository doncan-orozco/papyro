# frozen_string_literal: true

module Components
  module Ui
    class CardHeader < Components::Base
      def initialize(**attrs)
        @attrs = attrs
      end

      def view_template(&block)
        div(class: classes, **@attrs, &block)
      end

      private

      def classes
        "flex flex-col space-y-1.5 p-6"
      end
    end
  end
end
