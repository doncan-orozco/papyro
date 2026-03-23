# frozen_string_literal: true

# Select component following shadcn/ui Radix patterns
# Uses compound component pattern with nested trigger/content/item/value
module Components
  module Ui
    class Select < Components::Base
      def initialize(default_value: nil, value: nil, placeholder: nil, **attrs)
        @attrs = attrs
        @attrs[:data] ||= {}
        @attrs[:data][:controller] = "ui--select" unless @attrs[:data][:controller]

        selected_value = value.nil? ? default_value : value
        if !selected_value.nil? && !@attrs[:data].key?(:ui__select_value_value) && !@attrs[:data].key?("ui__select_value_value")
          @attrs[:data][:ui__select_value_value] = selected_value
        end

        if !placeholder.nil? && !@attrs[:data].key?(:ui__select_placeholder_value) && !@attrs[:data].key?("ui__select_placeholder_value")
          @attrs[:data][:ui__select_placeholder_value] = placeholder
        end
      end

      def view_template(&block)
        div(class: merged_classes, **attrs_without_class) do
          yield self if block
        end
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

      def value(**attrs)
        render Value.new(**attrs)
      end

      private

      def classes
        ""
      end

      class Trigger < Components::Base
        def initialize(placeholder: nil, **attrs)
          @placeholder = placeholder
          @attrs = attrs
        end

        def view_template(&block)
          dynamic_attrs = attrs_without_class.dup
          dynamic_attrs[:data] = with_required_data(
            dynamic_attrs[:data],
            ui__select_target: "trigger",
            action: "click->ui--select#toggle keydown->ui--select#navigate"
          )

          button(
            type: "button",
            role: "combobox",
            aria_expanded: "false",
            aria_haspopup: "listbox",
            class: merged_classes,
            **dynamic_attrs,
            &block
          )
        end

        private

        def classes
          [
            "flex h-9 w-full items-center justify-between whitespace-nowrap",
            "rounded-md border border-input bg-transparent",
            "px-3 py-2 text-sm shadow-sm",
            "ring-offset-background",
            "focus:outline-none focus:ring-1 focus:ring-ring",
            "disabled:cursor-not-allowed disabled:opacity-50",
            "[&>span]:line-clamp-1"
          ].join(" ")
        end

        def with_required_data(existing_data, **required_data)
          data_hash = (existing_data || {}).dup
          merged_required = required_data.dup

          if (data_hash.key?(:action) || data_hash.key?("action")) && merged_required.key?(:action)
            existing_action = data_hash[:action] || data_hash["action"]
            merged_required[:action] = merge_action_tokens(existing_action, merged_required[:action])
          end

          data_hash.merge(merged_required)
        end

        def merge_action_tokens(existing_actions, required_actions)
          (existing_actions.to_s.split + required_actions.to_s.split).uniq.join(" ")
        end
      end

      class Content < Components::Base
        def initialize(**attrs)
          @attrs = attrs
        end

        def view_template(&block)
          dynamic_attrs = attrs_without_class.dup
          dynamic_attrs[:data] = with_required_data(dynamic_attrs[:data], ui__select_target: "content")

          div(
            role: :listbox,
            class: merged_classes,
            **dynamic_attrs,
            &block
          )
        end

        private

        def classes
          [
            "!fixed",
            "z-50 min-w-[8rem]",
            "max-h-96 overflow-y-auto overflow-x-hidden",
            "rounded-md border border-border bg-popover p-1",
            "text-popover-foreground shadow-md"
          ].join(" ")
        end

        def with_required_data(existing_data, **required_data)
          (existing_data || {}).dup.merge(required_data)
        end
      end

      class Item < Components::Base
        def initialize(value:, **attrs)
          @value = value
          @attrs = attrs
        end

        def view_template(&block)
          merged_data = with_required_data(
            @attrs[:data],
            ui__select_target: "item",
            action: "click->ui--select#selectItem",
            value: @value
          )

          div(
            role: :option,
            data: merged_data,
            class: merged_classes,
            **attrs_without_class.except(:data)
          ) do
            span(class: "absolute right-2 flex h-3.5 w-3.5 items-center justify-center") do
              render Components::Ui::Icon.new(
                :check,
                source: :lucide,
                class: "h-4 w-4 hidden data-[selected=true]:inline",
                data: { ui__select_checkmark: true }
              )
            end
            span(&block)
          end
        end

        private

        def classes
          [
            "relative flex w-full cursor-default select-none items-center",
            "rounded-sm py-1.5 pl-2 pr-8 text-sm outline-none",
            "hover:bg-accent hover:text-accent-foreground",
            "data-[disabled]:pointer-events-none data-[disabled]:opacity-50"
          ].join(" ")
        end

        def with_required_data(existing_data, **required_data)
          data_hash = (existing_data || {}).dup
          merged_required = required_data.dup

          if (data_hash.key?(:action) || data_hash.key?("action")) && merged_required.key?(:action)
            existing_action = data_hash[:action] || data_hash["action"]
            merged_required[:action] = merge_action_tokens(existing_action, merged_required[:action])
          end

          data_hash.merge(merged_required)
        end

        def merge_action_tokens(existing_actions, required_actions)
          (existing_actions.to_s.split + required_actions.to_s.split).uniq.join(" ")
        end
      end

      class Value < Components::Base
        def initialize(placeholder: nil, **attrs)
          @placeholder = placeholder
          @attrs = attrs
        end

        def view_template
          dynamic_attrs = attrs_without_class.dup
          dynamic_attrs[:data] = with_required_data(dynamic_attrs[:data], ui__select_target: "valueDisplay")

          span(class: merged_classes, **dynamic_attrs) { @placeholder }
        end

        private

        def classes
          ""
        end

        def with_required_data(existing_data, **required_data)
          (existing_data || {}).dup.merge(required_data)
        end
      end

      SelectTrigger = Trigger
      SelectContent = Content
      SelectItem = Item
      SelectValue = Value
    end
  end
end
