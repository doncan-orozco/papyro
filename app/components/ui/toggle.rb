# frozen_string_literal: true

# Toggle - binary state button component
# Following shadcn/ui Radix patterns with semantic tokens
# Note: Requires Stimulus controller for state management
module Components
  module Ui
    class Toggle < Components::Base
      def initialize(variant: :default, size: :default, pressed: false, **attrs)
        @variant = variant
        @size = size
        @pressed = pressed
        @attrs = attrs
      end

      def view_template(&block)
        dynamic_attrs = attrs_without_class.dup

        # Set aria-pressed for accessibility
        aria_hash = dynamic_attrs[:aria] || {}
        aria_hash[:pressed] = @pressed unless aria_hash.key?(:pressed) || aria_hash.key?("pressed")
        dynamic_attrs[:aria] = aria_hash

        # Set data-state for CSS styling
        unless dynamic_attrs.key?(:"data-state") || dynamic_attrs.key?("data-state")
          dynamic_attrs[:"data-state"] = @pressed ? "on" : "off"
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
          base_classes,
          variant_classes[@variant],
          size_classes[@size]
        ].compact.join(" ")
      end

      def base_classes
        [
          # Layout
          "inline-flex items-center justify-center",
          # Styling
          "rounded-md text-sm font-medium transition-colors",
          # Focus
          "focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2",
          # Disabled
          "disabled:pointer-events-none disabled:opacity-50",
          # States
          "data-[state=on]:bg-accent data-[state=on]:text-accent-foreground"
        ].join(" ")
      end

      def variant_classes
        {
          default: "bg-transparent hover:bg-muted hover:text-muted-foreground",
          outline: "border border-input bg-transparent hover:bg-accent hover:text-accent-foreground"
        }
      end

      def size_classes
        {
          default: "h-9 px-3",
          sm: "h-8 px-2",
          lg: "h-10 px-3"
        }
      end
    end
  end
end
