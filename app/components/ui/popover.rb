# frozen_string_literal: true

module Components
  module Ui
    class Popover < Components::Base
      def initialize(open: nil, placement: nil, offset: nil, **attrs)
        @attrs = attrs
        @attrs[:data] ||= {}
        @attrs[:data][:controller] = "ui--popover" unless @attrs[:data][:controller]

        if !open.nil? && !@attrs[:data].key?(:ui__popover_open_value) && !@attrs[:data].key?("ui__popover_open_value")
          @attrs[:data][:ui__popover_open_value] = open
        elsif !@attrs[:data].key?(:ui__popover_open_value) && !@attrs[:data].key?("ui__popover_open_value")
          @attrs[:data][:ui__popover_open_value] = false
        end

        if !placement.nil? && !@attrs[:data].key?(:ui__popover_placement_value) && !@attrs[:data].key?("ui__popover_placement_value")
          @attrs[:data][:ui__popover_placement_value] = placement
        end

        if !offset.nil? && !@attrs[:data].key?(:ui__popover_offset_value) && !@attrs[:data].key?("ui__popover_offset_value")
          @attrs[:data][:ui__popover_offset_value] = offset
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
            ui__popover_target: "trigger",
            action: "click->ui--popover#toggle"
          }
        )), &block
      end

      def content(hidden: true, align: nil, side: nil, **attrs, &block)
        render Content.new(
          hidden: hidden,
          align: align,
          side: side,
          **with_required_data(attrs, data: { ui__popover_target: "content" }),
          &block
        )
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
        def initialize(align: nil, side: nil, **attrs)
          @align = align
          @side = side
          @attrs = attrs
        end

        def view_template(&block)
          dynamic_attrs = attrs_without_class.dup
          data_hash = (dynamic_attrs[:data] || {}).dup

          data_hash[:align] = @align if @align && !data_hash.key?(:align) && !data_hash.key?("align")
          data_hash[:side] = @side if @side && !data_hash.key?(:side) && !data_hash.key?("side")
          dynamic_attrs[:data] = data_hash

          dynamic_attrs[:role] = :dialog unless dynamic_attrs.key?(:role) || dynamic_attrs.key?("role")

          div(class: merged_classes, **dynamic_attrs, &block)
        end

        private

        def classes
          [
            "z-50 w-72 rounded-md border border-border bg-popover p-4 text-popover-foreground shadow-md outline-none",
            "transition-opacity duration-200",
            "data-[state=open]:animate-in data-[state=closed]:animate-out",
            "data-[state=closed]:fade-out-0 data-[state=open]:fade-in-0",
            "data-[state=closed]:zoom-out-95 data-[state=open]:zoom-in-95",
            "data-[side=bottom]:slide-in-from-top-2 data-[side=left]:slide-in-from-right-2",
            "data-[side=right]:slide-in-from-left-2 data-[side=top]:slide-in-from-bottom-2",
            "origin-[--radix-popover-content-transform-origin]"
          ].join(" ")
        end
      end

      PopoverTrigger = Trigger
      PopoverContent = Content
    end
  end
end
