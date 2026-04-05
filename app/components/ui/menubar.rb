# frozen_string_literal: true

# Menubar - top-level navigation bar component
# Following shadcn/ui Radix patterns with semantic tokens
# Note: Requires Stimulus controller for keyboard navigation and state management
module Components
  module Ui
    # Menubar root container
    class Menubar < Components::Base
      def view_template(&block)
        div(
          role: :menubar,
          class: merged_classes,
          **attrs_without_class,
        ) do
          yield self if block
        end
      end

      def menu(**attrs, &block)
        render Menu.new(**attrs), &block
      end

      def trigger(**attrs, &block)
        render Trigger.new(**attrs), &block
      end

      def content(**attrs, &block)
        render Content.new(**attrs), &block
      end

      def item(**attrs, &block)
        render Item.new(**attrs), &block
      end

      def checkbox_item(**attrs, &block)
        render CheckboxItem.new(**attrs), &block
      end

      def radio_item(**attrs, &block)
        render RadioItem.new(**attrs), &block
      end

      def label(**attrs, &block)
        render Label.new(**attrs), &block
      end

      def separator(**attrs, &block)
        render Separator.new(**attrs), &block
      end

      def shortcut(**attrs, &block)
        render Shortcut.new(**attrs), &block
      end

      private

      def classes
        "flex h-10 items-center space-x-1 rounded-md border border-border bg-background p-1"
      end
    end

    # Menubar Menu - individual menu in the menubar
    class Menubar::Menu < Components::Base
      def view_template(&block)
        div(class: merged_classes, **attrs_without_class, &block)
      end

      private

      def classes
        ""
      end
    end

    # Menubar Trigger - button that triggers a menu
    class Menubar::Trigger < Components::Base
      def view_template(&block)
        button(
          type: :button,
          role: :menuitem,
          class: merged_classes,
          **attrs_without_class,
          &block
        )
      end

      private

      def classes
        [
          "flex cursor-default select-none items-center rounded-sm px-3 py-1.5 text-sm font-medium outline-none",
          "focus:bg-accent focus:text-accent-foreground",
          "data-[state=open]:bg-accent data-[state=open]:text-accent-foreground"
        ].join(" ")
      end
    end

    # Menubar Content - dropdown content
    class Menubar::Content < Components::Base
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
          "z-50 min-w-[12rem] overflow-hidden rounded-md border border-border bg-popover p-1 text-popover-foreground shadow-md",
          "data-[state=open]:animate-in data-[state=closed]:animate-out",
          "data-[state=closed]:fade-out-0 data-[state=open]:fade-in-0",
          "data-[state=closed]:zoom-out-95 data-[state=open]:zoom-in-95",
          "data-[side=bottom]:slide-in-from-top-2 data-[side=left]:slide-in-from-right-2",
          "data-[side=right]:slide-in-from-left-2 data-[side=top]:slide-in-from-bottom-2"
        ].join(" ")
      end
    end

    # Menubar Item - individual menu item
    class Menubar::Item < Components::Base
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

    # Menubar Checkbox Item - checkbox menu item
    class Menubar::CheckboxItem < Components::Base
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

    # Menubar Radio Item - radio menu item
    class Menubar::RadioItem < Components::Base
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

    # Menubar Label - non-interactive label
    class Menubar::Label < Components::Base
      def view_template(&block)
        div(class: merged_classes, **attrs_without_class, &block)
      end

      private

      def classes
        "px-2 py-1.5 text-sm font-semibold"
      end
    end

    # Menubar Separator - visual divider
    class Menubar::Separator < Components::Base
      def view_template
        div(class: merged_classes, **attrs_without_class)
      end

      private

      def classes
        "-mx-1 my-1 h-px bg-muted"
      end
    end

    # Menubar Shortcut - keyboard shortcut display
    class Menubar::Shortcut < Components::Base
      def view_template(&block)
        span(class: merged_classes, **attrs_without_class, &block)
      end

      private

      def classes
        "ml-auto text-xs tracking-widest text-muted-foreground"
      end
    end

    MenubarMenu = Menubar::Menu
    MenubarTrigger = Menubar::Trigger
    MenubarContent = Menubar::Content
    MenubarItem = Menubar::Item
    MenubarCheckboxItem = Menubar::CheckboxItem
    MenubarRadioItem = Menubar::RadioItem
    MenubarLabel = Menubar::Label
    MenubarSeparator = Menubar::Separator
    MenubarShortcut = Menubar::Shortcut
  end
end
