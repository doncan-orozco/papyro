# frozen_string_literal: true

module Views
  module Settings
    module Security
      class Edit < Views::Base
        include Phlex::Rails::Helpers::FormWith

        def initialize(user:)
          @user = user
        end

        def view_template
          render Views::Settings::Layout.new(active: :security) do
            render Components::Ui::Card.new do |card|
              card.header do
                card.title { t("users.settings.security.title") }
                card.description { t("users.settings.security.description") }
              end

              card.content do
                form_with(model: @user, url: settings_security_path, method: :patch, class: "space-y-5") do |form|
                  form.field :current_password,
                    as: :password_field,
                    label: t("users.settings.security.current_password_label"),
                    options: {
                      required: true,
                      autocomplete: "current-password",
                      placeholder: t("users.settings.security.current_password_placeholder"),
                      maxlength: 72
                    }

                  form.field :password,
                    as: :password_field,
                    label: t("users.settings.security.password_label"),
                    options: {
                      required: true,
                      autocomplete: "new-password",
                      placeholder: t("users.settings.security.password_placeholder"),
                      maxlength: 72
                    }

                  form.field :password_confirmation,
                    as: :password_field,
                    label: t("users.settings.security.password_confirmation_label"),
                    options: {
                      required: true,
                      autocomplete: "new-password",
                      placeholder: t("users.settings.security.password_confirmation_placeholder"),
                      maxlength: 72
                    }

                  div(class: "flex flex-wrap gap-3") do
                    form.submit t("users.settings.security.submit"),
                      class: "inline-flex h-10 items-center justify-center whitespace-nowrap rounded-md bg-black px-4 py-2 text-sm font-semibold text-white shadow-sm transition-colors hover:bg-rose-600 hover:text-white focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2"
                    link_to t("users.settings.security.cancel"),
                      user_path(@user),
                      class: "inline-flex items-center justify-center whitespace-nowrap rounded-md text-sm font-medium ring-offset-background transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 disabled:pointer-events-none disabled:opacity-50 h-10 px-4 py-2 border border-input bg-background hover:bg-muted"
                  end
                end
              end
            end
          end
        end
      end
    end
  end
end
