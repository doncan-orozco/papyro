# frozen_string_literal: true

# Toggle Group - multiple toggle buttons with single or multiple selection
# Following shadcn/ui Radix patterns with semantic tokens
# Note: Requires Stimulus controller for state management
module Components
  module Ui
    class ToggleGroup < Components::Base
      def initialize(type: :single, variant: :default, size: :default, **attrs)
        @type = type # :single or :multiple
        @variant = variant
        @size = size
        @attrs = attrs
      end

      def view_template(&block)
        dynamic_attrs = attrs_without_class.dup

        # Add data attributes for type
        data_hash = dynamic_attrs[:data] || {}
        data_hash[:type] = @type unless data_hash.key?(:type) || data_hash.key?("type")
        dynamic_attrs[:data] = data_hash

        div(
          role: :group,
          class: merged_classes,
          **dynamic_attrs,
          &block
        )
      end

      private

      def classes
        "inline-flex items-center justify-center gap-1"
      end
    end

    # Toggle Group Item - individual toggle within a group
    class ToggleGroupItem < Components::Base
      def initialize(value:, variant: :default, size: :default, **attrs)
        @value = value
        @variant = variant
        @size = size
        @attrs = attrs
      end

      def view_template(&block)
        dynamic_attrs = attrs_without_class.dup

        # Add value to data attributes
        data_hash = dynamic_attrs[:data] || {}
        data_hash[:value] = @value unless data_hash.key?(:value) || data_hash.key?("value")
        dynamic_attrs[:data] = data_hash

        # Render as Toggle with additional data
        render Components::Ui::Toggle.new(
          variant: @variant,
          size: @size,
          **dynamic_attrs,
          &block
        )
      end
    end
  end
end
