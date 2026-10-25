# frozen_string_literal: true

# The layout's Sonner Toaster. Flash notices and alerts become success and error
# toasts with the localized app.toasts.* titles; Turbo Streams can append more
# toasts to it (`turbo_stream.append "toaster", Chadcn::Sonner::Toast.new(...)`).
#
# Usage (once per layout; `suppressed:` keeps the Toaster mounted but drops the
# messages, for pages that call disable_layout_flash_messages):
#   render Components::Shared::Flash.new(flash: flash, suppressed: content_for?(:flash))
module Components
  module Shared
    class Flash < Components::Base
      DURATION_MS = 4000
      # the gem's flash: option titles toasts with the raw message; these keep the localized titles
      TOAST_KINDS = {
        notice: { type: :success, title: "app.toasts.success" },
        alert: { type: :error, title: "app.toasts.error" }
      }.freeze
      private_constant :TOAST_KINDS

      def initialize(flash:, suppressed: false, **attrs)
        @flash = suppressed ? {} : flash
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
        TOAST_KINDS.flat_map do |key, kind|
          Array(@flash[key]).compact_blank.map do |message|
            { type: kind[:type], title: t(kind[:title]), description: message.to_s }
          end
        end
      end
    end
  end
end
