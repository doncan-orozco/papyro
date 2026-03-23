# frozen_string_literal: true

# Toast - message notification component
# Following shadcn/ui Radix patterns with semantic tokens
# Note: Requires Stimulus controller for display, animation, and auto-dismiss
module Components
  module Ui
    # Toast root container
    class Toast < Components::Base
      def initialize(variant: :default, **attrs)
        @variant = variant # :default or :destructive
        @attrs = attrs
      end

      def view_template(&block)
        div(
          role: :status,
          aria: { live: "polite", atomic: true },
          class: merged_classes,
          **attrs_without_class,
        ) do
          yield self if block
        end
      end

      def viewport(**attrs, &block)
        render Viewport.new(**attrs), &block
      end

      def title(**attrs, &block)
        render Title.new(**attrs), &block
      end

      def description(**attrs, &block)
        render Description.new(**attrs), &block
      end

      def action(**attrs, &block)
        render Action.new(**attrs), &block
      end

      def close(**attrs, &block)
        render Close.new(**attrs), &block
      end

      private

      def classes
        [
          base_classes,
          variant_classes[@variant]
        ].compact.join(" ")
      end

      def base_classes
        [
          "group pointer-events-auto relative flex w-full items-center justify-between space-x-4 overflow-hidden rounded-md border border-border p-6 pr-8 shadow-lg transition-all",
          "data-[swipe=cancel]:translate-x-0 data-[swipe=end]:translate-x-[var(--radix-toast-swipe-end-x)] data-[swipe=move]:translate-x-[var(--radix-toast-swipe-move-x)] data-[swipe=move]:transition-none",
          "data-[state=open]:animate-in data-[state=closed]:animate-out data-[swipe=end]:animate-out",
          "data-[state=closed]:fade-out-80 data-[state=closed]:slide-out-to-right-full data-[state=open]:slide-in-from-top-full data-[state=open]:sm:slide-in-from-bottom-full"
        ].join(" ")
      end

      def variant_classes
        {
          default: "border bg-background text-foreground",
          destructive: "destructive group border-destructive bg-destructive text-destructive-foreground"
        }
      end
    end

    # Toast Viewport - container for all toasts
    class Toast::Viewport < Components::Base
      def view_template(&block)
        ol(
          role: :region,
          aria: { label: "Notifications" },
          tabindex: -1,
          class: merged_classes,
          **attrs_without_class,
          &block
        )
      end

      private

      def classes
        [
          "fixed top-0 z-[100] flex max-h-screen w-full flex-col-reverse p-4 sm:bottom-0 sm:right-0 sm:top-auto sm:flex-col md:max-w-[420px]"
        ].join(" ")
      end
    end

    # Toast Title - title element
    class Toast::Title < Components::Base
      def view_template(&block)
        div(class: merged_classes, **attrs_without_class, &block)
      end

      private

      def classes
        "text-sm font-semibold"
      end
    end

    # Toast Description - description text
    class Toast::Description < Components::Base
      def view_template(&block)
        div(class: merged_classes, **attrs_without_class, &block)
      end

      private

      def classes
        "text-sm opacity-90"
      end
    end

    # Toast Action - action button
    class Toast::Action < Components::Base
      def initialize(**attrs)
        @attrs = attrs
      end

      def view_template(&block)
        render Components::Ui::Button.new(
          size: :sm,
          class: "shrink-0",
          **@attrs,
          &block
        )
      end
    end

    # Toast Close - close button
    class Toast::Close < Components::Base
      def view_template
        button(
          type: :button,
          class: merged_classes,
          **attrs_without_class
        ) do
          # X icon
          svg(
            class: "h-4 w-4",
            xmlns: "http://www.w3.org/2000/svg",
            width: 24,
            height: 24,
            viewBox: "0 0 24 24",
            fill: "none",
            stroke: "currentColor",
            stroke_width: 2,
            stroke_linecap: "round",
            stroke_linejoin: "round"
          ) do |s|
            s.path(d: "M18 6 6 18")
            s.path(d: "m6 6 12 12")
          end
          span(class: "sr-only") { "Close" }
        end
      end

      private

      def classes
        [
          "absolute right-2 top-2 rounded-md p-1 text-foreground/50 opacity-0 transition-opacity",
          "hover:text-foreground focus:opacity-100 focus:outline-none focus:ring-2 group-hover:opacity-100",
          "group-[.destructive]:text-destructive-foreground group-[.destructive]:hover:text-destructive-foreground group-[.destructive]:focus:ring-destructive group-[.destructive]:focus:ring-offset-destructive"
        ].join(" ")
      end
    end

    ToastViewport = Toast::Viewport
    ToastTitle = Toast::Title
    ToastDescription = Toast::Description
    ToastAction = Toast::Action
    ToastClose = Toast::Close

  end
end
