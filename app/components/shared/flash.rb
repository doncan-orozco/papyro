# frozen_string_literal: true

# The layout's Sonner Toaster. Flash notices and alerts become success and error
# toasts with the localized app.toasts.* titles; Turbo Streams can append more
# toasts to it (`turbo_stream.append "toaster", Chadcn::Sonner::Toast.new(...)`).
#
# Usage (once per layout):
#   render Components::Shared::Flash.new(flash: flash)
module Components
  module Shared
    class Flash < Components::Base
      DURATION_MS = 4000
      TOAST_TYPES = { notice: { type: :success, title_key: "success" }, alert: { type: :error, title_key: "error" } }.freeze

      def initialize(flash:, **attrs)
        @flash = flash
        @attrs = attrs
      end

      def view_template
        render Chadcn::Toaster.new(
          position: "bottom-right",
          close_button: true,
          duration: DURATION_MS,
          toast_options: { close_button_aria_label: t("app.toasts.close") },
          toasts: toasts,
          **@attrs
        )
      end

      private

      def toasts
        TOAST_TYPES.flat_map do |key, toast|
          Array(@flash[key]).compact_blank.map do |message|
            { type: toast[:type], title: t("app.toasts.#{toast[:title_key]}"), description: message.to_s }
          end
        end
      end
    end
  end
end
