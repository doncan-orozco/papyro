module Views
  module Users
    class Edit < Views::Base
      include Phlex::Rails::Helpers::FormWith

      def initialize(user:)
        @user = user
      end

      def view_template
        div(class: "min-h-screen bg-background text-foreground") do
          render Components::Public::Navbar.new

          main(class: "mx-auto w-full max-w-3xl px-4 py-10") do
            render Components::Ui::Card.new do |card|
              card.header do
                card.title { t("users.edit.title") }
                card.description { t("users.edit.description") }
              end

              card.content do
                form_with(model: @user, url: user_path(@user), method: :patch, class: "space-y-5") do |form|
                  form.field :email_address,
                    as: :email_field,
                    label: t("users.edit.email_label"),
                    options: {
                      required: true,
                      autocomplete: "email",
                      placeholder: t("users.edit.email_placeholder")
                    }

                  form.field :password,
                    as: :password_field,
                    label: t("users.edit.password_label"),
                    options: {
                      autocomplete: "new-password",
                      placeholder: t("users.edit.password_placeholder"),
                      maxlength: 72
                    }

                  form.field :password_confirmation,
                    as: :password_field,
                    label: t("users.edit.password_confirmation_label"),
                    options: {
                      autocomplete: "new-password",
                      placeholder: t("users.edit.password_confirmation_placeholder"),
                      maxlength: 72
                    }

                  div(class: "flex flex-wrap gap-3") do
                    form.submit t("users.edit.submit")
                    link_to t("users.edit.cancel"), user_path(@user), class: "inline-flex items-center justify-center whitespace-nowrap rounded-md text-sm font-medium ring-offset-background transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 disabled:pointer-events-none disabled:opacity-50 h-10 px-4 py-2 border border-input bg-background hover:bg-muted"
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
