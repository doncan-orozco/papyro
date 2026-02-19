# frozen_string_literal: true

# Alert Dialog Title - title element for alert dialogs
# Following shadcn/ui Radix patterns
module Components
  module Ui
    class AlertDialogTitle < Components::Base
      def view_template(&block)
        h2(class: merged_classes, **attrs_without_class, &block)
      end

      private

      def classes
        "text-lg font-semibold"
      end
    end
  end
end
