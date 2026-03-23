# frozen_string_literal: true

module Views
  module Admin
    module Sessions
      class New < Views::Base
        def initialize(form:)
          @form = form
        end

        def view_template
          div(class: "min-h-screen bg-background flex items-center justify-center px-4 py-12") do
            render Components::Ui::Card.new(class: "w-full max-w-md") do |card|
              card.header do
                card.title { t("admin.sessions.new.heading") }
                card.description { t("admin.sessions.new.description", default: "Admin authentication") }
              end

              card.content do
                render_flash_messages
                render_login_form
              end
            end
          end
        end

        private

        def render_flash_messages
          return unless (alert = view_context.flash[:alert])

          render Components::Ui::Alert.new(variant: :destructive, class: "mb-4") do
            p(class: "text-sm") { alert }
          end
        end

        def render_login_form
          form_with(model: @form, url: admin_session_path, method: :post, class: "space-y-5", local: true) do |form|
            form.field :email_address,
              as: :email_field,
              label: t("admin.sessions.new.email_label", default: "Email Address"),
              options: {
                required: true,
                autofocus: true,
                autocomplete: "username",
                placeholder: t("admin.sessions.new.email_placeholder")
              }

            form.field :password,
              as: :password_field,
              label: t("admin.sessions.new.password_label", default: "Password"),
              options: {
                required: true,
                autocomplete: "current-password",
                placeholder: t("admin.sessions.new.password_placeholder"),
                maxlength: 72
              }

            form.submit t("admin.sessions.new.submit"), class: "w-full"
          end
        end
      end
    end
  end
end
