# frozen_string_literal: true

module Components
  module Ui
    class Textarea < Components::Base
      def initialize(disabled: false, **attrs)
        @disabled = disabled
        @attrs = attrs
      end

      def view_template(&block)
        textarea(
          class: classes,
          disabled: @disabled,
          **@attrs,
          &block
        )
      end

      private

      def classes
        "flex min-h-[80px] w-full rounded-md border border-slate-200 bg-white px-3 py-2 text-sm ring-offset-white placeholder:text-slate-500 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-slate-950 focus-visible:ring-offset-2 disabled:cursor-not-allowed disabled:opacity-50"
      end
    end
  end
end
