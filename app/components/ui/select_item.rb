# frozen_string_literal: true

# Select item following shadcn/ui Radix patterns
# Note: Requires Stimulus controller for full interactivity
module Components
  module Ui
    class SelectItem < Components::Base
      def initialize(value:, **attrs)
        @value = value
        @attrs = attrs
      end

      def view_template(&block)
        merged_data = (@attrs[:data] || {}).merge(value: @value)

        div(
          role: :option,
          data: merged_data,
          class: merged_classes,
          **attrs_without_class.except(:data)
        ) do
          span(class: "absolute right-2 flex h-3.5 w-3.5 items-center justify-center") do
            render Components::Ui::Icon.new(
              :check,
              source: :lucide,
              class: "h-4 w-4 hidden data-[selected=true]:inline",
              data: { ui__select_checkmark: true }
            )
          end
          span(&block)
        end
      end

      private

      def classes
        [
          "relative flex w-full cursor-default select-none items-center",
          "rounded-sm py-1.5 pl-2 pr-8 text-sm outline-none",
          "hover:bg-accent hover:text-accent-foreground",
          "data-[disabled]:pointer-events-none data-[disabled]:opacity-50"
        ].join(" ")
      end
    end
  end
end
