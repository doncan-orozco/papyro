# frozen_string_literal: true

# Alert Dialog Overlay - backdrop for alert dialogs
# Following shadcn/ui Radix patterns with semantic tokens
module Components
  module Ui
    class AlertDialogOverlay < Components::Base
      def initialize(**attrs)
        @attrs = attrs
      end

      def view_template
        div(class: merged_classes, **attrs_without_class)
      end

      private

      def classes
        [
          "fixed inset-0 z-50",
          "bg-black/80",
          "data-[state=open]:animate-in data-[state=closed]:animate-out",
          "data-[state=closed]:fade-out-0 data-[state=open]:fade-in-0"
        ].join(" ")
      end
    end
  end
end
