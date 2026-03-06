module Views
  module Sessions
    class New < Views::Base
      def view_template
        div(class: "min-h-screen bg-background flex items-center justify-center px-4 py-12") do
          render Components::Ui::Card.new(class: "w-full max-w-md") do
            render Components::Ui::CardHeader.new do
              render Components::Ui::CardTitle.new { t(".heading") }
              render Components::Ui::CardDescription.new { t(".description", default: "Sign in to your account") }
            end

            render Components::Ui::CardContent.new do
              render_flash_messages
              render_login_form
            end

            render Components::Ui::CardFooter.new do
              p(class: "text-xs text-muted-foreground text-center") do
                plain t(".forgot_password_prompt", default: "Forgot your password? ")
                link_to t(".forgot_password"), new_password_path, class: "text-primary hover:underline font-medium"
              end
            end
          end
        end
      end

      private

      def render_login_form
        form_with(url: session_path, class: "space-y-5", local: true) do |form|
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
            class: "w-full inline-flex items-center justify-center whitespace-nowrap rounded-md text-sm font-medium ring-offset-background transition-all focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 disabled:pointer-events-none disabled:opacity-50 h-10 px-4 py-2 bg-primary text-primary-foreground shadow hover:bg-primary/90"
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
