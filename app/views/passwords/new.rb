module Views
  module Passwords
    class New < Views::Base
      def initialize(user:)
        @user = user
      end

      def view_template
        div(class: "min-h-screen bg-background flex items-center justify-center px-4 py-12") do
          render Components::Ui::Card.new(class: "w-full max-w-md") do |card|
            card.header do
              card.title { t("views.passwords.new.heading") }
              card.description { t("views.passwords.new.description", default: "Reset your password") }
            end

            card.content do
              render_flash_messages
              render_password_reset_form
            end
          end
        end
      end

      private

      def render_password_reset_form
        form_with(model: @user, url: passwords_path, class: "space-y-5", local: true) do |form|
          form.field :email_address,
            as: :email_field,
            label: t("views.passwords.new.email_label", default: "Email Address"),
            options: {
              required: true,
              autofocus: true,
              autocomplete: "username",
              placeholder: t("views.passwords.new.email_placeholder")
            }

          p(class: "text-xs text-muted-foreground") do
            t("views.passwords.new.instruction", default: "We will send you an email with instructions to reset your password.")
          end

          form.submit t("views.passwords.new.submit"), class: "w-full"
        end
      end

      def render_flash_messages
        if alert = view_context.flash[:alert]
          render Components::Ui::Alert.new(variant: :destructive, class: "mb-4") do
            render Components::Ui::Icon.new(:alert_circle, class: "h-4 w-4")
            p(id: "alert") { alert }
          end
        end
      end
    end
  end
end
