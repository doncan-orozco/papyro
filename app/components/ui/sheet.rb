# frozen_string_literal: true

# Sheet - slide-in panel component (Dialog variant)
# Following shadcn/ui Radix patterns with semantic tokens
# Note: Requires Stimulus controller for animation and focus management
module Components
  module Ui
    # Sheet root container
    class Sheet < Components::Base
      def initialize(**attrs)
        @attrs = attrs
      end

      def view_template(&block)
        div(class: merged_classes, **attrs_without_class, &block)
      end

      private

      def classes
        ""
      end
    end
  end
end
