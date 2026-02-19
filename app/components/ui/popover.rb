# frozen_string_literal: true

# Popover - click-triggered popup component
# Following shadcn/ui Radix patterns with semantic tokens
# Note: Requires Stimulus controller for positioning and interactivity
module Components
  module Ui
    # Popover Trigger - button that triggers the popover
    class PopoverTrigger < Components::Base
      def view_template(&block)
        # Typically a button, but can be any interactive element
        button(
          type: :button,
          class: merged_classes,
          **attrs_without_class,
          &block
        )
      end

      private

      def classes
        ""
      end
    end

    # Popover Content - the popup content
    class PopoverContent < Components::Base
      def initialize(align: "center", side: "bottom", **attrs)
        @align = align
        @side = side
        @attrs = attrs
      end

      def view_template(&block)
        div(
          class: merged_classes,
          **attrs_without_class.merge(
            data: (attrs_without_class[:data] || {}).merge(
              align: @align,
              side: @side
            )
          ),
          &block
        )
      end

      private

      def classes
        [
          "z-50 w-72 rounded-md border border-border bg-popover p-4 text-popover-foreground shadow-md outline-none",
          "data-[state=open]:animate-in data-[state=closed]:animate-out",
          "data-[state=closed]:fade-out-0 data-[state=open]:fade-in-0",
          "data-[state=closed]:zoom-out-95 data-[state=open]:zoom-in-95",
          "data-[side=bottom]:slide-in-from-top-2 data-[side=left]:slide-in-from-right-2",
          "data-[side=right]:slide-in-from-left-2 data-[side=top]:slide-in-from-bottom-2"
        ].join(" ")
      end
    end
  end
end
