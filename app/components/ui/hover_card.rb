# frozen_string_literal: true

# Hover Card - rich hover preview component
# Following shadcn/ui Radix patterns with semantic tokens
# Note: Requires Stimulus controller for positioning and interactivity
module Components
  module Ui
    # Hover Card root container
    class HoverCard < Components::Base
      def initialize(**attrs)
        @attrs = attrs
      end

      def view_template(&block)
        div(class: merged_classes, **attrs_without_class, &block)
      end

      private

      def classes
        ""
      end
    end

    # Hover Card Trigger - element that triggers the hover card
    class HoverCardTrigger < Components::Base
      def initialize(**attrs)
        @attrs = attrs
      end

      def view_template(&block)
        span(class: merged_classes, **attrs_without_class, &block)
      end

      private

      def classes
        ""
      end
    end

    # Hover Card Content - the popup content
    class HoverCardContent < Components::Base
      def initialize(align: "center", side: "top", **attrs)
        @align = align
        @side = side
        @attrs = attrs
      end

      def view_template(&block)
        dynamic_attrs = attrs_without_class.dup
        data_hash = (dynamic_attrs[:data] || {}).dup

        unless data_hash.key?(:align) || data_hash.key?("align")
          data_hash[:align] = @align
        end

        unless data_hash.key?(:side) || data_hash.key?("side")
          data_hash[:side] = @side
        end

        dynamic_attrs[:data] = data_hash

        div(
          class: merged_classes,
          **dynamic_attrs,
          &block
        )
      end

      private

      def classes
        [
          "z-50 w-64 rounded-md border border-border bg-popover p-4 text-popover-foreground shadow-md outline-none",
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
