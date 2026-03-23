# frozen_string_literal: true

# Data Table - enhanced table with sorting, filtering, and pagination
# Following shadcn/ui Radix patterns with semantic tokens
# Note: This is a wrapper around the existing Table component with added functionality
# Requires Stimulus controller for sorting, filtering, and pagination
module Components
  module Ui
    # Data Table root container
    class DataTable < Components::Base
      def initialize(sortable: false, filterable: false, paginated: false, **attrs)
        @sortable = sortable
        @filterable = filterable
        @paginated = paginated
        @attrs = attrs
      end

      def view_template(&block)
        dynamic_attrs = attrs_without_class.dup

        # Add data attributes for features
        data_hash = (dynamic_attrs[:data] || {}).dup
        data_hash[:sortable] = @sortable if @sortable
        data_hash[:filterable] = @filterable if @filterable
        data_hash[:paginated] = @paginated if @paginated
        dynamic_attrs[:data] = data_hash

        div(
          class: merged_classes,
          **dynamic_attrs,
        ) do
          yield self if block
        end
      end

      def toolbar(**attrs, &block)
        render Toolbar.new(**attrs), &block
      end

      def header(**attrs, &block)
        render Header.new(**attrs), &block
      end

      def pagination(**attrs, &block)
        render Pagination.new(**attrs), &block
      end

      def row_actions(**attrs, &block)
        render RowActions.new(**attrs), &block
      end

      def view_options(**attrs, &block)
        render ViewOptions.new(**attrs), &block
      end

      private

      def classes
        "w-full space-y-4"
      end
    end

    # Data Table Toolbar - filter and action controls
    class DataTable::Toolbar < Components::Base
      def view_template(&block)
        div(class: merged_classes, **attrs_without_class, &block)
      end

      private

      def classes
        "flex items-center justify-between"
      end
    end

    # Data Table Header - sortable column header
    class DataTable::Header < Components::Base
      def initialize(sortable: false, sort_direction: nil, **attrs)
        @sortable = sortable
        @sort_direction = sort_direction # :asc, :desc, or nil
        @attrs = attrs
      end

      def view_template(&block)
        if @sortable
          dynamic_attrs = attrs_without_class.dup
          data_hash = (dynamic_attrs[:data] || {}).dup

          unless data_hash.key?(:sortable) || data_hash.key?("sortable")
            data_hash[:sortable] = true
          end

          unless data_hash.key?(:sort_direction) || data_hash.key?("sort_direction")
            data_hash[:sort_direction] = @sort_direction
          end

          dynamic_attrs[:data] = data_hash

          button(
            type: :button,
            class: merged_classes,
            **dynamic_attrs,
            &block
          )
        else
          span(class: merged_classes, **attrs_without_class, &block)
        end
      end

      private

      def classes
        if @sortable
          [
            "flex items-center space-x-2",
            "-ml-3 h-12 px-2 hover:bg-accent hover:text-accent-foreground",
            "data-[sort-direction=asc]:text-accent-foreground",
            "data-[sort-direction=desc]:text-accent-foreground"
          ].join(" ")
        else
          ""
        end
      end
    end

    # Data Table Pagination - pagination controls
    class DataTable::Pagination < Components::Base
      def view_template(&block)
        div(class: merged_classes, **attrs_without_class, &block)
      end

      private

      def classes
        "flex items-center justify-between px-2"
      end
    end

    # Data Table Row Actions - action buttons for rows
    class DataTable::RowActions < Components::Base
      def view_template(&block)
        div(class: merged_classes, **attrs_without_class, &block)
      end

      private

      def classes
        "flex items-center gap-2"
      end
    end

    # Data Table View Options - column visibility toggle
    class DataTable::ViewOptions < Components::Base
      def view_template(&block)
        render Components::Ui::DropdownMenu::Trigger.new(**attrs_without_class) do
          render Components::Ui::Button.new(variant: :outline, size: :sm) do
            # Columns icon
            svg(
              class: "mr-2 h-4 w-4",
              xmlns: "http://www.w3.org/2000/svg",
              width: 24,
              height: 24,
              viewBox: "0 0 24 24",
              fill: "none",
              stroke: "currentColor",
              stroke_width: 2,
              stroke_linecap: "round",
              stroke_linejoin: "round"
            ) do |s|
              s.rect(x: 3, y: 3, width: 18, height: 18, rx: 2, ry: 2)
              s.line(x1: 12, y1: 3, x2: 12, y2: 21)
            end
            plain "View"
          end
        end
      end
    end

    DataTableToolbar = DataTable::Toolbar
    DataTableHeader = DataTable::Header
    DataTablePagination = DataTable::Pagination
    DataTableRowActions = DataTable::RowActions
    DataTableViewOptions = DataTable::ViewOptions

  end
end
