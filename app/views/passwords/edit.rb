module Views
  module Passwords
    class Edit < Views::Base
      def initialize(token:, form:)
        @token = token
        @form = form
      end

      def view_template
        div(class: "min-h-screen bg-background flex items-center justify-center px-4 py-12") do
          render Components::Ui::Card.new(class: "w-full max-w-md") do
            render Components::Ui::CardHeader.new do
              render Components::Ui::CardTitle.new { t(".heading") }
              render Components::Ui::CardDescription.new { t(".description", default: "Enter your new password") }
            end

            render Components::Ui::CardContent.new do
              render_flash_messages
              render_form
            end
          end
        end
      end

      private

      def render_form
        form_with(model: @form, url: password_path(@token), method: :put, class: "contents") do |form|
          div(class: "space-y-4") do
            form.field :password,
              as: :password_field,
              label: t(".password_label", default: "Password"),
              options: {
                required: true,
                autocomplete: "new-password",
                placeholder: t(".password_placeholder"),
                maxlength: 72
              }

            form.field :password_confirmation,
              as: :password_field,
              label: t(".password_confirmation_label", default: "Confirm Password"),
              options: {
                required: true,
                autocomplete: "new-password",
                placeholder: t(".password_confirmation_placeholder"),
                maxlength: 72
              }

            form.submit t(".submit"), class: "w-full"
          end
        end
      end

      def render_flash_messages
        if alert = view_context.flash[:alert]
          render Components::Ui::Alert.new(variant: :destructive, class: "mb-4") do
            p(class: "text-sm") { alert }
          end
        end
      end
    end
  end
end
