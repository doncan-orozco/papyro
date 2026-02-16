# frozen_string_literal: true

module Components
  module Ui
    class Badge < Components::Base
      def initialize(variant: :default, **attrs)
        @variant = variant
        @attrs = attrs
      end

      def view_template(&block)
        div(
          class: classes,
          **@attrs,
          &block
        )
      end

      private

      def classes
        [ base_classes, variant_classes[@variant] ].compact.join(" ")
      end

      def base_classes
        "inline-flex items-center rounded-full border px-2.5 py-0.5 text-xs font-semibold transition-colors focus:outline-none focus:ring-2 focus:ring-slate-950 focus:ring-offset-2"
      end

      def variant_classes
        {
          default: "border-transparent bg-slate-900 text-slate-50 hover:bg-slate-900/80",
          secondary: "border-transparent bg-slate-100 text-slate-900 hover:bg-slate-100/80",
          destructive: "border-transparent bg-red-500 text-slate-50 hover:bg-red-500/80",
          outline: "text-slate-950"
        }
      end
    end
  end
end
