# frozen_string_literal: true

# Avatar component following shadcn/ui Radix patterns
# Uses semantic tokens for theming
# Updated: 2026-02-17 for pixel-perfect shadcn Radix UI compatibility
module Components
  module Ui
    # Avatar container
    class Avatar < Components::Base
      def initialize(**attrs)
        @attrs = attrs
      end

      def view_template(&block)
        span(
          class: merged_classes,
          **attrs_without_class,
        ) do
          yield self if block
        end
      end

      def image(**attrs, &block)
        render Image.new(**attrs), &block
      end

      def fallback(**attrs, &block)
        render Fallback.new(**attrs), &block
      end

      private

      def classes
        "relative flex h-10 w-10 shrink-0 overflow-hidden rounded-full"
      end
    end

    # Avatar image
    class Avatar::Image < Components::Base
      def initialize(src:, alt: "", **attrs)
        @src = src
        @alt = alt
        @attrs = attrs
      end

      def view_template
        img(
          src: @src,
          alt: @alt,
          class: merged_classes,
          **attrs_without_class
        )
      end

      private

      def classes
        "aspect-square h-full w-full"
      end
    end

    # Avatar fallback (shown when image fails to load)
    class Avatar::Fallback < Components::Base
      def initialize(**attrs)
        @attrs = attrs
      end

      def view_template(&block)
        span(
          class: merged_classes,
          **attrs_without_class,
          &block
        )
      end

      private

      def classes
        "flex h-full w-full items-center justify-center rounded-full bg-muted"
      end
    end

    AvatarImage = Avatar::Image
    AvatarFallback = Avatar::Fallback

  end
end
