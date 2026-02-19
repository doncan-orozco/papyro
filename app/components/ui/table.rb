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
        table(
          class: merged_classes,
          **attrs_without_class,
          &block
        )
      end

      private

      def classes
        "w-full caption-bottom text-sm"
      end
    end

    # Table header
    class TableHeader < Components::Base
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
    class TableBody < Components::Base
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
    class TableFooter < Components::Base
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
    class TableRow < Components::Base
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
    class TableHead < Components::Base
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
    class TableCell < Components::Base
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
    class TableCaption < Components::Base
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
  end
end
