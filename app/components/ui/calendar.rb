# frozen_string_literal: true

# Calendar - date selection grid component
# Following shadcn/ui Radix patterns with semantic tokens
# Note: Requires Stimulus controller for date management and navigation
module Components
  module Ui
    # Calendar root container
    class Calendar < Components::Base
      def initialize(mode: :single, selected: nil, **attrs)
        @mode = mode # :single or :multiple or :range
        @selected = selected
        @attrs = attrs
      end

      def view_template(&block)
        dynamic_attrs = attrs_without_class.dup

        # Add data attributes
        data_hash = dynamic_attrs[:data] || {}
        data_hash[:mode] = @mode unless data_hash.key?(:mode) || data_hash.key?("mode")
        dynamic_attrs[:data] = data_hash

        div(
          role: :region,
          aria: { label: "Calendar" },
          class: merged_classes,
          **dynamic_attrs,
          &block
        )
      end

      private

      def classes
        "p-3"
      end
    end

    # Calendar Header - navigation and month/year display
    class CalendarHeader < Components::Base
      def view_template(&block)
        div(class: merged_classes, **attrs_without_class, &block)
      end

      private

      def classes
        "flex items-center justify-between pb-4"
      end
    end

    # Calendar Heading - month and year text
    class CalendarHeading < Components::Base
      def view_template(&block)
        div(
          role: :heading,
          aria: { live: "polite" },
          class: merged_classes,
          **attrs_without_class,
          &block
        )
      end

      private

      def classes
        "text-sm font-medium"
      end
    end

    # Calendar Nav - navigation button group
    class CalendarNav < Components::Base
      def view_template(&block)
        div(class: merged_classes, **attrs_without_class, &block)
      end

      private

      def classes
        "flex items-center gap-1"
      end
    end

    # Calendar Grid - table of dates
    class CalendarGrid < Components::Base
      def view_template(&block)
        table(
          role: :grid,
          class: merged_classes,
          **attrs_without_class,
          &block
        )
      end

      private

      def classes
        "w-full border-collapse"
      end
    end

    # Calendar Head - table header with day names
    class CalendarHead < Components::Base
      def view_template(&block)
        thead(class: merged_classes, **attrs_without_class, &block)
      end

      private

      def classes
        ""
      end
    end

    # Calendar HeadRow - row of day names
    class CalendarHeadRow < Components::Base
      def view_template(&block)
        tr(class: merged_classes, **attrs_without_class, &block)
      end

      private

      def classes
        "flex"
      end
    end

    # Calendar HeadCell - individual day name cell
    class CalendarHeadCell < Components::Base
      def view_template(&block)
        th(
          scope: :col,
          class: merged_classes,
          **attrs_without_class,
          &block
        )
      end

      private

      def classes
        "w-9 rounded-md text-[0.8rem] font-normal text-muted-foreground"
      end
    end

    # Calendar Body - table body with dates
    class CalendarBody < Components::Base
      def view_template(&block)
        tbody(class: merged_classes, **attrs_without_class, &block)
      end

      private

      def classes
        ""
      end
    end

    # Calendar Row - week row
    class CalendarRow < Components::Base
      def view_template(&block)
        tr(class: merged_classes, **attrs_without_class, &block)
      end

      private

      def classes
        "mt-2 flex w-full"
      end
    end

    # Calendar Cell - individual date cell
    class CalendarCell < Components::Base
      def view_template(&block)
        td(
          role: :gridcell,
          class: merged_classes,
          **attrs_without_class,
          &block
        )
      end

      private

      def classes
        [
          "relative p-0 text-center text-sm",
          "focus-within:relative focus-within:z-20",
          "[&:has([aria-selected])]:bg-accent",
          "[&:has([aria-selected].day-outside)]:bg-accent/50",
          "[&:has([aria-selected].day-range-end)]:rounded-r-md"
        ].join(" ")
      end
    end

    # Calendar Day - clickable day button
    class CalendarDay < Components::Base
      def initialize(selected: false, today: false, outside: false, **attrs)
        @selected = selected
        @today = today
        @outside = outside
        @attrs = attrs
      end

      def view_template(&block)
        dynamic_attrs = attrs_without_class.dup

        # Add aria-selected
        aria_hash = dynamic_attrs[:aria] || {}
        aria_hash[:selected] = @selected unless aria_hash.key?(:selected) || aria_hash.key?("selected")
        dynamic_attrs[:aria] = aria_hash

        button(
          type: :button,
          role: :gridcell,
          class: merged_classes,
          **dynamic_attrs,
          &block
        )
      end

      private

      def classes
        [
          "inline-flex h-9 w-9 items-center justify-center rounded-md p-0 text-sm font-normal",
          "transition-colors",
          "hover:bg-accent hover:text-accent-foreground",
          "focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2",
          "disabled:pointer-events-none disabled:opacity-50",
          @selected ? "bg-primary text-primary-foreground hover:bg-primary hover:text-primary-foreground focus:bg-primary focus:text-primary-foreground" : "",
          @today ? "bg-accent text-accent-foreground" : "",
          @outside ? "text-muted-foreground opacity-50 day-outside" : ""
        ].compact.join(" ")
      end
    end
  end
end
