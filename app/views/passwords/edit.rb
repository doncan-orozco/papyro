module Views
  module Passwords
    class Edit < Views::Base
      def initialize(token:)
        @token = token
      end

      def view_template
        div(class: "mx-auto md:w-2/3 w-full") do
          render_flash_messages

          h1(class: "font-bold text-4xl") { t(".heading") }

          whitespace
          form_with(url: password_path(@token), method: :put, class: "contents") do |form|
            div(class: "my-5") do
              form.password_field :password,
                required: true,
                autocomplete: "new-password",
                placeholder: t(".password_placeholder"),
                maxlength: 72,
                class: "block shadow-sm rounded-md border border-gray-400 focus:outline-solid focus:outline-blue-600 px-3 py-2 mt-2 w-full"
            end

            div(class: "my-5") do
              form.password_field :password_confirmation,
                required: true,
                autocomplete: "new-password",
                placeholder: t(".password_confirmation_placeholder"),
                maxlength: 72,
                class: "block shadow-sm rounded-md border border-gray-400 focus:outline-solid focus:outline-blue-600 px-3 py-2 mt-2 w-full"
            end

            div(class: "inline") do
              form.submit t(".submit"),
                class: "w-full sm:w-auto text-center rounded-md px-3.5 py-2.5 bg-blue-600 hover:bg-blue-500 text-white inline-block font-medium cursor-pointer"
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
