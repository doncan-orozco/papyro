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
          form_with(model: @article, url: form_url, method: form_method, class: "contents", data: { turbo: false }) do |form|
            render_form_field(form, :title)
            render_form_field(form, :slug)
            render_markdown_field(form)
            render_form_field(form, :excerpt, type: :textarea)
            render_status_field(form)
            render_actions(form)
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
          @errors.dig(field)&.any? ? "border-destructive" : ""
        end

        def render_form_field(form, field, type: :text)
          div(class: "space-y-2") do
            render Components::Ui::Label.new(for: "article_#{field}") { t("admin.articles.form.#{field}_label") }

            if type == :textarea
              form.text_area field,
                placeholder: t("admin.articles.form.#{field}_placeholder"),
                rows: 3,
                maxlength: 500,
                class: "flex min-h-[80px] w-full rounded-md border border-input bg-background px-3 py-2 text-sm ring-offset-background placeholder:text-muted-foreground focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 disabled:cursor-not-allowed disabled:opacity-50 #{error_class(field)}"
            else
              form.text_field field,
                required: field == :title,
                autofocus: field == :title,
                placeholder: t("admin.articles.form.#{field}_placeholder"),
                class: "flex h-10 w-full rounded-md border border-input bg-background px-3 py-2 text-sm ring-offset-background file:border-0 file:bg-transparent file:text-sm file:font-medium placeholder:text-muted-foreground focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 disabled:cursor-not-allowed disabled:opacity-50 #{error_class(field)}"
            end

            if t("admin.articles.form.#{field}_hint", default: nil).present?
              p(class: "text-xs text-muted-foreground") { t("admin.articles.form.#{field}_hint") }
            end

            render_errors(field)
          end
        end

        def render_markdown_field(form)
          div(class: "space-y-2") do
            render Components::Ui::Label.new(for: "article_body") { t("admin.articles.form.body_label") }

            tag(:"house-md-toolbar", id: "house_toolbar")
            form.markdown_area :body,
              toolbar: "house_toolbar",
              required: true,
              class: "flex min-h-[200px] w-full rounded-md border border-input bg-background px-3 py-2 text-sm ring-offset-background placeholder:text-muted-foreground focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 disabled:cursor-not-allowed disabled:opacity-50 #{error_class(:body)}"

            p(class: "text-xs text-muted-foreground") { t("admin.articles.form.body_hint", default: "Markdown-formatted content for the article") }
            render_errors(:body)
          end
        end

        def render_status_field(form)
          div(class: "space-y-2") do
            render Components::Ui::Label.new(for: "article_status") { t("admin.articles.form.status_label") }
            form.select :status,
              [
                [ t("admin.articles.form.status_draft"), "draft" ],
                [ t("admin.articles.form.status_published"), "published" ],
                [ t("admin.articles.form.status_archived"), "archived" ]
              ],
              {},
              class: "flex h-10 w-full rounded-md border border-input bg-background px-3 py-2 text-sm ring-offset-background placeholder:text-muted-foreground focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 disabled:cursor-not-allowed disabled:opacity-50 #{error_class(:status)}"

            render_errors(:status)
          end
        end

        def render_actions(form)
          div(class: "flex gap-3 pt-4") do
            form.submit t("admin.articles.form.save"),
              class: "inline-flex items-center justify-center whitespace-nowrap rounded-md text-sm font-medium ring-offset-background transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 disabled:pointer-events-none disabled:opacity-50 h-10 px-4 py-2 bg-primary text-primary-foreground shadow hover:bg-primary/90 cursor-pointer"

            link_to t("admin.articles.form.cancel"),
              admin_articles_path,
              class: "inline-flex items-center justify-center whitespace-nowrap rounded-md text-sm font-medium ring-offset-background transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 disabled:pointer-events-none disabled:opacity-50 h-10 px-4 py-2 border border-input bg-background hover:bg-muted",
              data: { turbo_frame: "_top" }
          end
        end

        def render_errors(field)
          return unless @errors.dig(field)&.any?

          render Components::Ui::Alert.new(variant: :destructive) do
            div(class: "space-y-1") do
              @errors[field].each do |error|
                p(class: "text-sm") { error }
              end
            end
          end
        end
      end
    end
  end
end
