module Views
  module Sessions
    class New < Views::Base
      def initialize(user:)
        @user = user
      end

      def view_template
        div(class: "min-h-screen bg-background flex items-center justify-center px-4 py-12") do
          render Components::Ui::Card.new(class: "w-full max-w-md") do |card|
            card.header do
              card.title { t("views.sessions.new.heading") }
              card.description { t("views.sessions.new.description") }
            end

            card.content do
              render_login_form
            end

            card.footer do
              p(class: "text-xs text-muted-foreground text-center") do
                plain t("views.sessions.new.forgot_password_prompt")
                link_to t("views.sessions.new.forgot_password"), new_password_path, class: "text-primary hover:underline font-medium"
              end
            end
          end
        end
      end

      private

      def render_login_form
        form_with(model: @user, url: session_path, class: "space-y-5", local: true) do |form|
          form.field :email_address,
            as: :email_field,
            label: t("views.sessions.new.email_label"),
            options: {
              required: true,
              autofocus: true,
              autocomplete: "username",
              placeholder: t("views.sessions.new.email_placeholder")
            }

          form.field :password,
            as: :password_field,
            label: t("views.sessions.new.password_label"),
            options: {
              required: true,
              autocomplete: "current-password",
              placeholder: t("views.sessions.new.password_placeholder"),
              maxlength: 72
            }

          form.submit t("views.sessions.new.submit"), class: "w-full"
        end
      end
    end
  end
end
