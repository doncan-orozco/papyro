# frozen_string_literal: true

# Dropdown Menu component following shadcn/ui Radix patterns
# Uses semantic tokens for theming
# Updated: 2026-02-17 for pixel-perfect shadcn Radix UI compatibility
# Note: Requires Stimulus controller for full interactivity
module Components
  module Ui
    # Dropdown menu trigger button
    class DropdownMenuTrigger < Components::Base
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
          "inline-flex items-center justify-center",
          "rounded-lg px-3 py-2",
          "text-sm font-medium",
          "transition-colors",
          "hover:bg-muted",
          "focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2",
          "disabled:pointer-events-none disabled:opacity-50"
        ].join(" ")
      end
    end

    # Dropdown menu content container
    class DropdownMenuContent < Components::Base
      def initialize(**attrs)
        @attrs = attrs
      end

      def view_template(&block)
        div(
          role: :menu,
          class: merged_classes,
          **attrs_without_class,
          &block
        )
      end

      private

      def classes
        [
          "z-50 min-w-[8rem]",
          "overflow-hidden",
          "rounded-lg border border-border bg-popover p-1",
          "text-popover-foreground shadow-md",
          "data-[state=open]:animate-in data-[state=closed]:animate-out",
          "data-[state=closed]:fade-out-0 data-[state=open]:fade-in-0",
          "data-[state=closed]:zoom-out-95 data-[state=open]:zoom-in-95",
          "data-[side=bottom]:slide-in-from-top-2",
          "data-[side=left]:slide-in-from-right-2",
          "data-[side=right]:slide-in-from-left-2",
          "data-[side=top]:slide-in-from-bottom-2"
        ].join(" ")
      end
    end

    # Dropdown menu item
    class DropdownMenuItem < Components::Base
      def initialize(**attrs)
        @attrs = attrs
      end

      def view_template(&block)
        div(
          role: :menuitem,
          class: merged_classes,
          **attrs_without_class,
          &block
        )
      end

      private

      def classes
        [
          "relative flex cursor-pointer select-none items-center",
          "rounded-md px-2 py-1.5",
          "text-sm outline-none",
          "transition-colors",
          "focus:bg-accent focus:text-accent-foreground",
          "data-[disabled]:pointer-events-none data-[disabled]:opacity-50"
        ].join(" ")
      end
    end

    # Dropdown menu label
    class DropdownMenuLabel < Components::Base
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
        "px-2 py-1.5 text-sm font-semibold"
      end
    end

    # Dropdown menu separator
    class DropdownMenuSeparator < Components::Base
      def initialize(**attrs)
        @attrs = attrs
      end

      def view_template
        div(
          role: :separator,
          class: merged_classes,
          **attrs_without_class
        )
      end

      private

      def classes
        "-mx-1 my-1 h-px bg-border"
      end
    end
  end
end
