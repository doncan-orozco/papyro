module Views
  module Registrations
    class New < Views::Base
      include Phlex::Rails::Helpers::ButtonTo

      def initialize(user:)
        @user = user
      end

      def view_template
        div(class: "relative min-h-screen bg-background flex items-center justify-center px-4 py-12") do
          link_to root_path(locale: I18n.locale),
            class: "absolute left-4 top-6 inline-flex items-center text-sm text-foreground/80 transition-colors hover:text-foreground hover:underline focus-visible:underline",
            data: { turbo_frame: "_top", turbo_action: "advance" } do
            plain "← #{t("views.registrations.new.back_to_home")}"
          end

          div(class: "w-full max-w-md space-y-6") do
            div(class: "flex justify-center") do
              link_to root_path(locale: I18n.locale), class: "group inline-flex shrink-0 items-center gap-3", data: { turbo_frame: "_top", turbo_action: "advance" } do
                span(
                  role: "img",
                  aria: { label: "Papyro" },
                  class: "size-7 shrink-0 bg-current text-foreground/80 transition-colors duration-500 ease-out group-hover:text-rose-600 dark:group-hover:text-rose-500 [mask-image:url('/icon.svg')] [mask-position:center] [mask-repeat:no-repeat] [mask-size:contain] [-webkit-mask-image:url('/icon.svg')] [-webkit-mask-position:center] [-webkit-mask-repeat:no-repeat] [-webkit-mask-size:contain]"
                )
                span(class: "text-sm font-semibold tracking-[0.16em] text-foreground/80 transition-colors duration-500 ease-out group-hover:text-rose-600 dark:group-hover:text-rose-500") { "PAPYRO" }
              end
            end

            render Components::Ui::Card.new(class: "w-full max-w-md") do |card|
              card.header do
                card.title { t("views.registrations.new.heading") }
                card.description { t("views.registrations.new.description") }
              end

              card.content do
                render_google_sign_up_button
                render_registration_form
              end

              card.footer do
                p(class: "text-xs text-foreground/80 text-center") do
                  plain "#{t("views.registrations.new.sign_in_prompt")} "
                  link_to t("views.registrations.new.sign_in"), new_session_path, class: "text-primary hover:underline font-medium"
                end
              end
            end
          end
        end
      end

      private

      def render_google_sign_up_button
        div(class: "space-y-4") do
          button_to "/auth/google_oauth2",
            method: :post,
            class: "w-full rounded-xl border border-border bg-background px-4 py-2.5 text-sm font-medium text-foreground shadow-sm transition hover:bg-accent hover:text-accent-foreground",
            data: { turbo: false } do
            span(class: "flex items-center justify-center gap-2") do
              svg(viewBox: "0 0 48 48", class: "size-4", aria: { hidden: true }) do |s|
                s.path(fill: "#EA4335", d: "M24 9.5c3.54 0 6.73 1.22 9.24 3.63l6.86-6.86C35.91 2.36 30.37 0 24 0 14.62 0 6.51 5.4 2.56 13.27l7.98 6.19C12.33 13.71 17.69 9.5 24 9.5z")
                s.path(fill: "#4285F4", d: "M46.98 24.55c0-1.57-.14-3.09-.4-4.55H24v9.02h12.94c-.56 2.98-2.25 5.5-4.78 7.2l7.73 6C44.38 38.09 46.98 31.82 46.98 24.55z")
                s.path(fill: "#FBBC05", d: "M10.54 28.64A14.5 14.5 0 0 1 9.76 24c0-1.61.28-3.18.78-4.64l-7.98-6.19A24.02 24.02 0 0 0 0 24c0 3.87.92 7.53 2.56 10.83l7.98-6.19z")
                s.path(fill: "#34A853", d: "M24 48c6.37 0 11.72-2.09 15.63-5.68l-7.73-6c-2.15 1.45-4.9 2.31-7.9 2.31-6.31 0-11.67-4.21-13.46-9.96l-7.98 6.19C6.51 42.6 14.62 48 24 48z")
              end
              span { t("views.registrations.new.sign_up_with_google") }
            end
          end

          div(class: "relative py-1") do
            div(class: "absolute inset-0 flex items-center", aria: { hidden: true }) do
              div(class: "w-full border-t border-border/70")
            end

            div(class: "relative flex justify-center") do
              span(class: "bg-card px-3 text-xs font-medium uppercase tracking-[0.12em] text-foreground/80") do
                plain t("views.registrations.new.continue_with_email_divider")
              end
            end
          end
        end
      end

      def render_registration_form
        form_with(model: @user, url: sign_up_path, class: "space-y-5", local: true) do |form|
          form.field :email_address,
            as: :email_field,
            label: t("views.registrations.new.email_label"),
            options: {
              required: true,
              autofocus: true,
              autocomplete: "username",
              placeholder: t("views.registrations.new.email_placeholder")
            }

          form.field :password,
            as: :password_field,
            label: t("views.registrations.new.password_label"),
            options: {
              required: true,
              autocomplete: "new-password",
              placeholder: t("views.registrations.new.password_placeholder"),
              maxlength: 72
            }

          form.submit t("views.registrations.new.submit"), class: "w-full"
        end
      end
    end
  end
end
