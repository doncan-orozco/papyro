module Views
  module Passwords
    class New < Views::Base
      def view_template
        div(class: "min-h-screen bg-background flex items-center justify-center px-4 py-12") do
          render Components::Ui::Card.new(class: "w-full max-w-md") do
            render Components::Ui::CardHeader.new do
              render Components::Ui::CardTitle.new { t(".heading") }
              render Components::Ui::CardDescription.new { t(".description", default: "Reset your password") }
            end

            render Components::Ui::CardContent.new do
              render_flash_messages
              render_password_reset_form
            end
          end
        end
      end

      private

      def render_password_reset_form
        form_with(url: passwords_path, class: "space-y-5", local: true) do |form|
          # Email field
          div(class: "space-y-2") do
            render Components::Ui::Label.new(for: "email_address") { t(".email_label", default: "Email Address") }
            form.email_field :email_address,
              required: true,
              autofocus: true,
              autocomplete: "username",
              placeholder: t(".email_placeholder"),
              value: view_context.params[:email_address],
              class: "flex h-10 w-full rounded-md border border-input bg-background px-3 py-2 text-sm ring-offset-background placeholder:text-muted-foreground focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2"
          end

          p(class: "text-xs text-muted-foreground") do
            t(".instruction", default: "We will send you an email with instructions to reset your password.")
          end

          # Submit button
          form.submit t(".submit"),
            class: "w-full inline-flex items-center justify-center whitespace-nowrap rounded-md text-sm font-medium ring-offset-background transition-all focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 disabled:pointer-events-none disabled:opacity-50 h-10 px-4 py-2 bg-primary text-primary-foreground shadow hover:bg-primary/90"
        end
      end

      def render_flash_messages
        if alert = view_context.flash[:alert]
          render Components::Ui::Alert.new(variant: :destructive, class: "mb-4") do
            svg(class: "h-4 w-4", fill: "none", stroke: "currentColor", viewbox: "0 0 24 24") do |s|
              s.path(stroke_linecap: "round", stroke_linejoin: "round", stroke_width: "2", d: "M12 8v4m0 4v.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z")
            end
            p { alert }
          end
        end
      end
    end
  end
end
