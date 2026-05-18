module Views
  module Sessions
    class New < Views::Base
      def initialize(user:)
        @user = user
      end

      def view_template
        div(class: "relative min-h-screen bg-background flex items-center justify-center px-4 py-12") do
          link_to root_path(locale: I18n.locale),
            class: "absolute left-4 top-6 inline-flex items-center text-sm text-muted-foreground transition-colors hover:text-foreground",
            data: { turbo_frame: "_top", turbo_action: "advance" } do
            plain "← #{t("views.sessions.new.back_to_home")}"
          end

          div(class: "w-full max-w-md space-y-6") do
            div(class: "flex justify-center") do
              link_to root_path(locale: I18n.locale), class: "group inline-flex shrink-0 items-center gap-3", data: { turbo_frame: "_top", turbo_action: "advance" } do
                span(
                  role: "img",
                  aria: { label: "Papyro" },
                  class: "size-7 shrink-0 bg-current text-foreground/70 transition-colors duration-500 ease-out group-hover:text-rose-600 dark:group-hover:text-rose-500 [mask-image:url('/icon.svg')] [mask-position:center] [mask-repeat:no-repeat] [mask-size:contain] [-webkit-mask-image:url('/icon.svg')] [-webkit-mask-position:center] [-webkit-mask-repeat:no-repeat] [-webkit-mask-size:contain]"
                )
                span(class: "text-sm font-semibold tracking-[0.16em] text-foreground/70 transition-colors duration-500 ease-out group-hover:text-rose-600 dark:group-hover:text-rose-500") { "PAPYRO" }
              end
            end

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
                  plain "#{t("views.sessions.new.forgot_password_prompt")} "
                  link_to t("views.sessions.new.forgot_password"), new_password_path, class: "text-primary hover:underline font-medium"
                end
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
