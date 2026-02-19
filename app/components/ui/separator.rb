# frozen_string_literal: true

# Separator component following shadcn/ui Radix patterns
# Uses semantic tokens for theming
# Updated: 2026-02-17 for pixel-perfect shadcn Radix UI compatibility
module Components
  module Ui
    class Separator < Components::Base
      def initialize(orientation: :horizontal, decorative: true, **attrs)
        @orientation = orientation
        @decorative = decorative
        @attrs = attrs
      end

      def view_template
        dynamic_attrs = attrs_without_class.dup

        # Set ARIA attributes based on decorative flag
        if @decorative
          aria_hash = dynamic_attrs[:aria] || {}
          aria_hash[:hidden] = true unless aria_hash.key?(:hidden) || aria_hash.key?("hidden")
          dynamic_attrs[:aria] = aria_hash
        else
          aria_hash = dynamic_attrs[:aria] || {}
          aria_hash[:orientation] = @orientation unless aria_hash.key?(:orientation) || aria_hash.key?("orientation")
          dynamic_attrs[:aria] = aria_hash
        end

        div(
          role: @decorative ? :none : :separator,
          data: { orientation: @orientation },
          class: merged_classes,
          **dynamic_attrs
        )
      end

      private

      def classes
        [
          "shrink-0 bg-border",
          orientation_classes[@orientation]
        ].compact.join(" ")
      end

      def orientation_classes
        {
          horizontal: "h-[1px] w-full",
          vertical: "h-full w-[1px]"
        }
      end
    end
  end
end
