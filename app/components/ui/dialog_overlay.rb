# frozen_string_literal: true

# Dialog overlay following shadcn/ui Radix patterns
# Uses semantic tokens for theming
# Note: Requires Stimulus controller for full interactivity
module Components
  module Ui
    class DialogOverlay < Components::Base
      def initialize(**attrs)
        @attrs = attrs
      end

      def view_template
        div(
          class: merged_classes,
          **attrs_without_class
        )
      end

      private

      def classes
        # copy of React's overlay utility classes, including animation data-state helpers
        # include state‑specific duration so the fade is noticeable
        [
          "fixed inset-0 z-50 bg-black/80",
          "data-[state=open]:animate-in data-[state=closed]:animate-out",
          "data-[state=closed]:fade-out-0 data-[state=open]:fade-in-0",
          "data-[state=open]:duration-500 data-[state=closed]:duration-300"
        ].join(" ")
      end
    end
  end
end
