# frozen_string_literal: true

module Components
  module Ui
    class Dialog < Components::Base
      def initialize(open: nil, close_on_overlay_click: nil, close_on_esc: nil, **attrs)
        @attrs = attrs
        @attrs[:data] ||= {}
        @attrs[:data][:controller] = "ui--dialog" unless @attrs[:data][:controller]

        if !open.nil? && !@attrs[:data].key?(:ui__dialog_open_value) && !@attrs[:data].key?("ui__dialog_open_value")
          @attrs[:data][:ui__dialog_open_value] = open
        elsif !@attrs[:data].key?(:ui__dialog_open_value) && !@attrs[:data].key?("ui__dialog_open_value")
          @attrs[:data][:ui__dialog_open_value] = false
        end

        if !close_on_overlay_click.nil? && !@attrs[:data].key?(:ui__dialog_close_on_overlay_click_value) && !@attrs[:data].key?("ui__dialog_close_on_overlay_click_value")
          @attrs[:data][:ui__dialog_close_on_overlay_click_value] = close_on_overlay_click
        end

        if !close_on_esc.nil? && !@attrs[:data].key?(:ui__dialog_close_on_esc_value) && !@attrs[:data].key?("ui__dialog_close_on_esc_value")
          @attrs[:data][:ui__dialog_close_on_esc_value] = close_on_esc
        end
      end

      def view_template(&block)
        div(class: merged_classes, **attrs_without_class) do
          yield self if block
        end
      end

      def trigger(**attrs, &block)
        render Trigger.new(**with_required_data(attrs, data: { action: "click->ui--dialog#open" })), &block
      end

      def content(hidden: true, overlay_hidden: true, labelledby_id: nil, describedby_id: nil, close_button: true, **attrs, &block)
        render Overlay.new(
          hidden: overlay_hidden,
          **with_required_data({}, data: { ui__dialog_target: "overlay" })
        )

        render Content.new(
          hidden: hidden,
          labelledby_id: labelledby_id,
          describedby_id: describedby_id,
          close_button: close_button,
          **with_required_data(attrs, data: { ui__dialog_target: "content" }),
          &block
        )
      end

      def header(**attrs, &block)
        render Header.new(**attrs, &block)
      end

      def title(**attrs, &block)
        render Title.new(**attrs, &block)
      end

      def description(**attrs, &block)
        render Description.new(**attrs, &block)
      end

      def footer(**attrs, &block)
        render Footer.new(**attrs, &block)
      end

      def close(**attrs, &block)
        render Close.new(**with_required_data(attrs, data: { action: "click->ui--dialog#close" }), &block)
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

      class Overlay < Components::Base
        def initialize(**attrs)
          @attrs = attrs
        end

        def view_template
          div(class: merged_classes, **attrs_without_class)
        end

        private

        def classes
          [
            "fixed inset-0 z-50 bg-black/80",
            "data-[state=open]:animate-in data-[state=closed]:animate-out",
            "data-[state=closed]:fade-out-0 data-[state=open]:fade-in-0",
            "data-[state=open]:duration-500 data-[state=closed]:duration-300"
          ].join(" ")
        end
      end

      class Content < Components::Base
        def initialize(labelledby_id: nil, describedby_id: nil, close_button: true, **attrs)
          @labelledby_id = labelledby_id
          @describedby_id = describedby_id
          @close_button = close_button
          @attrs = attrs
        end

        def view_template(&block)
          dynamic_attrs = attrs_without_class.dup

          aria_hash = dynamic_attrs[:aria] || {}
          aria_hash[:modal] = true unless aria_hash.key?(:modal) || aria_hash.key?("modal")

          if @labelledby_id && !aria_hash.key?(:labelledby) && !aria_hash.key?("labelledby")
            aria_hash[:labelledby] = @labelledby_id
          end

          if @describedby_id && !aria_hash.key?(:describedby) && !aria_hash.key?("describedby")
            aria_hash[:describedby] = @describedby_id
          end

          dynamic_attrs[:aria] = aria_hash

          div(role: :dialog, class: merged_classes, **dynamic_attrs) do
            yield if block

            if @close_button
              render Close.new(data: { action: "click->ui--dialog#close" }) do
                svg(
                  xmlns: "http://www.w3.org/2000/svg",
                  viewBox: "0 0 24 24",
                  fill: "none",
                  stroke: "currentColor",
                  class: "h-4 w-4"
                ) do |s|
                  s.path(d: "M6 18L18 6M6 6l12 12", stroke_width: 2, stroke_linecap: "round", stroke_linejoin: "round")
                end
                span(class: "sr-only") { I18n.t("design_system.overlays.dialog.close") }
              end
            end
          end
        end

        private

        def classes
          [
            "fixed left-[50%] top-[50%] z-50",
            "grid w-full max-w-lg translate-x-[-50%] translate-y-[-50%] gap-4",
            "border border-border bg-background p-6 shadow-lg",
            "transition-all duration-200",
            "data-[state=open]:animate-in data-[state=closed]:animate-out",
            "data-[state=closed]:fade-out-0 data-[state=open]:fade-in-0",
            "data-[state=closed]:zoom-out-95 data-[state=open]:zoom-in-95",
            "data-[state=closed]:slide-out-to-left-1/2 data-[state=closed]:slide-out-to-top-[48%]",
            "data-[state=open]:slide-in-from-left-1/2 data-[state=open]:slide-in-from-top-[48%]",
            "data-[state=open]:duration-500 data-[state=closed]:duration-300",
            "sm:rounded-lg"
          ].join(" ")
        end
      end

      class Header < Components::Base
        def initialize(**attrs)
          @attrs = attrs
        end

        def view_template(&block)
          div(class: merged_classes, **attrs_without_class, &block)
        end

        private

        def classes
          "flex flex-col space-y-1.5 text-center sm:text-left"
        end
      end

      class Title < Components::Base
        def initialize(**attrs)
          @attrs = attrs
        end

        def view_template(&block)
          h2(class: merged_classes, **attrs_without_class, &block)
        end

        private

        def classes
          "text-lg font-semibold leading-none tracking-tight"
        end
      end

      class Description < Components::Base
        def initialize(**attrs)
          @attrs = attrs
        end

        def view_template(&block)
          p(class: merged_classes, **attrs_without_class, &block)
        end

        private

        def classes
          "text-sm text-muted-foreground"
        end
      end

      class Footer < Components::Base
        def initialize(**attrs)
          @attrs = attrs
        end

        def view_template(&block)
          div(class: merged_classes, **attrs_without_class, &block)
        end

        private

        def classes
          "flex flex-col-reverse sm:flex-row sm:justify-end sm:space-x-2"
        end
      end

      class Close < Components::Base
        def initialize(**attrs)
          @attrs = attrs
        end

        def view_template(&block)
          button(type: :button, class: merged_classes, **attrs_without_class, &block)
        end

        private

        def classes
          [
            "absolute right-4 top-4 rounded-sm opacity-70 ring-offset-background",
            "transition-opacity hover:opacity-100",
            "focus:outline-none focus:ring-2 focus:ring-ring focus:ring-offset-2",
            "disabled:pointer-events-none",
            "data-[state=open]:bg-accent data-[state=open]:text-muted-foreground"
          ].join(" ")
        end
      end

      DialogTrigger = Trigger
      DialogOverlay = Overlay
      DialogContent = Content
      DialogHeader = Header
      DialogTitle = Title
      DialogDescription = Description
      DialogFooter = Footer
      DialogClose = Close
    end
  end
end
