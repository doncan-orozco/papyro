# frozen_string_literal: true

module Views
  module Admin
    module Articles
      class New < Views::Base
        def initialize(article)
          @article = article
        end

        def view_template
          div(class: "bg-background px-4 py-12") do
            div(class: "mx-auto max-w-2xl") do
              render_breadcrumb
              div(class: "mb-8") do
                h1(class: "text-3xl font-bold tracking-tight mb-2") { t("admin.articles.new.title") }
                p(class: "text-muted-foreground") { t("admin.articles.new.subtitle", default: "Create a new article") }
              end

              render Components::Ui::Card.new do
                render Components::Ui::CardContent.new(class: "pt-6") do
                  render FormComponent.new(@article)
                end
              end
            end
          end
        end

        private

        def render_breadcrumb
          render Components::Ui::Breadcrumb.new(class: "mb-6") do
            render Components::Ui::BreadcrumbList.new do
              render Components::Ui::BreadcrumbItem.new do
                render Components::Ui::BreadcrumbLink.new(href: admin_root_path) { t("admin.articles.breadcrumbs.home") }
              end
              render Components::Ui::BreadcrumbSeparator.new
              render Components::Ui::BreadcrumbItem.new do
                render Components::Ui::BreadcrumbLink.new(href: admin_articles_path) { t("admin.articles.breadcrumbs.articles") }
              end
              render Components::Ui::BreadcrumbSeparator.new
              render Components::Ui::BreadcrumbItem.new do
                render Components::Ui::BreadcrumbPage.new { t("admin.articles.breadcrumbs.new") }
              end
            end
          end
        end
      end
    end
  end
end
