# frozen_string_literal: true

# Dropdown menu item following shadcn/ui Radix patterns
# Note: Requires Stimulus controller for full interactivity
module Components
  module Ui
    class DropdownMenuItem < Components::Base
      def initialize(href: nil, **attrs)
        @href = href
        @attrs = attrs
      end

      def view_template(&block)
        if @href
          a(
            href: @href,
            role: :menuitem,
            class: merged_classes,
            **attrs_without_class,
            &block
          )
        else
          button(
            type: :button,
            role: :menuitem,
            class: merged_classes,
            **attrs_without_class,
            &block
          )
        end
      end

      private

      def classes
        [
          "relative flex cursor-pointer select-none items-center w-full",
          "rounded-md px-2 py-1.5",
          "text-sm text-left outline-none",
          "transition-colors",
          "focus:bg-accent focus:text-accent-foreground",
          "hover:bg-accent hover:text-accent-foreground",
          "disabled:pointer-events-none disabled:opacity-50"
        ].join(" ")
      end
    end
  end
end
