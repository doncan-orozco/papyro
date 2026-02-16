# frozen_string_literal: true

module Components
  module Ui
    class Label < Components::Base
      def initialize(**attrs)
        @attrs = attrs
      end

      def view_template(&block)
        label(
          class: "text-sm font-medium leading-none peer-disabled:cursor-not-allowed peer-disabled:opacity-70",
          **@attrs,
          &block
        )
      end
    end
  end
end
