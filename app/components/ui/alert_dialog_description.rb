# frozen_string_literal: true

# Alert Dialog Description - description text for alert dialogs
# Following shadcn/ui Radix patterns
module Components
  module Ui
    class AlertDialogDescription < Components::Base
      def view_template(&block)
        p(class: merged_classes, **attrs_without_class, &block)
      end

      private

      def classes
        "text-sm text-muted-foreground"
      end
    end
  end
end
