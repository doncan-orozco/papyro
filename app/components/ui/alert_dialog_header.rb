# frozen_string_literal: true

# Alert Dialog Header - header section for alert dialogs
# Following shadcn/ui Radix patterns
module Components
  module Ui
    class AlertDialogHeader < Components::Base
      def view_template(&block)
        div(class: merged_classes, **attrs_without_class, &block)
      end

      private

      def classes
        "flex flex-col space-y-2 text-center sm:text-left"
      end
    end
  end
end
