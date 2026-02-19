# frozen_string_literal: true

# Navigation Menu - multi-level navigation component
# Following shadcn/ui Radix patterns with semantic tokens
# Note: Requires Stimulus controller for hover/focus states and keyboard navigation
module Components
  module Ui
    # Navigation Menu root container
    class NavigationMenu < Components::Base
      def view_template(&block)
        nav(
          role: :navigation,
          class: merged_classes,
          **attrs_without_class,
          &block
        )
      end

      private

      def classes
        "relative z-10 flex max-w-max flex-1 items-center justify-center"
      end
    end

    # Navigation Menu List - list of menu items
    class NavigationMenuList < Components::Base
      def view_template(&block)
        ul(class: merged_classes, **attrs_without_class, &block)
      end

      private

      def classes
        "group flex flex-1 list-none items-center justify-center space-x-1"
      end
    end

    # Navigation Menu Item - individual menu item container
    class NavigationMenuItem < Components::Base
      def view_template(&block)
        li(class: merged_classes, **attrs_without_class, &block)
      end

      private

      def classes
        ""
      end
    end

    # Navigation Menu Trigger - button that triggers submenu
    class NavigationMenuTrigger < Components::Base
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
          "group inline-flex h-10 w-max items-center justify-center rounded-md bg-background px-4 py-2 text-sm font-medium",
          "transition-colors",
          "hover:bg-accent hover:text-accent-foreground",
          "focus:bg-accent focus:text-accent-foreground focus:outline-none",
          "disabled:pointer-events-none disabled:opacity-50",
          "data-[active]:bg-accent/50 data-[state=open]:bg-accent/50"
        ].join(" ")
      end
    end

    # Navigation Menu Content - dropdown content container
    class NavigationMenuContent < Components::Base
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
          "left-0 top-0 w-full",
          "data-[motion^=from-]:animate-in data-[motion^=to-]:animate-out",
          "data-[motion^=from-]:fade-in data-[motion^=to-]:fade-out",
          "data-[motion=from-end]:slide-in-from-right-52 data-[motion=from-start]:slide-in-from-left-52",
          "data-[motion=to-end]:slide-out-to-right-52 data-[motion=to-start]:slide-out-to-left-52",
          "md:absolute md:w-auto"
        ].join(" ")
      end
    end

    # Navigation Menu Link - link within the menu
    class NavigationMenuLink < Components::Base
      def initialize(href: nil, active: false, **attrs)
        @href = href
        @active = active
        @attrs = attrs
      end

      def view_template(&block)
        dynamic_attrs = attrs_without_class.dup

        # Add data-active if active
        if @active
          data_hash = (dynamic_attrs[:data] || {}).dup
          data_hash[:active] = "" unless data_hash.key?(:active) || data_hash.key?("active")
          dynamic_attrs[:data] = data_hash
        end

        if @href
          a(href: @href, class: merged_classes, **dynamic_attrs, &block)
        else
          span(class: merged_classes, **dynamic_attrs, &block)
        end
      end

      private

      def classes
        [
          "block select-none space-y-1 rounded-md p-3 leading-none no-underline outline-none",
          "transition-colors",
          "hover:bg-accent hover:text-accent-foreground",
          "focus:bg-accent focus:text-accent-foreground"
        ].join(" ")
      end
    end

    # Navigation Menu Viewport - container for the content
    class NavigationMenuViewport < Components::Base
      def view_template(&block)
        div(class: merged_classes, **attrs_without_class, &block)
      end

      private

      def classes
        [
          "origin-top-center relative mt-1.5 h-[var(--radix-navigation-menu-viewport-height)] w-full overflow-hidden rounded-md border border-border bg-popover text-popover-foreground shadow-lg",
          "data-[state=open]:animate-in data-[state=closed]:animate-out",
          "data-[state=closed]:zoom-out-95 data-[state=open]:zoom-in-90",
          "md:w-[var(--radix-navigation-menu-viewport-width)]"
        ].join(" ")
      end
    end

    # Navigation Menu Indicator - visual indicator for active item
    class NavigationMenuIndicator < Components::Base
      def view_template
        div(class: merged_classes, **attrs_without_class) do
          div(class: "relative top-[60%] h-2 w-2 rotate-45 rounded-tl-sm bg-border shadow-md")
        end
      end

      private

      def classes
        [
          "top-full z-[1] flex h-1.5 items-end justify-center overflow-hidden",
          "data-[state=visible]:animate-in data-[state=hidden]:animate-out",
          "data-[state=hidden]:fade-out data-[state=visible]:fade-in"
        ].join(" ")
      end
    end
  end
end
