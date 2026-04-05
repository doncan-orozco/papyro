# frozen_string_literal: true

# Table components following shadcn/ui Radix patterns
# Uses semantic tokens for theming
# Updated: 2026-02-17 for pixel-perfect shadcn Radix UI compatibility
module Components
  module Ui
    # Table element
    class Table < Components::Base
      def initialize(**attrs)
        @attrs = attrs
      end

      def view_template(&block)
        div(class: "relative w-full overflow-auto") do
          table(
            class: merged_classes,
            **attrs_without_class,
          ) do
            yield self if block
          end
        end
      end

      def header(**attrs, &block)
        render Header.new(**attrs), &block
      end

      def body(**attrs, &block)
        render Body.new(**attrs), &block
      end

      def footer(**attrs, &block)
        render Footer.new(**attrs), &block
      end

      def row(**attrs, &block)
        render Row.new(**attrs), &block
      end

      def head(**attrs, &block)
        render Head.new(**attrs), &block
      end

      def cell(**attrs, &block)
        render Cell.new(**attrs), &block
      end

      def caption(**attrs, &block)
        render Caption.new(**attrs), &block
      end

      private

      def classes
        "w-full caption-bottom text-sm border-collapse"
      end
    end

    # Table header
    class Table::Header < Components::Base
      def initialize(**attrs)
        @attrs = attrs
      end

      def view_template(&block)
        thead(
          class: merged_classes,
          **attrs_without_class,
          &block
        )
      end

      private

      def classes
        "[&_tr]:border-b"
      end
    end

    # Table body
    class Table::Body < Components::Base
      def initialize(**attrs)
        @attrs = attrs
      end

      def view_template(&block)
        tbody(
          class: merged_classes,
          **attrs_without_class,
          &block
        )
      end

      private

      def classes
        "[&_tr:last-child]:border-0"
      end
    end

    # Table footer
    class Table::Footer < Components::Base
      def initialize(**attrs)
        @attrs = attrs
      end

      def view_template(&block)
        tfoot(
          class: merged_classes,
          **attrs_without_class,
          &block
        )
      end

      private

      def classes
        "border-t bg-muted/50 font-medium [&>tr]:last:border-b-0"
      end
    end

    # Table row
    class Table::Row < Components::Base
      def initialize(**attrs)
        @attrs = attrs
      end

      def view_template(&block)
        tr(
          class: merged_classes,
          **attrs_without_class,
          &block
        )
      end

      private

      def classes
        [
          "border-b transition-colors",
          "hover:bg-muted/50",
          "data-[state=selected]:bg-muted"
        ].join(" ")
      end
    end

    # Table header cell
    class Table::Head < Components::Base
      def initialize(**attrs)
        @attrs = attrs
      end

      def view_template(&block)
        th(
          class: merged_classes,
          **attrs_without_class,
          &block
        )
      end

      private

      def classes
        [
          "h-10 px-2 text-left align-middle font-medium",
          "text-muted-foreground",
          "[&:has([role=checkbox])]:pr-0",
          "[&>[role=checkbox]]:translate-y-[2px]"
        ].join(" ")
      end
    end

    # Table cell
    class Table::Cell < Components::Base
      def initialize(**attrs)
        @attrs = attrs
      end

      def view_template(&block)
        td(
          class: merged_classes,
          **attrs_without_class,
          &block
        )
      end

      private

      def classes
        [
          "p-2 align-middle",
          "[&:has([role=checkbox])]:pr-0",
          "[&>[role=checkbox]]:translate-y-[2px]"
        ].join(" ")
      end
    end

    # Table caption
    class Table::Caption < Components::Base
      def initialize(**attrs)
        @attrs = attrs
      end

      def view_template(&block)
        caption(
          class: merged_classes,
          **attrs_without_class,
          &block
        )
      end

      private

      def classes
        "mt-4 text-sm text-muted-foreground"
      end
    end

    TableHeader = Table::Header
    TableBody = Table::Body
    TableFooter = Table::Footer
    TableRow = Table::Row
    TableHead = Table::Head
    TableCell = Table::Cell
    TableCaption = Table::Caption
  end
end
