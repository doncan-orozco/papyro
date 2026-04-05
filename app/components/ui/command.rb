# frozen_string_literal: true

# Command - command palette/search component
# Following shadcn/ui Radix patterns with semantic tokens
# Note: Requires Stimulus controller for filtering and keyboard navigation
module Components
  module Ui
    # Command root container
    class Command < Components::Base
      def view_template(&block)
        div(
          role: :application,
          class: merged_classes,
          **attrs_without_class,
        ) do
          yield self if block
        end
      end

      def dialog(**attrs, &block)
        render Dialog.new(**attrs), &block
      end

      def input(**attrs, &block)
        render Input.new(**attrs), &block
      end

      def list(**attrs, &block)
        render List.new(**attrs), &block
      end

      def empty(**attrs, &block)
        render Empty.new(**attrs), &block
      end

      def group(**attrs, &block)
        render Group.new(**attrs), &block
      end

      def separator(**attrs, &block)
        render Separator.new(**attrs), &block
      end

      def item(**attrs, &block)
        render Item.new(**attrs), &block
      end

      def shortcut(**attrs, &block)
        render Shortcut.new(**attrs), &block
      end

      private

      def classes
        [
          "flex h-full w-full flex-col overflow-hidden rounded-md bg-popover text-popover-foreground"
        ].join(" ")
      end
    end

    # Command Dialog - modal wrapper for command palette
    class Command::Dialog < Components::Base
      def view_template(&block)
        div(
          role: :dialog,
          class: merged_classes,
          **attrs_without_class,
          &block
        )
      end

      private

      def classes
        [
          "fixed left-[50%] top-[50%] z-50",
          "max-h-[85vh] w-full max-w-[640px]",
          "translate-x-[-50%] translate-y-[-50%]",
          "overflow-hidden rounded-lg border border-border bg-background shadow-lg",
          "data-[state=open]:animate-in data-[state=closed]:animate-out",
          "data-[state=closed]:fade-out-0 data-[state=open]:fade-in-0",
          "data-[state=closed]:zoom-out-95 data-[state=open]:zoom-in-95"
        ].join(" ")
      end
    end

    # Command Input - search input
    class Command::Input < Components::Base
      def initialize(placeholder: nil, **attrs)
        @placeholder = placeholder
        @attrs = attrs
      end

      def view_template
        div(class: "flex items-center border-b border-border px-3") do
          # Search icon
          svg(
            class: "mr-2 h-4 w-4 shrink-0 opacity-50",
            xmlns: "http://www.w3.org/2000/svg",
            width: 24,
            height: 24,
            viewBox: "0 0 24 24",
            fill: "none",
            stroke: "currentColor",
            stroke_width: 2,
            stroke_linecap: "round",
            stroke_linejoin: "round"
          ) do |s|
            s.circle(cx: 11, cy: 11, r: 8)
            s.path(d: "m21 21-4.3-4.3")
          end

          input(
            type: :text,
            placeholder: @placeholder,
            class: merged_classes,
            **attrs_without_class
          )
        end
      end

      private

      def classes
        [
          "flex h-11 w-full rounded-md bg-transparent py-3 text-sm outline-none",
          "placeholder:text-muted-foreground",
          "disabled:cursor-not-allowed disabled:opacity-50"
        ].join(" ")
      end
    end

    # Command List - scrollable list of results
    class Command::List < Components::Base
      def view_template(&block)
        div(
          role: :listbox,
          class: merged_classes,
          **attrs_without_class,
          &block
        )
      end

      private

      def classes
        "max-h-[300px] overflow-y-auto overflow-x-hidden"
      end
    end

    # Command Empty - empty state message
    class Command::Empty < Components::Base
      def view_template(&block)
        div(class: merged_classes, **attrs_without_class, &block)
      end

      private

      def classes
        "py-6 text-center text-sm"
      end
    end

    # Command Group - grouped list items
    class Command::Group < Components::Base
      def view_template(&block)
        div(
          role: :group,
          class: merged_classes,
          **attrs_without_class,
          &block
        )
      end

      private

      def classes
        [
          "overflow-hidden p-1 text-foreground",
          "[&_[role=group]]:px-2 [&_[role=group]]:py-1.5 [&_[role=group]]:text-xs [&_[role=group]]:font-medium [&_[role=group]]:text-muted-foreground"
        ].join(" ")
      end
    end

    # Command Separator - visual divider
    class Command::Separator < Components::Base
      def view_template
        div(class: merged_classes, **attrs_without_class)
      end

      private

      def classes
        "-mx-1 h-px bg-border"
      end
    end

    # Command Item - individual result item
    class Command::Item < Components::Base
      def view_template(&block)
        div(
          role: :option,
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
          "data-[disabled]:pointer-events-none data-[selected=true]:bg-accent data-[selected=true]:text-accent-foreground data-[disabled]:opacity-50"
        ].join(" ")
      end
    end

    # Command Shortcut - keyboard shortcut display
    class Command::Shortcut < Components::Base
      def view_template(&block)
        span(class: merged_classes, **attrs_without_class, &block)
      end

      private

      def classes
        "ml-auto text-xs tracking-widest text-muted-foreground"
      end
    end

    CommandDialog = Command::Dialog
    CommandInput = Command::Input
    CommandList = Command::List
    CommandEmpty = Command::Empty
    CommandGroup = Command::Group
    CommandSeparator = Command::Separator
    CommandItem = Command::Item
    CommandShortcut = Command::Shortcut
  end
end
