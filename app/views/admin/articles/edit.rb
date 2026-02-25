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
          div(class: "min-h-screen bg-background px-4 py-12") do
            div(class: "mx-auto max-w-2xl") do
              div(class: "mb-8") do
                h1(class: "text-3xl font-bold tracking-tight mb-2") { t("admin.articles.edit.title") }
                p(class: "text-muted-foreground") { t("admin.articles.edit.subtitle", default: "Edit this article") }
              end

              render Components::Ui::Card.new do
                render Components::Ui::CardContent.new(class: "pt-6") do
                  render FormComponent.new(@article, @errors)
                end
              end
            end
          end
        end
      end
    end
  end
end
