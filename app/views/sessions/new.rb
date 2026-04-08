module Views
  module Sessions
    class New < Views::Base
      def initialize(form:)
        @form = form
      end

      def view_template
        disable_layout_flash_messages

        div(class: "min-h-screen bg-background flex items-center justify-center px-4 py-12") do
          render Components::Ui::Card.new(class: "w-full max-w-md") do |card|
            card.header do
              card.title { t("views.sessions.new.heading") }
              card.description { t("views.sessions.new.description") }
            end

            card.content do
              render_flash_messages
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
        form_with(model: @form, url: session_path, class: "space-y-5", local: true) do |form|
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

      def render_flash_messages
        if alert = view_context.flash[:alert]
          render Components::Ui::Alert.new(variant: :destructive, class: "mb-4") do
            svg(class: "h-4 w-4", fill: "none", stroke: "currentColor", viewbox: "0 0 24 24") do |s|
              s.path(stroke_linecap: "round", stroke_linejoin: "round", stroke_width: "2", d: "M12 8v4m0 4v.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z")
            end
            div(class: "flex flex-col gap-2") do
              p(class: "font-semibold") { alert }
            end
          end
        end

        if notice = view_context.flash[:notice]
          render Components::Ui::Alert.new(class: "mb-4 border-green-600 bg-green-50 text-green-900") do
            svg(class: "h-4 w-4 text-green-600", fill: "none", stroke: "currentColor", viewbox: "0 0 24 24") do |s|
              s.path(stroke_linecap: "round", stroke_linejoin: "round", stroke_width: "2", d: "M9 12l2 2m0 0l4-4m-16 6v7a2 2 0 002 2h12a2 2 0 002-2v-7")
            end
            p { notice }
          end
        end
      end
    end
  end
end
