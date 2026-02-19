# frozen_string_literal: true

# Sonner - toast notification system with stacking
# Following shadcn/ui patterns (using sonner library approach)
# Note: This is an alternative implementation to the Toast component
# Requires Stimulus controller for toast queue management
module Components
  module Ui
    # Sonner Toast - individual notification (uses Toast component)
    class SonnerToast < Components::Base
      def initialize(variant: :default, **attrs)
        @variant = variant
        @attrs = attrs
      end

      def view_template(&block)
        render Components::Ui::Toast.new(variant: @variant, **@attrs, &block)
      end
    end

    # Sonner Toaster - notification container with stacking
    class SonnerToaster < Components::Base
      def initialize(position: :bottom_right, **attrs)
        @position = position # :top_left, :top_right, :bottom_left, :bottom_right, :top_center, :bottom_center
        @attrs = attrs
      end

      def view_template(&block)
        dynamic_attrs = attrs_without_class.dup
        data_hash = (dynamic_attrs[:data] || {}).dup

        unless data_hash.key?(:position) || data_hash.key?("position")
          data_hash[:position] = @position
        end

        dynamic_attrs[:data] = data_hash

        div(
          role: :region,
          aria: { label: "Notifications" },
          class: merged_classes,
          **dynamic_attrs,
          &block
        )
      end

      private

      def classes
        [
          "fixed z-[100] flex max-h-screen w-full flex-col gap-2 p-4 md:max-w-[420px]",
          # Position variants
          "data-[position=top_left]:left-0 data-[position=top_left]:top-0",
          "data-[position=top_right]:right-0 data-[position=top_right]:top-0",
          "data-[position=top_center]:left-1/2 data-[position=top_center]:top-0 data-[position=top_center]:-translate-x-1/2",
          "data-[position=bottom_left]:bottom-0 data-[position=bottom_left]:left-0",
          "data-[position=bottom_right]:bottom-0 data-[position=bottom_right]:right-0",
          "data-[position=bottom_center]:bottom-0 data-[position=bottom_center]:left-1/2 data-[position=bottom_center]:-translate-x-1/2"
        ].join(" ")
      end
    end
  end
end
