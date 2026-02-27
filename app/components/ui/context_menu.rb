# frozen_string_literal: true

# Context Menu - right-click menu component
# Following shadcn/ui Radix patterns with semantic tokens
# Similar to Dropdown Menu but triggered by right-click
# Note: Requires Stimulus controller for positioning and interactivity
module Components
  module Ui
    # Context Menu root class (required for Zeitwerk autoloading)
    class ContextMenu < Components::Base
      # This class can be used as a namespace or entrypoint for the context menu component system.
    end

    # Context Menu Trigger - element that triggers the context menu on right-click
    class ContextMenuTrigger < Components::Base
      def view_template(&block)
        div(class: merged_classes, **attrs_without_class, &block)
      end

      private

      def classes
        ""
      end
    end

    # Context Menu Content - the popup menu
    class ContextMenuContent < Components::Base
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
          "z-50 min-w-[8rem] overflow-hidden rounded-md border border-border bg-popover p-1 text-popover-foreground shadow-md",
          "data-[state=open]:animate-in data-[state=closed]:animate-out",
          "data-[state=closed]:fade-out-0 data-[state=open]:fade-in-0",
          "data-[state=closed]:zoom-out-95 data-[state=open]:zoom-in-95",
          "data-[side=bottom]:slide-in-from-top-2 data-[side=left]:slide-in-from-right-2",
          "data-[side=right]:slide-in-from-left-2 data-[side=top]:slide-in-from-bottom-2"
        ].join(" ")
      end
    end

    # Context Menu Item - individual menu item
    class ContextMenuItem < Components::Base
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
          "relative flex cursor-default select-none items-center rounded-sm px-2 py-1.5 text-sm outline-none",
          "transition-colors",
          "focus:bg-accent focus:text-accent-foreground",
          "data-[disabled]:pointer-events-none data-[disabled]:opacity-50"
        ].join(" ")
      end
    end

    # Context Menu Checkbox Item - checkbox menu item
    class ContextMenuCheckboxItem < Components::Base
      def view_template(&block)
        div(
          role: :menuitemcheckbox,
          class: merged_classes,
          **attrs_without_class,
          &block
        )
      end

      private

      def classes
        [
          "relative flex cursor-default select-none items-center rounded-sm py-1.5 pl-8 pr-2 text-sm outline-none",
          "transition-colors",
          "focus:bg-accent focus:text-accent-foreground",
          "data-[disabled]:pointer-events-none data-[disabled]:opacity-50"
        ].join(" ")
      end
    end

    # Context Menu Radio Item - radio menu item
    class ContextMenuRadioItem < Components::Base
      def view_template(&block)
        div(
          role: :menuitemradio,
          class: merged_classes,
          **attrs_without_class,
          &block
        )
      end

      private

      def classes
        [
          "relative flex cursor-default select-none items-center rounded-sm py-1.5 pl-8 pr-2 text-sm outline-none",
          "transition-colors",
          "focus:bg-accent focus:text-accent-foreground",
          "data-[disabled]:pointer-events-none data-[disabled]:opacity-50"
        ].join(" ")
      end
    end

    # Context Menu Label - non-interactive label
    class ContextMenuLabel < Components::Base
      def view_template(&block)
        div(class: merged_classes, **attrs_without_class, &block)
      end

      private

      def classes
        "px-2 py-1.5 text-sm font-semibold"
      end
    end

    # Context Menu Separator - visual divider
    class ContextMenuSeparator < Components::Base
      def view_template
        div(class: merged_classes, **attrs_without_class)
      end

      private

      def classes
        "-mx-1 my-1 h-px bg-muted"
      end
    end

    # Context Menu Shortcut - keyboard shortcut display
    class ContextMenuShortcut < Components::Base
      def view_template(&block)
        span(class: merged_classes, **attrs_without_class, &block)
      end

      private

      def classes
        "ml-auto text-xs tracking-widest opacity-60"
      end
    end
  end
end
