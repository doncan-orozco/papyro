# frozen_string_literal: true

module Components
  module Ui
    class Card < Components::Base
      def initialize(**attrs)
        @attrs = attrs
      end

      def view_template(&block)
        div(class: classes, **@attrs, &block)
      end

      private

      def classes
        "rounded-lg border border-slate-200 bg-white text-slate-950 shadow-sm"
      end
    end
  end
end
