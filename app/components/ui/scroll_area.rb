# frozen_string_literal: true

# Scroll Area - custom scrollbar styling component
# Following shadcn/ui Radix patterns with semantic tokens
module Components
  module Ui
    # Scroll Area root container
    class ScrollArea < Components::Base
      def initialize(orientation: :vertical, **attrs)
        @orientation = orientation
        @attrs = attrs
      end

      def view_template(&block)
        dynamic_attrs = attrs_without_class.dup
        data_hash = (dynamic_attrs[:data] || {}).dup

        unless data_hash.key?(:orientation) || data_hash.key?("orientation")
          data_hash[:orientation] = @orientation
        end

        dynamic_attrs[:data] = data_hash

        div(
          class: merged_classes,
          **dynamic_attrs
        ) do
          yield self if block
        end
      end

      def viewport(**attrs, &block)
        render Viewport.new(**attrs), &block
      end

      def scrollbar(**attrs, &block)
        render Scrollbar.new(**attrs), &block
      end

      def thumb(**attrs, &block)
        render Thumb.new(**attrs), &block
      end

      def corner(**attrs, &block)
        render Corner.new(**attrs), &block
      end

      private

      def classes
        "relative overflow-hidden"
      end

      def viewport_classes
        base = "h-full w-full rounded-[inherit] overflow-auto ui-scroll-area-viewport"

        case @orientation
        when :horizontal
          "#{base} overflow-x-auto overflow-y-hidden"
        when :vertical
          "#{base} overflow-y-auto"
        else
          base
        end
      end
    end

    # Scroll Area Viewport - scrollable content container
    class ScrollArea::Viewport < Components::Base
      def initialize(**attrs)
        @attrs = attrs
      end

      def view_template(&block)
        div(class: merged_classes, **attrs_without_class, &block)
      end

      private

      def classes
        "h-full w-full rounded-[inherit]"
      end
    end

    # Scroll Area Scrollbar - custom scrollbar
    class ScrollArea::Scrollbar < Components::Base
      def initialize(orientation: :vertical, **attrs)
        @orientation = orientation
        @attrs = attrs
      end

      def view_template(&block)
        dynamic_attrs = attrs_without_class.dup
        data_hash = (dynamic_attrs[:data] || {}).dup

        unless data_hash.key?(:orientation) || data_hash.key?("orientation")
          data_hash[:orientation] = @orientation
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
          "flex touch-none select-none transition-colors",
          # Vertical orientation
          "data-[orientation=vertical]:h-full data-[orientation=vertical]:w-2.5 data-[orientation=vertical]:border-l data-[orientation=vertical]:border-l-transparent data-[orientation=vertical]:p-[1px]",
          # Horizontal orientation
          "data-[orientation=horizontal]:h-2.5 data-[orientation=horizontal]:flex-col data-[orientation=horizontal]:border-t data-[orientation=horizontal]:border-t-transparent data-[orientation=horizontal]:p-[1px]"
        ].join(" ")
      end
    end

    # Scroll Area Thumb - draggable scrollbar thumb
    class ScrollArea::Thumb < Components::Base
      def initialize(**attrs)
        @attrs = attrs
      end

      def view_template
        div(class: merged_classes, **attrs_without_class)
      end

      private

      def classes
        "relative flex-1 rounded-full bg-border"
      end
    end

    # Scroll Area Corner - corner element when both scrollbars are present
    class ScrollArea::Corner < Components::Base
      def initialize(**attrs)
        @attrs = attrs
      end

      def view_template
        div(class: merged_classes, **attrs_without_class)
      end

      private

      def classes
        "bg-border"
      end
    end

    ScrollAreaViewport = ScrollArea::Viewport
    ScrollAreaScrollbar = ScrollArea::Scrollbar
    ScrollAreaThumb = ScrollArea::Thumb
    ScrollAreaCorner = ScrollArea::Corner

  end
end
