# frozen_string_literal: true

# Tabs component following shadcn/ui Radix patterns
# Uses semantic tokens for theming
# Updated: 2026-02-17 for pixel-perfect shadcn Radix UI compatibility
# Note: Requires Stimulus controller for full interactivity
module Components
  module Ui
    # Tabs container
    class Tabs < Components::Base
      def initialize(**attrs)
        @attrs = attrs
      end

      def view_template(&block)
        dynamic_attrs = attrs_without_class.dup
        dynamic_attrs = with_required_data(dynamic_attrs, data: { controller: "ui--tabs" })

        div(
          class: merged_classes,
          **dynamic_attrs,
        ) do
          yield self if block
        end
      end

      def list(**attrs, &block)
        render List.new(**attrs), &block
      end

      def trigger(**attrs, &block)
        render Trigger.new(
          **with_required_data(
            attrs,
            data: {
              ui__tabs_target: "trigger",
              action: "click->ui--tabs#select keydown->ui--tabs#keydown"
            }
          )
        ), &block
      end

      def content(**attrs, &block)
        render Content.new(**with_required_data(attrs, data: { ui__tabs_target: "content" })), &block
      end

      private

      def classes
        "w-full"
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
    end

    # Tabs list (the tab buttons container)
    class Tabs::List < Components::Base
      def initialize(**attrs)
        @attrs = attrs
      end

      def view_template(&block)
        div(
          role: :tablist,
          class: merged_classes,
          **attrs_without_class,
          &block
        )
      end

      private

      def classes
        [
          "inline-flex h-9 items-center justify-center",
          "rounded-lg bg-muted p-1",
          "text-muted-foreground"
        ].join(" ")
      end
    end

    # Tab trigger button
    class Tabs::Trigger < Components::Base
      def initialize(**attrs)
        @attrs = attrs
      end

      def view_template(&block)
        button(
          type: :button,
          role: :tab,
          class: merged_classes,
          **attrs_without_class,
          &block
        )
      end

      private

      def classes
        [
          "inline-flex items-center justify-center whitespace-nowrap",
          "rounded-md px-3 py-1",
          "text-sm font-medium",
          "ring-offset-background transition-all",
          "focus-visible:outline-none focus-visible:ring-3 focus-visible:ring-ring/20",
          "disabled:pointer-events-none disabled:opacity-50",
          "data-[state=active]:bg-background data-[state=active]:text-foreground",
          "data-[state=active]:shadow"
        ].join(" ")
      end
    end

    # Tab content panel
    class Tabs::Content < Components::Base
      def initialize(**attrs)
        @attrs = attrs
      end

      def view_template(&block)
        div(
          role: :tabpanel,
          class: merged_classes,
          **attrs_without_class,
          &block
        )
      end

      private

      def classes
        [
          "mt-2",
          "ring-offset-background",
          "focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2"
        ].join(" ")
      end
    end

    TabsList = Tabs::List
    TabsTrigger = Tabs::Trigger
    TabsContent = Tabs::Content
  end
end
