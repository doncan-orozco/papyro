# frozen_string_literal: true

module Views
  module Admin
    module Articles
      class FormComponent < Components::Base
        include Phlex::Rails::Helpers::FormWith
        include Phlex::Rails::Helpers::TextFieldTag
        include Phlex::Rails::Helpers::TextAreaTag
        include Phlex::Rails::Helpers::SelectTag

        def initialize(article, errors = {}, **attrs)
          @article = article
          @errors = errors
          @attrs = attrs
        end

        def view_template
          turbo_frame_tag "admin_article_form", **@attrs do
            render Components::Ui::Card.new do
              render Components::Ui::CardContent.new(class: "p-6") do
                form_with(model: @article, url: form_url, method: form_method, class: "space-y-6") do |form|
                  div(class: "space-y-2") do
                    render Components::Ui::Label.new(for_id: "article_title") do
                      t("admin.articles.form.title_label")
                    end
                    form.text_field :title,
                      required: true,
                      autofocus: true,
                      placeholder: t("admin.articles.form.title_placeholder"),
                      class: input_classes(error_class(:title))
                    render_errors(:title)
                  end

                  div(class: "space-y-2") do
                    render Components::Ui::Label.new(for_id: "article_slug") do
                      t("admin.articles.form.slug_label")
                    end
                    form.text_field :slug,
                      required: true,
                      placeholder: t("admin.articles.form.slug_placeholder"),
                      class: input_classes(error_class(:slug))
                    p(class: "text-sm text-slate-500") { t("admin.articles.form.slug_hint") }
                    render_errors(:slug)
                  end

                  div(class: "space-y-2") do
                    render Components::Ui::Label.new(for_id: "article_content") do
                      t("admin.articles.form.content_label")
                    end
                    form.rich_text_area :content,
                      class: "block w-full rounded-md border border-slate-200 #{error_class(:content)}"
                    render_errors(:content)
                  end

                  div(class: "space-y-2") do
                    render Components::Ui::Label.new(for_id: "article_excerpt") do
                      t("admin.articles.form.excerpt_label")
                    end
                    form.text_area :excerpt,
                      placeholder: t("admin.articles.form.excerpt_placeholder"),
                      rows: 3,
                      maxlength: 500,
                      class: textarea_classes(error_class(:excerpt))
                    p(class: "text-sm text-slate-500") { t("admin.articles.form.excerpt_hint") }
                    render_errors(:excerpt)
                  end

                  div(class: "space-y-2") do
                    render Components::Ui::Label.new(for_id: "article_status") do
                      t("admin.articles.form.status_label")
                    end
                    form.select :status,
                      [
                        [ t("admin.articles.form.status_draft"), "draft" ],
                        [ t("admin.articles.form.status_published"), "published" ],
                        [ t("admin.articles.form.status_archived"), "archived" ]
                      ],
                      {},
                      class: select_classes(error_class(:status))
                    render_errors(:status)
                  end

                  div(class: "flex gap-4 pt-4") do
                    render Components::Ui::Button.new(
                      variant: :default,
                      size: :default,
                      type: "submit"
                    ) { t("admin.articles.form.save") }

                    link_to t("admin.articles.form.cancel"),
                      admin_articles_path,
                      class: "inline-flex items-center justify-center rounded-md font-medium transition-colors h-10 px-4 py-2 text-sm bg-slate-100 text-slate-900 hover:bg-slate-100/80"
                  end
                end
              end
            end
          end
        end

        private

        def form_url
          @article.persisted? ? [ :admin, @article ] : admin_articles_path
        end

        def form_method
          @article.persisted? ? :patch : :post
        end

        def error_class(field)
          @errors.dig(field)&.any? ? "border-red-500" : ""
        end

        def input_classes(error_class)
          base = "flex h-10 w-full rounded-md border bg-white px-3 py-2 text-sm ring-offset-white placeholder:text-slate-500 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-slate-950 focus-visible:ring-offset-2"
          error_class.present? ? "#{base} #{error_class}" : "#{base} border-slate-200"
        end

        def textarea_classes(error_class)
          base = "flex min-h-[80px] w-full rounded-md border bg-white px-3 py-2 text-sm ring-offset-white placeholder:text-slate-500 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-slate-950 focus-visible:ring-offset-2"
          error_class.present? ? "#{base} #{error_class}" : "#{base} border-slate-200"
        end

        def select_classes(error_class)
          base = "flex h-10 w-full rounded-md border bg-white px-3 py-2 text-sm ring-offset-white focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-slate-950 focus-visible:ring-offset-2"
          error_class.present? ? "#{base} #{error_class}" : "#{base} border-slate-200"
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
