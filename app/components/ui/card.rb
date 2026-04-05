# frozen_string_literal: true

# Card components following shadcn/ui Radix patterns
# Uses semantic tokens for theming
# Updated: 2026-02-16 for pixel-perfect shadcn Radix UI compatibility
module Components
  module Ui
    # Main Card container
    class Card < Components::Base
      def initialize(**attrs)
        @attrs = attrs
      end

      def view_template(&block)
        div(class: merged_classes, **attrs_without_class) do
          yield self if block
        end
      end

      def header(**attrs, &block)
        render Header.new(**attrs), &block
      end

      def title(**attrs, &block)
        render Title.new(**attrs), &block
      end

      def description(**attrs, &block)
        render Description.new(**attrs), &block
      end

      def content(**attrs, &block)
        render Content.new(**attrs), &block
      end

      def footer(**attrs, &block)
        render Footer.new(**attrs), &block
      end

      private

      def classes
        "rounded-lg border border-border bg-card text-card-foreground shadow-sm"
      end
    end

    # Card header with title and description
    class Card::Header < Components::Base
      def initialize(**attrs)
        @attrs = attrs
      end

      def view_template(&block)
        div(class: merged_classes, **attrs_without_class, &block)
      end

      private

      def classes
        "flex flex-col space-y-1.5 p-6"
      end
    end

    # Card title (h3 by default, customizable)
    class Card::Title < Components::Base
      def initialize(as: :h3, **attrs)
        @as = as
        @attrs = attrs
      end

      def view_template(&block)
        public_send(@as, class: merged_classes, **attrs_without_class, &block)
      end

      private

      def classes
        "font-semibold leading-none tracking-tight"
      end
    end

    # Card description text
    class Card::Description < Components::Base
      def initialize(as: :p, **attrs)
        @as = as
        @attrs = attrs
      end

      def view_template(&block)
        public_send(@as, class: merged_classes, **attrs_without_class, &block)
      end

      private

      def classes
        "text-sm text-muted-foreground"
      end
    end

    # Card main content area
    class Card::Content < Components::Base
      def initialize(**attrs)
        @attrs = attrs
      end

      def view_template(&block)
        div(class: merged_classes, **attrs_without_class, &block)
      end

      private

      def classes
        "p-6 pt-0"
      end
    end

    # Card footer for actions
    class Card::Footer < Components::Base
      def initialize(**attrs)
        @attrs = attrs
      end

      def view_template(&block)
        div(class: merged_classes, **attrs_without_class, &block)
      end

      private

      def classes
        "flex items-center p-6 pt-0"
      end
    end

    CardHeader = Card::Header
    CardTitle = Card::Title
    CardDescription = Card::Description
    CardContent = Card::Content
    CardFooter = Card::Footer
  end
end
