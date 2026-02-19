# frozen_string_literal: true

# Switch component following shadcn/ui Radix patterns
# Uses semantic tokens for theming
# Updated: 2026-02-17 for pixel-perfect shadcn Radix UI compatibility
# Note: This is a basic implementation. For full functionality, consider using Stimulus controller
module Components
  module Ui
    # Switch root element (button)
    class Switch < Components::Base
      def initialize(checked: nil, **attrs)
        @checked = checked
        @attrs = attrs
      end

      def view_template(&block)
        dynamic_attrs = attrs_without_class.dup

        # Determine checked state from explicit prop or data-state
        checked =
          if !@checked.nil?
            @checked
          else
            state = dynamic_attrs[:"data-state"] || dynamic_attrs["data-state"]
            case state
            when "checked" then true
            when "unchecked" then false
            else
              nil
            end
          end

        # Set aria-checked unless consumer already provided it
        if !checked.nil?
          aria_hash = dynamic_attrs[:aria] || {}
          aria_hash[:checked] = checked unless aria_hash.key?(:checked) || aria_hash.key?("checked")
          dynamic_attrs[:aria] = aria_hash
        end

        # Keep visual state (data-state) in sync with ARIA state unless overridden
        if !checked.nil? && !dynamic_attrs.key?(:"data-state") && !dynamic_attrs.key?("data-state")
          dynamic_attrs[:"data-state"] = checked ? "checked" : "unchecked"
        end

        button(
          type: :button,
          role: :switch,
          class: merged_classes,
          **dynamic_attrs,
          &block
        )
      end

      private

      def classes
        [
          # Peer for label styling
          "peer",
          # Layout
          "inline-flex h-5 w-9 shrink-0 cursor-pointer items-center",
          # Styling
          "rounded-full border-2 border-transparent shadow-sm",
          "transition-colors",
          # Focus states
          "focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 focus-visible:ring-offset-background",
          # Disabled state
          "disabled:cursor-not-allowed disabled:opacity-50",
          # States (use with data-state attribute)
          "data-[state=checked]:bg-primary data-[state=unchecked]:bg-input"
        ].join(" ")
      end
    end

    # Switch thumb (the moving circle)
    class SwitchThumb < Components::Base
      def initialize(**attrs)
        @attrs = attrs
      end

      def view_template
        span(class: merged_classes, **attrs_without_class)
      end

      private

      def classes
        [
          # Size and shape
          "pointer-events-none block h-4 w-4 rounded-full",
          # Styling
          "bg-background shadow-lg ring-0",
          # Transition
          "transition-transform",
          # States (use with data-state attribute)
          "data-[state=checked]:translate-x-4 data-[state=unchecked]:translate-x-0"
        ].join(" ")
      end
    end
  end
end
