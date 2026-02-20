# frozen_string_literal: true

# Sonner toaster - notification container with stacking
module Components
  module Ui
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
          "data-[position=top-left]:left-0 data-[position=top-left]:top-0",
          "data-[position=top-right]:right-0 data-[position=top-right]:top-0",
          "data-[position=top-center]:left-1/2 data-[position=top-center]:top-0 data-[position=top-center]:-translate-x-1/2",
          "data-[position=bottom-left]:bottom-0 data-[position=bottom-left]:left-0",
          "data-[position=bottom-right]:bottom-0 data-[position=bottom-right]:right-0",
          "data-[position=bottom-center]:bottom-0 data-[position=bottom-center]:left-1/2 data-[position=bottom-center]:-translate-x-1/2"
        ].join(" ")
      end
    end
  end
end
