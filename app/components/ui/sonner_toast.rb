# frozen_string_literal: true

# Sonner toast notification (uses Toast component)
module Components
  module Ui
    class SonnerToast < Components::Base
      def initialize(variant: :default, **attrs)
        @variant = variant
        @attrs = attrs
      end

      def view_template(&block)
        render Components::Ui::Toast.new(variant: @variant, **@attrs, &block)
      end
    end
  end
end
