# frozen_string_literal: true

module Views
  module Admin
    module Articles
      class FormComponent < Components::Base
        include Phlex::Rails::Helpers::FormWith
        include Phlex::Rails::Helpers::TextFieldTag
        include Phlex::Rails::Helpers::TextAreaTag
        include Phlex::Rails::Helpers::SelectTag
        
        def initialize(article, errors = {})
          @article = article
          @errors = errors
        end

        def view_template
          turbo_frame_tag "admin_article_form" do
            form_with(model: @article, url: form_url, method: form_method, class: "contents") do |form|
              div(class: "my-5") do
                form.label :title, t("admin.articles.form.title_label"), class: "block font-medium mb-2"
                form.text_field :title,
                  required: true,
                  autofocus: true,
                  placeholder: t("admin.articles.form.title_placeholder"),
                  class: "block w-full rounded-md border border-gray-400 px-3 py-2 #{error_class(:title)}"
                render_errors(:title)
              end

              div(class: "my-5") do
                form.label :slug, t("admin.articles.form.slug_label"), class: "block font-medium mb-2"
                form.text_field :slug,
                  required: true,
                  placeholder: t("admin.articles.form.slug_placeholder"),
                  class: "block w-full rounded-md border border-gray-400 px-3 py-2 #{error_class(:slug)}"
                p(class: "text-sm text-gray-500 mt-1") { t("admin.articles.form.slug_hint") }
                render_errors(:slug)
              end

              div(class: "my-5") do
                form.label :content, t("admin.articles.form.content_label"), class: "block font-medium mb-2"
                form.rich_text_area :content,
                  class: "block w-full rounded-md border border-gray-400 #{error_class(:content)}"
                render_errors(:content)
              end

              div(class: "my-5") do
                form.label :excerpt, t("admin.articles.form.excerpt_label"), class: "block font-medium mb-2"
                form.text_area :excerpt,
                  placeholder: t("admin.articles.form.excerpt_placeholder"),
                  rows: 3,
                  maxlength: 500,
                  class: "block w-full rounded-md border border-gray-400 px-3 py-2 #{error_class(:excerpt)}"
                p(class: "text-sm text-gray-500 mt-1") { t("admin.articles.form.excerpt_hint") }
                render_errors(:excerpt)
              end

              div(class: "my-5") do
                form.label :status, t("admin.articles.form.status_label"), class: "block font-medium mb-2"
                form.select :status,
                  [
                    [t("admin.articles.form.status_draft"), "draft"],
                    [t("admin.articles.form.status_published"), "published"],
                    [t("admin.articles.form.status_archived"), "archived"]
                  ],
                  {},
                  class: "block w-full rounded-md border border-gray-400 px-3 py-2 #{error_class(:status)}"
                render_errors(:status)
              end

              div(class: "flex gap-4") do
                form.submit t("admin.articles.form.save"),
                  class: "rounded-lg py-3 px-5 bg-blue-600 text-white hover:bg-blue-700 font-medium cursor-pointer"
                
                link_to t("admin.articles.form.cancel"),
                  admin_articles_path,
                  class: "rounded-lg py-3 px-5 bg-gray-200 text-gray-800 hover:bg-gray-300 font-medium"
              end
            end
          end
        end

        private

        def form_url
          @article.persisted? ? [:admin, @article] : admin_articles_path
        end

        def form_method
          @article.persisted? ? :patch : :post
        end

        def error_class(field)
          @errors.dig(field)&.any? ? "border-red-500" : ""
        end

        def render_errors(field)
          return unless @errors.dig(field)&.any?

          div(class: "mt-1") do
            @errors[field].each do |error|
              p(class: "text-sm text-red-600") { error }
            end
          end
        end
      end
    end
  end
end
