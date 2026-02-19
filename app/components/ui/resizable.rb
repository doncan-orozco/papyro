# frozen_string_literal: true

# Resizable - split panes with draggable dividers
# Following shadcn/ui Radix patterns with semantic tokens
# Note: Requires Stimulus controller for drag handling and resize logic
module Components
  module Ui
    # Resizable root container
    class Resizable < Components::Base
      def initialize(direction: :horizontal, **attrs)
        @direction = direction # :horizontal or :vertical
        @attrs = attrs
      end

      def view_template(&block)
        dynamic_attrs = attrs_without_class.dup

        # Add data attributes
        data_hash = dynamic_attrs[:data] || {}
        data_hash[:direction] = @direction unless data_hash.key?(:direction) || data_hash.key?("direction")
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
          "flex",
          "data-[direction=horizontal]:flex-row data-[direction=vertical]:flex-col",
          "h-full w-full"
        ].join(" ")
      end
    end

    # Resizable Panel - individual resizable panel
    class ResizablePanel < Components::Base
      def initialize(default_size: nil, min_size: nil, max_size: nil, **attrs)
        @default_size = default_size
        @min_size = min_size
        @max_size = max_size
        @attrs = attrs
      end

      def view_template(&block)
        dynamic_attrs = attrs_without_class.dup

        # Add data attributes for sizing
        data_hash = dynamic_attrs[:data] || {}
        data_hash[:default_size] = @default_size if @default_size
        data_hash[:min_size] = @min_size if @min_size
        data_hash[:max_size] = @max_size if @max_size
        dynamic_attrs[:data] = data_hash

        div(
          class: merged_classes,
          **dynamic_attrs,
          &block
        )
      end

      private

      def classes
        "flex-1 overflow-auto"
      end
    end

    # Resizable Handle - draggable divider between panels
    class ResizableHandle < Components::Base
      def view_template(&block)
        div(
          role: :separator,
          aria: { valuenow: 50 },
          tabindex: 0,
          class: merged_classes,
          **attrs_without_class
        ) do
          if block
            yield
          else
            # Default handle indicator
            div(class: "h-4 w-1 rounded-full bg-border")
          end
        end
      end

      private

      def classes
        [
          "relative flex items-center justify-center",
          "transition-colors",
          "focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2",
          # Horizontal handle
          "data-[direction=horizontal]:h-full data-[direction=horizontal]:w-px data-[direction=horizontal]:cursor-col-resize",
          "data-[direction=horizontal]:hover:bg-accent",
          # Vertical handle
          "data-[direction=vertical]:h-px data-[direction=vertical]:w-full data-[direction=vertical]:cursor-row-resize",
          "data-[direction=vertical]:hover:bg-accent"
        ].join(" ")
      end
    end
  end
end
