# frozen_string_literal: true

# Dialog close button following shadcn/ui Radix patterns
# Uses semantic tokens for theming
module Components
  module Ui
    class DialogClose < Components::Base
      def initialize(**attrs)
        @attrs = attrs
      end

      def view_template(&block)
        button(
          type: :button,
          class: merged_classes,
          **attrs_without_class,
          &block
        )
      end

      private

      def classes
        # matches the React close-button styles from dialog.tsx
        [
          "absolute right-4 top-4 rounded-sm opacity-70 ring-offset-background",
          "transition-opacity hover:opacity-100",
          "focus:outline-none focus:ring-2 focus:ring-ring focus:ring-offset-2",
          "disabled:pointer-events-none",
          "data-[state=open]:bg-accent data-[state=open]:text-muted-foreground"
        ].join(" ")
      end
    end
  end
end
