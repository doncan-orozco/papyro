# frozen_string_literal: true

# Alert Dialog Cancel - cancel button wrapper
# Following shadcn/ui Radix patterns
# This is typically a Button with outline variant
module Components
  module Ui
    class AlertDialogCancel < Components::Base
      def initialize(**attrs)
        @attrs = attrs
      end

      def view_template(&block)
        # AlertDialogCancel is typically a Button with outline variant
        attrs_with_variant = @attrs.merge(variant: @attrs[:variant] || :outline)
        render Components::Ui::Button.new(**attrs_with_variant, &block)
      end
    end
  end
end
