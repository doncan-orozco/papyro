# frozen_string_literal: true

# Slider - range input component
# Following shadcn/ui Radix patterns with semantic tokens
# Note: Requires Stimulus controller for value management and dragging
module Components
  module Ui
    # Slider root container
    class Slider < Components::Base
      def initialize(min: 0, max: 100, step: 1, value: nil, **attrs)
        @min = min
        @max = max
        @step = step
        @value = value || min
        @attrs = attrs
      end

      def view_template(&block)
        dynamic_attrs = attrs_without_class.dup

        # Add data attributes for configuration
        data_hash = dynamic_attrs[:data] || {}
        data_hash[:min] = @min unless data_hash.key?(:min) || data_hash.key?("min")
        data_hash[:max] = @max unless data_hash.key?(:max) || data_hash.key?("max")
        data_hash[:step] = @step unless data_hash.key?(:step) || data_hash.key?("step")
        data_hash[:value] = @value unless data_hash.key?(:value) || data_hash.key?("value")
        dynamic_attrs[:data] = data_hash

        # Add role for accessibility
        dynamic_attrs[:role] = :slider unless dynamic_attrs.key?(:role) || dynamic_attrs.key?("role")

        # Add aria attributes
        aria_hash = dynamic_attrs[:aria] || {}
        aria_hash[:valuemin] = @min unless aria_hash.key?(:valuemin) || aria_hash.key?("valuemin")
        aria_hash[:valuemax] = @max unless aria_hash.key?(:valuemax) || aria_hash.key?("valuemax")
        aria_hash[:valuenow] = @value unless aria_hash.key?(:valuenow) || aria_hash.key?("valuenow")
        dynamic_attrs[:aria] = aria_hash

        div(
          class: merged_classes,
          tabindex: 0,
          **dynamic_attrs,
          &block
        )
      end

      private

      def classes
        [
          "relative flex w-full touch-none select-none items-center",
          "group",
          "focus-visible:outline-none"
        ].join(" ")
      end
    end

    # Slider Track - background track
    class SliderTrack < Components::Base
      def view_template(&block)
        div(class: merged_classes, **attrs_without_class, &block)
      end

      private

      def classes
        "relative h-2 w-full grow overflow-hidden rounded-full bg-secondary"
      end
    end

    # Slider Range - filled portion of track
    class SliderRange < Components::Base
      def view_template
        div(class: merged_classes, **attrs_without_class)
      end

      private

      def classes
        "absolute h-full bg-primary"
      end
    end

    # Slider Thumb - draggable handle
    class SliderThumb < Components::Base
      def view_template
        div(class: merged_classes, **attrs_without_class)
      end

      private

      def classes
        [
          "block h-5 w-5 rounded-full border-2 border-primary bg-background",
          "ring-offset-background",
          "transition-colors",
          "focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2",
          "disabled:pointer-events-none disabled:opacity-50"
        ].join(" ")
      end
    end
  end
end
