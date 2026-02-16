# frozen_string_literal: true

module Views
  module Admin
    module Articles
      class Edit < Views::Base
        def initialize(article, errors = {})
          @article = article
          @errors = errors
        end

        def view_template
          div(class: "mx-auto md:w-2/3 w-full max-w-4xl") do
            h1(class: "font-bold text-3xl mb-6") { t("admin.articles.edit.title") }
            render FormComponent.new(@article, @errors)
          end
        end
      end
    end
  end
end
