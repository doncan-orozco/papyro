# frozen_string_literal: true

# Date Picker - combined calendar and input component
# Following shadcn/ui Radix patterns with semantic tokens
# Note: Requires Stimulus controller for calendar interaction and date formatting
module Components
  module Ui
    # Date Picker root container
    class DatePicker < Components::Base
      def initialize(value: nil, placeholder: nil, **attrs)
        @value = value
        @placeholder = placeholder || "Pick a date"
        @attrs = attrs
      end

      def view_template(&block)
        render Components::Ui::Popover.new(**attrs_without_class) do
          # Trigger button
          render Components::Ui::PopoverTrigger.new(
            class: "w-[280px] justify-start text-left font-normal"
          ) do
            # Calendar icon
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
              s.rect(x: 3, y: 4, width: 18, height: 18, rx: 2, ry: 2)
              s.line(x1: 16, y1: 2, x2: 16, y2: 6)
              s.line(x1: 8, y1: 2, x2: 8, y2: 6)
              s.line(x1: 3, y1: 10, x2: 21, y2: 10)
            end

            span(class: @value ? "" : "text-muted-foreground") do
              @value || @placeholder
            end
          end

          # Popover content with calendar
          render Components::Ui::PopoverContent.new(
            class: "w-auto p-0",
            align: "start"
          ) do
            if block
              yield
            else
              render Components::Ui::Calendar.new(mode: :single)
            end
          end
        end
      end

      private

      def classes
        ""
      end
    end
  end
end
