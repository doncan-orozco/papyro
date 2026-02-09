module Views
  module Passwords
    class New < Views::Base
      def view_template
        div(class: "mx-auto md:w-2/3 w-full") do
          render_flash_messages

          h1(class: "font-bold text-4xl") { t(".heading") }

          whitespace
          form_with(url: passwords_path, class: "contents") do |form|
            div(class: "my-5") do
              form.email_field :email_address,
                required: true,
                autofocus: true,
                autocomplete: "username",
                placeholder: t(".email_placeholder"),
                value: view_context.params[:email_address],
                class: "block shadow-sm rounded-md border border-gray-400 focus:outline-solid focus:outline-blue-600 px-3 py-2 mt-2 w-full"
            end

            div(class: "inline") do
              form.submit t(".submit"),
                class: "w-full sm:w-auto text-center rounded-lg px-3.5 py-2.5 bg-blue-600 hover:bg-blue-500 text-white inline-block font-medium cursor-pointer"
            end
          end
        end
      end

      private

      def render_flash_messages
        if alert = view_context.flash[:alert]
          p(class: "py-2 px-3 bg-red-50 mb-5 text-red-500 font-medium rounded-lg inline-block", id: "alert") { alert }
        end
      end
    end
  end
end
