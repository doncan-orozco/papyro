# frozen_string_literal: true

# Radio Group - enhanced radio button group with better layout
# Following shadcn/ui Radix patterns with semantic tokens
# Note: Requires Stimulus controller for state management
module Components
  module Ui
    # Radio Group root container
    class RadioGroup < Components::Base
      def initialize(name: nil, value: nil, **attrs)
        @name = name
        @value = value
        @attrs = attrs
      end

      def view_template(&block)
        dynamic_attrs = attrs_without_class.dup

        # Add role for accessibility
        dynamic_attrs[:role] = :radiogroup unless dynamic_attrs.key?(:role) || dynamic_attrs.key?("role")

        div(
          class: merged_classes,
          **dynamic_attrs,
          &block
        )
      end

      private

      def classes
        "grid gap-2"
      end
    end

    # Radio Group Item - individual radio button
    class RadioGroupItem < Components::Base
      def initialize(value:, id: nil, name: nil, checked: false, **attrs)
        @value = value
        @id = id || "radio-#{value}"
        @name = name
        @checked = checked
        @attrs = attrs
      end

      def view_template
        dynamic_attrs = attrs_without_class.dup

        # Set aria-checked for accessibility
        aria_hash = dynamic_attrs[:aria] || {}
        aria_hash[:checked] = @checked unless aria_hash.key?(:checked) || aria_hash.key?("checked")
        dynamic_attrs[:aria] = aria_hash

        # Set data-state for CSS styling
        unless dynamic_attrs.key?(:"data-state") || dynamic_attrs.key?("data-state")
          dynamic_attrs[:"data-state"] = @checked ? "checked" : "unchecked"
        end

        button(
          type: :button,
          role: :radio,
          id: @id,
          class: merged_classes,
          **dynamic_attrs
        ) do
          # Radio indicator (circle)
          span(class: indicator_classes) do
            # Inner dot when checked
            span(class: "h-2 w-2 rounded-full bg-current")
          end
        end
      end

      private

      def classes
        [
          "aspect-square h-4 w-4 rounded-full border border-primary text-primary",
          "ring-offset-background",
          "focus:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2",
          "disabled:cursor-not-allowed disabled:opacity-50"
        ].join(" ")
      end

      def indicator_classes
        [
          "flex items-center justify-center",
          "data-[state=unchecked]:invisible data-[state=checked]:visible"
        ].join(" ")
      end
    end

    # Radio Group Label - label for radio group items
    class RadioGroupLabel < Components::Base
      def initialize(for_id: nil, **attrs)
        @for_id = for_id
        @attrs = attrs
      end

      def view_template(&block)
        dynamic_attrs = attrs_without_class.dup
        dynamic_attrs[:for] = @for_id if @for_id

        label(
          class: merged_classes,
          **dynamic_attrs,
          &block
        )
      end

      private

      def classes
        [
          "text-sm font-medium leading-none",
          "peer-disabled:cursor-not-allowed peer-disabled:opacity-70"
        ].join(" ")
      end
    end
  end
end
