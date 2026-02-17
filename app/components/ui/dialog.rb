# frozen_string_literal: true

# Dialog (Modal) component following shadcn/ui Radix patterns
# Uses semantic tokens for theming
# Updated: 2026-02-17 for pixel-perfect shadcn Radix UI compatibility
# Note: Requires Stimulus controller for full interactivity
module Components
  module Ui
    # Dialog overlay
    class DialogOverlay < Components::Base
      def initialize(**attrs)
        @attrs = attrs
      end

      def view_template
        div(
          class: merged_classes,
          **attrs_without_class
        )
      end

      private

      def classes
        [
          "fixed inset-0 z-50",
          "bg-black/80",
          "data-[state=open]:animate-in data-[state=closed]:animate-out",
          "data-[state=closed]:fade-out-0 data-[state=open]:fade-in-0"
        ].join(" ")
      end
    end

    # Dialog content container
    class DialogContent < Components::Base
      def initialize(**attrs)
        @attrs = attrs
      end

      def view_template(&block)
        div(
          role: :dialog,
          class: merged_classes,
          **attrs_without_class,
          &block
        )
      end

      private

      def classes
        [
          "fixed left-[50%] top-[50%] z-50",
          "grid w-full max-w-lg translate-x-[-50%] translate-y-[-50%] gap-4",
          "border border-border bg-background p-6 shadow-lg",
          "duration-200",
          "data-[state=open]:animate-in data-[state=closed]:animate-out",
          "data-[state=closed]:fade-out-0 data-[state=open]:fade-in-0",
          "data-[state=closed]:zoom-out-95 data-[state=open]:zoom-in-95",
          "data-[state=closed]:slide-out-to-left-1/2 data-[state=closed]:slide-out-to-top-[48%]",
          "data-[state=open]:slide-in-from-left-1/2 data-[state=open]:slide-in-from-top-[48%]",
          "sm:rounded-lg"
        ].join(" ")
      end
    end

    # Dialog header
    class DialogHeader < Components::Base
      def initialize(**attrs)
        @attrs = attrs
      end

      def view_template(&block)
        div(
          class: merged_classes,
          **attrs_without_class,
          &block
        )
      end

      private

      def classes
        "flex flex-col space-y-1.5 text-center sm:text-left"
      end
    end

    # Dialog footer
    class DialogFooter < Components::Base
      def initialize(**attrs)
        @attrs = attrs
      end

      def view_template(&block)
        div(
          class: merged_classes,
          **attrs_without_class,
          &block
        )
      end

      private

      def classes
        "flex flex-col-reverse sm:flex-row sm:justify-end sm:space-x-2"
      end
    end

    # Dialog title
    class DialogTitle < Components::Base
      def initialize(**attrs)
        @attrs = attrs
      end

      def view_template(&block)
        h2(
          class: merged_classes,
          **attrs_without_class,
          &block
        )
      end

      private

      def classes
        "text-lg font-semibold leading-none tracking-tight"
      end
    end

    # Dialog description
    class DialogDescription < Components::Base
      def initialize(**attrs)
        @attrs = attrs
      end

      def view_template(&block)
        p(
          class: merged_classes,
          **attrs_without_class,
          &block
        )
      end

      private

      def classes
        "text-sm text-muted-foreground"
      end
    end
  end
end
