# frozen_string_literal: true

# Alert Dialog Action - confirm/action button wrapper
# Following shadcn/ui Radix patterns
# This is typically just a Button component with default styling
module Components
  module Ui
    class AlertDialogAction < Components::Base
      def initialize(**attrs)
        @attrs = attrs
      end

      def view_template(&block)
        # AlertDialogAction is typically just a Button component
        render Components::Ui::Button.new(**@attrs, &block)
      end
    end
  end
end
