# frozen_string_literal: true

# Dropdown menu following shadcn/ui Radix patterns
# Yields itself via compound component pattern
# Requires Stimulus controller for full interactivity
module Components
  module Ui
    class DropdownMenu < Components::Base
      def initialize(**attrs)
        @attrs = attrs
        # Set default controller if not already provided
        @attrs[:data] ||= {}
        @attrs[:data][:controller] = "ui--dropdown" unless @attrs[:data][:controller]
      end

      def view_template(&block)
        div(class: merged_classes, **attrs_without_class) do
          yield self if block
        end
      end

      def trigger(**attrs, &block)
        render Trigger.new(
          **with_required_data(
            attrs,
            target: "trigger",
            required_action: "click->ui--dropdown#toggle"
          ),
          &block
        )
      end

      def content(**attrs, &block)
        render Content.new(
          **with_required_data(
            attrs,
            target: "content",
            required_action: "keydown->ui--dropdown#navigate"
          ),
          &block
        )
      end

      def item(**attrs, &block)
        render Item.new(
          **with_required_data(
            attrs,
            target: "item",
            required_action: "click->ui--dropdown#select keydown->ui--dropdown#itemKeydown"
          ),
          &block
        )
      end

      def separator(**attrs)
        render Separator.new(**attrs)
      end

      def label(**attrs, &block)
        render Label.new(**attrs, &block)
      end

      private

      def with_required_data(attrs, target:, required_action:)
        merged_attrs = attrs.dup
        data = (merged_attrs[:data] || {}).dup

        data[:ui__dropdown_target] ||= target
        data[:action] = merge_action_tokens(data[:action], required_action)

        merged_attrs[:data] = data
        merged_attrs
      end

      def merge_action_tokens(existing_actions, required_actions)
        action_tokens = [ existing_actions, required_actions ]
          .compact
          .flat_map { |value| value.to_s.split(/\s+/) }
          .reject(&:empty?)

        action_tokens.uniq.join(" ")
      end

      # Nested child classes
      class Trigger < Components::Base
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
            "focus-visible:outline-none focus-visible:ring-3 focus-visible:ring-ring/20",
            "disabled:pointer-events-none disabled:opacity-50"
          ].join(" ")
        end
      end

      class Content < Components::Base
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
            "!fixed",
            "z-50 min-w-[8rem]",
            "overflow-hidden",
            "rounded-lg border border-border bg-popover p-1",
            "text-popover-foreground shadow-md"
          ].join(" ")
        end
      end

      class Item < Components::Base
        def initialize(href: nil, variant: :default, **attrs)
          @href = href
          @variant = variant
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
            "hover:bg-accent hover:text-accent-foreground",
            "focus:bg-accent focus:text-accent-foreground",
            "disabled:pointer-events-none disabled:opacity-50",
            variant_classes.fetch(@variant, variant_classes[:default])
          ].join(" ")
        end

        def variant_classes
          {
            default: "",
            destructive: "text-destructive hover:bg-destructive hover:text-destructive-foreground focus:bg-destructive focus:text-destructive-foreground"
          }
        end
      end

      class Separator < Components::Base
        def initialize(**attrs)
          @attrs = attrs
        end

        def view_template
          div(class: merged_classes, **attrs_without_class)
        end

        private

        def classes
          "-mx-1 my-1 h-px bg-muted"
        end
      end

      class Label < Components::Base
        def initialize(**attrs)
          @attrs = attrs
        end

        def view_template(&block)
          div(class: merged_classes, **attrs_without_class, &block)
        end

        private

        def classes
          "px-2 py-1.5 text-xs font-medium text-muted-foreground"
        end
      end

      # Legacy compatibility aliases
      DropdownMenuTrigger = Trigger
      DropdownMenuContent = Content
      DropdownMenuItem = Item
      DropdownMenuSeparator = Separator
      DropdownMenuLabel = Label
    end
  end
end
