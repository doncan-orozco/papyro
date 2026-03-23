# frozen_string_literal: true

# Carousel - image/content slider component
# Following shadcn/ui Radix patterns with semantic tokens
# Note: Requires Stimulus controller for slide transitions and navigation
module Components
  module Ui
    # Carousel root container
    class Carousel < Components::Base
      def initialize(orientation: :horizontal, **attrs)
        @orientation = orientation # :horizontal or :vertical
        @attrs = attrs
      end

      def view_template(&block)
        dynamic_attrs = attrs_without_class.dup

        # Add data attributes
        data_hash = (dynamic_attrs[:data] || {}).dup
        data_hash[:orientation] = @orientation unless data_hash.key?(:orientation) || data_hash.key?("orientation")
        dynamic_attrs[:data] = data_hash

        div(
          role: :region,
          aria: { roledescription: "carousel" },
          class: merged_classes,
          **dynamic_attrs,
        ) do
          yield self if block
        end
      end

      def content(**attrs, &block)
        render Content.new(**attrs), &block
      end

      def item(**attrs, &block)
        render Item.new(**attrs), &block
      end

      def previous(**attrs, &block)
        render Previous.new(**attrs), &block
      end

      def next(**attrs, &block)
        render Next.new(**attrs), &block
      end

      private

      def classes
        "relative w-full"
      end
    end

    # Carousel Content - slides container
    class Carousel::Content < Components::Base
      def view_template(&block)
        div(class: merged_classes, **attrs_without_class, &block)
      end

      private

      def classes
        "flex overflow-hidden"
      end
    end

    # Carousel Item - individual slide
    class Carousel::Item < Components::Base
      def view_template(&block)
        div(
          role: :group,
          aria: { roledescription: "slide" },
          class: merged_classes,
          **attrs_without_class,
          &block
        )
      end

      private

      def classes
        "min-w-0 shrink-0 grow-0 basis-full"
      end
    end

    # Carousel Previous - previous slide button
    class Carousel::Previous < Components::Base
      def view_template(&block)
        render Components::Ui::Button.new(
          variant: :outline,
          size: :icon,
          class: "absolute h-8 w-8 rounded-full",
          **attrs_without_class
        ) do
          if block
            yield
          else
            # Chevron left icon
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
              s.path(d: "m15 18-6-6 6-6")
            end
            span(class: "sr-only") { "Previous slide" }
          end
        end
      end
    end

    # Carousel Next - next slide button
    class Carousel::Next < Components::Base
      def view_template(&block)
        render Components::Ui::Button.new(
          variant: :outline,
          size: :icon,
          class: "absolute h-8 w-8 rounded-full",
          **attrs_without_class
        ) do
          if block
            yield
          else
            # Chevron right icon
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
              s.path(d: "m9 18 6-6-6-6")
            end
            span(class: "sr-only") { "Next slide" }
          end
        end
      end
    end

    CarouselContent = Carousel::Content
    CarouselItem = Carousel::Item
    CarouselPrevious = Carousel::Previous
    CarouselNext = Carousel::Next

  end
end
