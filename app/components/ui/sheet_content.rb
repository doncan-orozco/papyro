# frozen_string_literal: true

module Components
  module Ui
    # Sheet Content - sliding panel
    class SheetContent < Components::Base
      def initialize(side: :right, labelledby_id: nil, describedby_id: nil, **attrs)
        @side = side # :top, :right, :bottom, :left
        @labelledby_id = labelledby_id
        @describedby_id = describedby_id
        @attrs = attrs
      end

      def view_template(&block)
        dynamic_attrs = attrs_without_class.dup

        aria_hash = dynamic_attrs[:aria] || {}
        aria_hash[:modal] = true unless aria_hash.key?(:modal) || aria_hash.key?("modal")

        if @labelledby_id && !aria_hash.key?(:labelledby) && !aria_hash.key?("labelledby")
          aria_hash[:labelledby] = @labelledby_id
        end

        if @describedby_id && !aria_hash.key?(:describedby) && !aria_hash.key?("describedby")
          aria_hash[:describedby] = @describedby_id
        end

        dynamic_attrs[:aria] = aria_hash

        # Add side data attribute
        data_hash = (dynamic_attrs[:data] || {}).dup
        data_hash[:side] = @side unless data_hash.key?(:side) || data_hash.key?("side")
        dynamic_attrs[:data] = data_hash

        div(
          role: :dialog,
          class: merged_classes,
          **dynamic_attrs,
          &block
        )
      end

      private

      def classes
        [
          "fixed z-50 gap-4 bg-background p-6 shadow-lg transition ease-in-out",
          "data-[state=open]:animate-in data-[state=closed]:animate-out data-[state=closed]:duration-300 data-[state=open]:duration-500",
          # Top side
          "data-[side=top]:inset-x-0 data-[side=top]:top-0 data-[side=top]:border-b",
          "data-[side=top]:data-[state=closed]:slide-out-to-top data-[side=top]:data-[state=open]:slide-in-from-top",
          # Bottom side
          "data-[side=bottom]:inset-x-0 data-[side=bottom]:bottom-0 data-[side=bottom]:border-t",
          "data-[side=bottom]:data-[state=closed]:slide-out-to-bottom data-[side=bottom]:data-[state=open]:slide-in-from-bottom",
          # Left side
          "data-[side=left]:inset-y-0 data-[side=left]:left-0 data-[side=left]:h-full data-[side=left]:w-3/4 data-[side=left]:border-r",
          "data-[side=left]:data-[state=closed]:slide-out-to-left data-[side=left]:data-[state=open]:slide-in-from-left",
          "data-[side=left]:sm:max-w-sm",
          # Right side
          "data-[side=right]:inset-y-0 data-[side=right]:right-0 data-[side=right]:h-full data-[side=right]:w-3/4 data-[side=right]:border-l",
          "data-[side=right]:data-[state=closed]:slide-out-to-right data-[side=right]:data-[state=open]:slide-in-from-right",
          "data-[side=right]:sm:max-w-sm"
        ].join(" ")
      end
    end
  end
end
