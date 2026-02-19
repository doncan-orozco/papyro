# frozen_string_literal: true

# Collapsible - single expand/collapse region
# Following shadcn/ui Radix patterns with semantic tokens
# Note: Requires Stimulus controller for state management
module Components
  module Ui
    # Collapsible root container
    class Collapsible < Components::Base
      def initialize(open: false, **attrs)
        @open = open
        @attrs = attrs
      end

      def view_template(&block)
        dynamic_attrs = attrs_without_class.dup

        # Set data-state for CSS styling
        unless dynamic_attrs.key?(:"data-state") || dynamic_attrs.key?("data-state")
          dynamic_attrs[:"data-state"] = @open ? "open" : "closed"
        end

        div(
          class: merged_classes,
          **dynamic_attrs,
          &block
        )
      end

      private

      def classes
        ""
      end
    end

    # Collapsible Trigger - button to toggle collapse
    class CollapsibleTrigger < Components::Base
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
        ""
      end
    end

    # Collapsible Content - content that expands/collapses
    class CollapsibleContent < Components::Base
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
          "overflow-hidden",
          "transition-all",
          "data-[state=closed]:animate-collapse-up data-[state=open]:animate-collapse-down"
        ].join(" ")
      end
    end
  end
end
