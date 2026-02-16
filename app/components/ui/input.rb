# frozen_string_literal: true

module Components
  module Ui
    class Input < Components::Base
      def initialize(type: "text", disabled: false, **attrs)
        @type = type
        @disabled = disabled
        @attrs = attrs
      end

      def view_template
        input(
          type: @type,
          class: classes,
          disabled: @disabled,
          **@attrs
        )
      end

      private

      def classes
        "flex h-10 w-full rounded-md border border-slate-200 bg-white px-3 py-2 text-sm ring-offset-white file:border-0 file:bg-transparent file:text-sm file:font-medium placeholder:text-slate-500 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-slate-950 focus-visible:ring-offset-2 disabled:cursor-not-allowed disabled:opacity-50"
      end
    end
  end
end
