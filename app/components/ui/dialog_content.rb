# frozen_string_literal: true

# Dialog content container following shadcn/ui Radix patterns
# Uses semantic tokens for theming
# Note: Requires Stimulus controller for full interactivity
module Components
  module Ui
    class DialogContent < Components::Base
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
          role: :dialog,
          class: merged_classes,
          **dynamic_attrs
        ) do
          # render whatever the caller passed (title, description, footer, etc.)
          yield

          # built‑in close button (same placement as React)
          render Components::Ui::DialogClose.new(
            data: { action: "click->ui--dialog#close" }
          ) do
            svg(
              xmlns: "http://www.w3.org/2000/svg",
              viewBox: "0 0 24 24",
              fill: "none",
              stroke: "currentColor",
              class: "h-4 w-4"
            ) do |s|
              s.path(d: "M6 18L18 6M6 6l12 12", stroke_width: 2, stroke_linecap: "round", stroke_linejoin: "round")
            end
            span(class: "sr-only") { I18n.t("design_system.catalog.overlays.dialog.close") }
          end
        end
      end

      private

      def classes
        # add the same animation helpers that React uses so the modal fades/zooms
        # also give open/close durations so the transition is easier to perceive
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
          "data-[state=open]:duration-500 data-[state=closed]:duration-300",
          "sm:rounded-lg"
        ].join(" ")
      end
    end
  end
end
