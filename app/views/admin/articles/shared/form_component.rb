# frozen_string_literal: true

module Views
  module Admin
    module Articles
      class Shared::FormComponent < Components::Base
        include Phlex::Rails::Helpers::FormWith

        def initialize(article, **attrs)
          @article = article
          @attrs = attrs
        end

        def view_template
          form_with(model: @article, url: form_url, method: form_method, class: "contents", data: { turbo: false }) do |form|
            form.field :title,
              as: :text_field,
              label: t("admin.articles.form.title_label"),
              hint: t("admin.articles.form.title_hint", default: nil),
              options: {
                required: true,
                autofocus: false,
                placeholder: t("admin.articles.form.title_placeholder")
              }

            form.field :slug,
              as: :text_field,
              label: t("admin.articles.form.slug_label"),
              hint: t("admin.articles.form.slug_hint", default: nil),
              options: { placeholder: t("admin.articles.form.slug_placeholder") }

            form.field :body,
              as: :markdown_area,
              label: t("admin.articles.form.body_label"),
              hint: t("admin.articles.form.body_hint", default: "Markdown-formatted content for the article"),
              before_input: capture { div { tag(:"house-md-toolbar", id: "house_toolbar") } },
              options: {
                toolbar: "house_toolbar",
                required: true,
                class: "min-h-[200px]"
              }

            form.field :excerpt,
              as: :text_area,
              label: t("admin.articles.form.excerpt_label"),
              hint: t("admin.articles.form.excerpt_hint", default: nil),
              options: { placeholder: t("admin.articles.form.excerpt_placeholder"), rows: 3, maxlength: 500 }

            form.field :status,
              as: :select,
              label: t("admin.articles.form.status_label"),
              choices: [
                [ t("admin.articles.form.status_draft"), "draft" ],
                [ t("admin.articles.form.status_published"), "published" ],
                [ t("admin.articles.form.status_archived"), "archived" ]
              ]

            div(class: "flex gap-3 pt-4") do
              form.submit t("admin.articles.form.save")

              link_to t("admin.articles.form.cancel"),
                mine_articles_path,
                class: "inline-flex items-center justify-center whitespace-nowrap rounded-md text-sm font-medium ring-offset-background transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 disabled:pointer-events-none disabled:opacity-50 h-10 px-4 py-2 border border-input bg-background hover:bg-muted",
                data: { turbo_frame: "_top" }
            end
          end
        end

        private

        def form_url
          @article.persisted? ? article_path(@article) : articles_path
        end

        def form_method
          @article.persisted? ? :patch : :post
        end
      end
    end
  end
end
