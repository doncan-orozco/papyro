# frozen_string_literal: true

module Components
  module Ui
    class Select < Components::Base
      def initialize(disabled: false, **attrs)
        @disabled = disabled
        @attrs = attrs
      end

      def view_template(&block)
        select(
          class: classes,
          disabled: @disabled,
          **@attrs,
          &block
        )
      end

      private

      def classes
        "flex h-10 w-full items-center justify-between rounded-md border border-slate-200 bg-white px-3 py-2 text-sm ring-offset-white placeholder:text-slate-500 focus:outline-none focus:ring-2 focus:ring-slate-950 focus:ring-offset-2 disabled:cursor-not-allowed disabled:opacity-50"
      end
    end
  end
end
