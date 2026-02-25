# frozen_string_literal: true

module Views
  module Admin
    module Sessions
      class New < Views::Base
        def view_template
          div(class: "min-h-screen bg-background flex items-center justify-center px-4 py-12") do
            render Components::Ui::Card.new(class: "w-full max-w-md") do
              render Components::Ui::CardHeader.new do
                render Components::Ui::CardTitle.new { t(".heading") }
                render Components::Ui::CardDescription.new { t(".description", default: "Admin authentication") }
              end

              render Components::Ui::CardContent.new do
                render_login_form
              end
            end
          end
        end

        private

        def render_login_form
          form_with(url: admin_session_path, method: :post, class: "space-y-5", local: true) do |form|
            # Email field
            div(class: "space-y-2") do
              render Components::Ui::Label.new(for: "email_address") { t(".email_label", default: "Email Address") }
              form.email_field :email_address,
                required: true,
                autofocus: true,
                autocomplete: "username",
                placeholder: t(".email_placeholder"),
                class: "flex h-10 w-full rounded-md border border-input bg-background px-3 py-2 text-sm ring-offset-background placeholder:text-muted-foreground focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2"
            end

            # Password field
            div(class: "space-y-2") do
              render Components::Ui::Label.new(for: "password") { t(".password_label", default: "Password") }
              form.password_field :password,
                required: true,
                autocomplete: "current-password",
                placeholder: t(".password_placeholder"),
                maxlength: 72,
                class: "flex h-10 w-full rounded-md border border-input bg-background px-3 py-2 text-sm ring-offset-background placeholder:text-muted-foreground focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2"
            end

            # Submit button
            form.submit t(".submit"),
              class: "w-full inline-flex items-center justify-center whitespace-nowrap rounded-md text-sm font-medium ring-offset-background transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 disabled:pointer-events-none disabled:opacity-50 h-10 px-4 py-2 bg-primary text-primary-foreground shadow hover:bg-primary/90 cursor-pointer"
          end
        end
      end
    end
  end
end
