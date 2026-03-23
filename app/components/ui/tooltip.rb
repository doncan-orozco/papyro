# frozen_string_literal: true

# Tooltip component following shadcn/ui Radix patterns
# Uses compound component pattern with nested trigger/content helpers
module Components
  module Ui
    class Tooltip < Components::Base
      def initialize(delay: nil, placement: nil, offset: nil, **attrs)
        @attrs = attrs
        @attrs[:data] ||= {}
        @attrs[:data][:controller] = "ui--tooltip" unless @attrs[:data][:controller]

        if !delay.nil? && !@attrs[:data].key?(:ui__tooltip_delay_value) && !@attrs[:data].key?("ui__tooltip_delay_value")
          @attrs[:data][:ui__tooltip_delay_value] = delay
        end

        if !placement.nil? && !@attrs[:data].key?(:ui__tooltip_placement_value) && !@attrs[:data].key?("ui__tooltip_placement_value")
          @attrs[:data][:ui__tooltip_placement_value] = placement
        end

        if !offset.nil? && !@attrs[:data].key?(:ui__tooltip_offset_value) && !@attrs[:data].key?("ui__tooltip_offset_value")
          @attrs[:data][:ui__tooltip_offset_value] = offset
        end
      end

      def view_template(&block)
        div(class: merged_classes, **attrs_without_class) do
          yield self if block
        end
      end

      def trigger(**attrs, &block)
        render Trigger.new(**with_required_data(
          attrs,
          data: {
            ui__tooltip_target: "trigger",
            action: "mouseenter->ui--tooltip#show mouseleave->ui--tooltip#hide focus->ui--tooltip#show blur->ui--tooltip#hide"
          }
        )), &block
      end

      def content(**attrs, &block)
        render Content.new(**with_required_data(attrs, data: { ui__tooltip_target: "content" })), &block
      end

      private

      def classes
        ""
      end

      def with_required_data(attrs, data:)
        merged_attrs = attrs.dup
        existing_data = (merged_attrs[:data] || {}).dup
        required_data = data.dup

        if required_data.key?(:action) && (existing_data.key?(:action) || existing_data.key?("action"))
          existing_action = existing_data[:action] || existing_data["action"]
          required_data[:action] = merge_action_tokens(existing_action, required_data[:action])
        end

        merged_attrs[:data] = existing_data.merge(required_data)
        merged_attrs
      end

      def merge_action_tokens(existing_actions, required_actions)
        (existing_actions.to_s.split + required_actions.to_s.split).uniq.join(" ")
      end

      class Trigger < Components::Base
        def initialize(**attrs)
          @attrs = attrs
        end

        def view_template(&block)
          div(class: merged_classes, **attrs_without_class, &block)
        end

        private

        def classes
          "inline-block"
        end
      end

      class Content < Components::Base
        def initialize(**attrs)
          @attrs = attrs
        end

        def view_template(&block)
          div(
            role: :tooltip,
            class: merged_classes,
            **attrs_without_class,
            &block
          )
        end

        private

        def classes
          [
            "z-50",
            "overflow-hidden",
            "rounded-lg border border-border bg-popover px-3 py-1.5",
            "text-sm text-popover-foreground shadow-md",
            "transition-all duration-200"
          ].join(" ")
        end
      end

      TooltipTrigger = Trigger
      TooltipContent = Content
    end
  end
end
