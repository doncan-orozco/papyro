module Views
  module Sessions
    class New < Views::Base
      def view_template
        div(class: "mx-auto md:w-2/3 w-full max-w-md") do
          render_flash_messages

          render Components::Ui::Card.new do
            render Components::Ui::CardHeader.new do
              h1(class: "font-bold text-2xl") { t(".heading") }
            end

            render Components::Ui::CardContent.new do
              form_with(url: session_path, class: "space-y-4") do |form|
                div(class: "space-y-2") do
                  render Components::Ui::Label.new(for_id: "email_address") { t(".email_label") }
                  form.email_field :email_address,
                    required: true,
                    autofocus: true,
                    autocomplete: "username",
                    placeholder: t(".email_placeholder"),
                    value: view_context.params[:email_address],
                    class: "flex h-10 w-full rounded-md border border-slate-200 bg-white px-3 py-2 text-sm ring-offset-white placeholder:text-slate-500 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-slate-950 focus-visible:ring-offset-2"
                end

                div(class: "space-y-2") do
                  render Components::Ui::Label.new(for_id: "password") { t(".password_label") }
                  form.password_field :password,
                    required: true,
                    autocomplete: "current-password",
                    placeholder: t(".password_placeholder"),
                    maxlength: 72,
                    class: "flex h-10 w-full rounded-md border border-slate-200 bg-white px-3 py-2 text-sm ring-offset-white placeholder:text-slate-500 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-slate-950 focus-visible:ring-offset-2"
                end

                div(class: "flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4 pt-2") do
                  render Components::Ui::Button.new(
                    variant: :default,
                    size: :default,
                    type: "submit"
                  ) { t(".submit") }

                  div(class: "text-sm text-slate-500") do
                    link_to t(".forgot_password"), new_password_path, class: "text-slate-700 underline underline-offset-4 hover:no-underline"
                  end
                end
              end
            end
          end
        end
      end

      private

      def render_flash_messages
        if alert = view_context.flash[:alert]
          div(class: "mb-6 rounded-lg border border-red-200 bg-red-50 p-4", id: "alert") do
            p(class: "text-sm text-red-800 font-medium") { alert }
          end
        end

        if notice = view_context.flash[:notice]
          div(class: "mb-6 rounded-lg border border-green-200 bg-green-50 p-4", id: "notice") do
            p(class: "text-sm text-green-800 font-medium") { notice }
          end
        end
      end
    end
  end
end
