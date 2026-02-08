module Components
  module Ui
    class Button < Components::Base
      def initialize(variant: :default, size: :default, **attrs)
        @variant = variant
        @size = size
        @attrs = attrs
      end

      def view_template(&block)
        button(class: classes, **@attrs, &block)
      end

      private

      def classes
        [
          base_classes,
          variant_classes[@variant],
          size_classes[@size]
        ].compact.join(" ")
      end

      def base_classes
        "inline-flex items-center justify-center rounded-md font-medium transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-offset-2 disabled:pointer-events-none disabled:opacity-50"
      end

      def variant_classes
        {
          default: "bg-slate-900 text-slate-50 hover:bg-slate-900/90",
          destructive: "bg-red-500 text-slate-50 hover:bg-red-500/90",
          outline: "border border-slate-200 bg-white hover:bg-slate-100 hover:text-slate-900",
          secondary: "bg-slate-100 text-slate-900 hover:bg-slate-100/80",
          ghost: "hover:bg-slate-100 hover:text-slate-900",
          link: "text-slate-900 underline-offset-4 hover:underline"
        }
      end

      def size_classes
        {
          default: "h-10 px-4 py-2 text-sm",
          sm: "h-9 rounded-md px-3 text-sm",
          lg: "h-12 rounded-md px-8 text-lg",
          icon: "h-10 w-10"
        }
      end
    end
  end
end
