# frozen_string_literal: true

# Accordion component following shadcn/ui Radix patterns
# Uses semantic tokens for theming
# Updated: 2026-02-17 for pixel-perfect shadcn Radix UI compatibility
# Note: Requires Stimulus controller for full interactivity
module Components
  module Ui
    # Accordion container
    class Accordion < Components::Base
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
        "w-full"
      end
    end

    # Accordion item
    class AccordionItem < Components::Base
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
        "border-b border-border"
      end
    end

    # Accordion trigger (header button)
    class AccordionTrigger < Components::Base
      def initialize(**attrs)
        @attrs = attrs
      end

      def view_template(&block)
        button(
          type: :button,
          class: merged_classes,
          **attrs_without_class,
          &block
        )
      end

      private

      def classes
        [
          "flex flex-1 items-center justify-between",
          "py-4 text-sm font-medium",
          "transition-all",
          "hover:underline",
          "[&[data-state=open]>svg]:rotate-180"
        ].join(" ")
      end
    end

    # Accordion content panel
    class AccordionContent < Components::Base
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
        [
          "overflow-hidden text-sm",
          "data-[state=closed]:animate-accordion-up",
          "data-[state=open]:animate-accordion-down"
        ].join(" ")
      end
    end

    # Accordion content inner wrapper (for padding)
    class AccordionContentInner < Components::Base
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
        "pb-4 pt-0"
      end
    end
  end
end
