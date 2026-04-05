# frozen_string_literal: true

# Calendar - date selection grid component
# Following shadcn/ui Radix patterns with semantic tokens
# Note: Requires Stimulus controller for date management and navigation
module Components
  module Ui
    # Calendar root container
    class Calendar < Components::Base
      def initialize(
        mode: :single,
        selected: nil,
        selected_dates: nil,
        range_start: nil,
        range_end: nil,
        min_date: nil,
        max_date: nil,
        disabled_dates: nil,
        **attrs
      )
        @mode = mode # :single or :multiple or :range
        @selected = selected
        @selected_dates = selected_dates
        @range_start = range_start
        @range_end = range_end
        @min_date = min_date
        @max_date = max_date
        @disabled_dates = disabled_dates
        @attrs = attrs
      end

      def view_template(&block)
        dynamic_attrs = attrs_without_class.dup

        # Add data attributes
        data_hash = (dynamic_attrs[:data] || {}).dup
        data_hash[:mode] = @mode unless data_hash.key?(:mode) || data_hash.key?("mode")
        data_hash[:ui__calendar_selected_date_value] = normalize_date(@selected) if @selected && !data_hash.key?(:ui__calendar_selected_date_value)
        data_hash[:ui__calendar_selected_dates_value] = normalize_date_list(@selected_dates) if @selected_dates && !data_hash.key?(:ui__calendar_selected_dates_value)
        data_hash[:ui__calendar_range_start_value] = normalize_date(@range_start) if @range_start && !data_hash.key?(:ui__calendar_range_start_value)
        data_hash[:ui__calendar_range_end_value] = normalize_date(@range_end) if @range_end && !data_hash.key?(:ui__calendar_range_end_value)
        data_hash[:ui__calendar_min_date_value] = normalize_date(@min_date) if @min_date && !data_hash.key?(:ui__calendar_min_date_value)
        data_hash[:ui__calendar_max_date_value] = normalize_date(@max_date) if @max_date && !data_hash.key?(:ui__calendar_max_date_value)
        data_hash[:ui__calendar_disabled_dates_value] = normalize_date_list(@disabled_dates) if @disabled_dates && !data_hash.key?(:ui__calendar_disabled_dates_value)
        dynamic_attrs[:data] = data_hash

        div(
          role: :region,
          aria: { label: "Calendar" },
          class: merged_classes,
          **dynamic_attrs,
        ) do
          yield self if block
        end
      end

      def header(**attrs, &block)
        render Header.new(**attrs), &block
      end

      def heading(**attrs, &block)
        render Heading.new(**attrs), &block
      end

      def nav(**attrs, &block)
        render Nav.new(**attrs), &block
      end

      def grid(**attrs, &block)
        render Grid.new(**attrs), &block
      end

      def head(**attrs, &block)
        render Head.new(**attrs), &block
      end

      def head_row(**attrs, &block)
        render HeadRow.new(**attrs), &block
      end

      def head_cell(**attrs, &block)
        render HeadCell.new(**attrs), &block
      end

      def body(**attrs, &block)
        render Body.new(**attrs), &block
      end

      def row(**attrs, &block)
        render Row.new(**attrs), &block
      end

      def cell(**attrs, &block)
        render Cell.new(**attrs), &block
      end

      def day(**attrs, &block)
        render Day.new(**attrs), &block
      end

      private

      def classes
        "p-3"
      end

      def normalize_date(value)
        case value
        when Date, Time, DateTime
          value.to_date.iso8601
        else
          value.to_s
        end
      end

      def normalize_date_list(values)
        return values.to_json if values.is_a?(Array)
        values.to_s
      end
    end

    # Calendar Header - navigation and month/year display
    class Calendar::Header < Components::Base
      def initialize(**attrs)
        @attrs = attrs
      end

      def view_template(&block)
        div(class: merged_classes, **attrs_without_class, &block)
      end

      private

      def classes
        "flex items-center justify-between pb-4"
      end
    end

    # Calendar Heading - month and year text
    class Calendar::Heading < Components::Base
      def initialize(**attrs)
        @attrs = attrs
      end

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
    class Calendar::Nav < Components::Base
      def initialize(**attrs)
        @attrs = attrs
      end

      def view_template(&block)
        div(class: merged_classes, **attrs_without_class, &block)
      end

      private

      def classes
        "flex items-center gap-1"
      end
    end

    # Calendar Grid - table of dates
    class Calendar::Grid < Components::Base
      def initialize(**attrs)
        @attrs = attrs
      end

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
    class Calendar::Head < Components::Base
      def initialize(**attrs)
        @attrs = attrs
      end

      def view_template(&block)
        thead(class: merged_classes, **attrs_without_class, &block)
      end

      private

      def classes
        ""
      end
    end

    # Calendar HeadRow - row of day names
    class Calendar::HeadRow < Components::Base
      def initialize(**attrs)
        @attrs = attrs
      end

      def view_template(&block)
        tr(class: merged_classes, **attrs_without_class, &block)
      end

      private

      def classes
        ""
      end
    end

    # Calendar HeadCell - individual day name cell
    class Calendar::HeadCell < Components::Base
      def initialize(**attrs)
        @attrs = attrs
      end

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
        "w-9 rounded-md text-center text-[0.8rem] font-normal text-muted-foreground"
      end
    end

    # Calendar Body - table body with dates
    class Calendar::Body < Components::Base
      def initialize(**attrs)
        @attrs = attrs
      end

      def view_template(&block)
        tbody(class: merged_classes, **attrs_without_class, &block)
      end

      private

      def classes
        "pt-2 text-center"
      end
    end

    # Calendar Row - week row
    class Calendar::Row < Components::Base
      def initialize(**attrs)
        @attrs = attrs
      end

      def view_template(&block)
        tr(class: merged_classes, **attrs_without_class, &block)
      end

      private

      def classes
        ""
      end
    end

    # Calendar Cell - individual date cell
    class Calendar::Cell < Components::Base
      def initialize(**attrs)
        @attrs = attrs
      end

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
    class Calendar::Day < Components::Base
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

    CalendarHeader = Calendar::Header
    CalendarHeading = Calendar::Heading
    CalendarNav = Calendar::Nav
    CalendarGrid = Calendar::Grid
    CalendarHead = Calendar::Head
    CalendarHeadRow = Calendar::HeadRow
    CalendarHeadCell = Calendar::HeadCell
    CalendarBody = Calendar::Body
    CalendarRow = Calendar::Row
    CalendarCell = Calendar::Cell
    CalendarDay = Calendar::Day
  end
end
