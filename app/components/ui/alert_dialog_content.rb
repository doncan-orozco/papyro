# frozen_string_literal: true

# Alert Dialog Content - main content container for alert dialogs
# Following shadcn/ui Radix patterns with semantic tokens
# Note: Requires Stimulus controller for full interactivity
module Components
  module Ui
    class AlertDialogContent < Components::Base
      def initialize(labelledby_id: nil, describedby_id: nil, **attrs)
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

        div(
          role: :alertdialog,
          class: merged_classes,
          **dynamic_attrs,
          &block
        )
      end

      private

      def classes
        [
          "fixed left-[50%] top-[50%] z-50",
          "grid w-full max-w-lg translate-x-[-50%] translate-y-[-50%] gap-4",
          "border border-border bg-background p-6 shadow-lg",
          "transition-all duration-200",
          "data-[state=open]:animate-in data-[state=closed]:animate-out",
          "data-[state=closed]:fade-out-0 data-[state=open]:fade-in-0",
          "data-[state=closed]:zoom-out-95 data-[state=open]:zoom-in-95",
          "data-[state=closed]:slide-out-to-left-1/2 data-[state=closed]:slide-out-to-top-[48%]",
          "data-[state=open]:slide-in-from-left-1/2 data-[state=open]:slide-in-from-top-[48%]",
          "sm:rounded-lg"
        ].join(" ")
      end
    end
  end
end
