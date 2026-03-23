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
        ) do
          yield self if block
        end
      end

      def item(**attrs, &block)
        render Item.new(**attrs), &block
      end

      def trigger(**attrs, &block)
        render Trigger.new(**attrs), &block
      end

      def content(**attrs, &block)
        render Content.new(**attrs), &block
      end

      def content_inner(**attrs, &block)
        render ContentInner.new(**attrs), &block
      end

      private

      def classes
        "w-full"
      end
    end

    # Accordion item
    class Accordion::Item < Components::Base
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
    class Accordion::Trigger < Components::Base
      def initialize(expanded: nil, controls_id: nil, **attrs)
        @expanded = expanded
        @controls_id = controls_id
        @attrs = attrs
      end

      def view_template(&block)
        dynamic_attrs = attrs_without_class.dup

        # Determine expanded state: explicit prop wins, otherwise derive from data-state
        expanded =
          if !@expanded.nil?
            @expanded
          else
            state = dynamic_attrs[:"data-state"] || dynamic_attrs["data-state"]
            case state
            when "open" then true
            when "closed" then false
            else
              nil
            end
          end

        # Set aria-expanded unless consumer already provided it
        if !expanded.nil? && !dynamic_attrs.key?(:"aria-expanded") && !dynamic_attrs.key?("aria-expanded")
          aria_hash = dynamic_attrs[:aria] || {}
          aria_hash[:expanded] = expanded
          dynamic_attrs[:aria] = aria_hash
        end

        # Set aria-controls when an ID is provided and not already set
        if @controls_id && !dynamic_attrs.key?(:"aria-controls") && !dynamic_attrs.key?("aria-controls")
          aria_hash = dynamic_attrs[:aria] || {}
          aria_hash[:controls] = @controls_id
          dynamic_attrs[:aria] = aria_hash
        end

        button(
          type: :button,
          class: merged_classes,
          **dynamic_attrs,
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
    class Accordion::Content < Components::Base
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
          "transition-all duration-200"
        ].join(" ")
      end
    end

    # Accordion content inner wrapper (for padding)
    class Accordion::ContentInner < Components::Base
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

    AccordionItem = Accordion::Item
    AccordionTrigger = Accordion::Trigger
    AccordionContent = Accordion::Content
    AccordionContentInner = Accordion::ContentInner

  end
end
