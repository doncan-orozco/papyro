module Views
  module Passwords
    class Edit < Views::Base
      def initialize(token:)
        @token = token
      end

      def view_template
        div(class: "min-h-screen bg-background flex items-center justify-center px-4 py-12") do
          render Components::Ui::Card.new(class: "w-full max-w-md") do
            render Components::Ui::CardHeader.new do
              render Components::Ui::CardTitle.new { t(".heading") }
              render Components::Ui::CardDescription.new { t(".description", default: "Enter your new password") }
            end

            render Components::Ui::CardContent.new do
              render_flash_messages
              render_form
            end
          end
        end
      end

      private

      def render_form
        form_with(url: password_path(@token), method: :put, class: "contents") do |form|
          div(class: "space-y-4") do
            render Components::Ui::FormGroup.new(class: "space-y-2") do
              render Components::Ui::Label.new(for: "password") { t(".password_label", default: "Password") }
              form.password_field :password,
                required: true,
                autocomplete: "new-password",
                placeholder: t(".password_placeholder"),
                maxlength: 72,
                class: "flex h-10 w-full rounded-md border border-input bg-background px-3 py-2 text-sm ring-offset-background file:border-0 file:bg-transparent file:text-sm file:font-medium placeholder:text-muted-foreground focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 disabled:cursor-not-allowed disabled:opacity-50"
            end

            render Components::Ui::FormGroup.new(class: "space-y-2") do
              render Components::Ui::Label.new(for: "password_confirmation") { t(".password_confirmation_label", default: "Confirm Password") }
              form.password_field :password_confirmation,
                required: true,
                autocomplete: "new-password",
                placeholder: t(".password_confirmation_placeholder"),
                maxlength: 72,
                class: "flex h-10 w-full rounded-md border border-input bg-background px-3 py-2 text-sm ring-offset-background file:border-0 file:bg-transparent file:text-sm file:font-medium placeholder:text-muted-foreground focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 disabled:cursor-not-allowed disabled:opacity-50"
            end

            form.submit t(".submit"),
              class: "w-full inline-flex items-center justify-center whitespace-nowrap rounded-md text-sm font-medium ring-offset-background transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 disabled:pointer-events-none disabled:opacity-50 h-10 px-4 py-2 bg-primary text-primary-foreground shadow hover:bg-primary/90 cursor-pointer"
          end
        end
      end

      def render_flash_messages
        if alert = view_context.flash[:alert]
          render Components::Ui::Alert.new(variant: :destructive, class: "mb-4") do
            p(class: "text-sm") { alert }
          end
        end
      end
    end
  end
end
