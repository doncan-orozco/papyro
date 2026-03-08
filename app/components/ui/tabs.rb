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
        div(
          class: merged_classes,
          **attrs_without_class,
          &block
        )
      end

      private

      def classes
        "w-full"
      end
    end

    # Tabs list (the tab buttons container)
    class TabsList < Components::Base
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
    class TabsTrigger < Components::Base
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
    class TabsContent < Components::Base
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
  end
end

# Zeitwerk autoload helpers for nested classes defined above
# Without these, requesting Components::Ui::TabsList (etc.) would try to
# load tabs_list.rb which doesn’t exist. By registering them here we point
# Zeitwerk at this file as their source.

Components::Ui.autoload :TabsList, __FILE__
Components::Ui.autoload :TabsTrigger, __FILE__
Components::Ui.autoload :TabsContent, __FILE__
