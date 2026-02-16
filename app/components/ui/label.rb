# frozen_string_literal: true

module Components
  module Ui
    class Label < Components::Base
      def initialize(for_id: nil, **attrs)
        @for_id = for_id
        @attrs = attrs
      end

      def view_template(&block)
        label(for: @for_id, class: classes, **@attrs, &block)
      end

      private

      def classes
        "text-sm font-medium leading-none peer-disabled:cursor-not-allowed peer-disabled:opacity-70"
      end
    end
  end
end
