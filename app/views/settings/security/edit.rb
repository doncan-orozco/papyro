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
                      class: "transition-colors duration-300 hover:bg-rose-600 hover:border-rose-600"
                    link_to t("users.settings.security.cancel"),
                      user_path(@user),
                      class: "inline-flex items-center justify-center gap-2 whitespace-nowrap rounded-md text-sm font-medium transition-colors focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-ring disabled:pointer-events-none disabled:opacity-50 [&_svg]:pointer-events-none [&_svg]:size-4 [&_svg]:shrink-0 border border-input bg-background shadow-sm hover:bg-accent hover:text-accent-foreground h-9 px-4 py-2"
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
