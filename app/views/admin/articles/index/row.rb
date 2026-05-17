# frozen_string_literal: true

module Views
  module Admin
    module Articles
      class Index::Row < Views::Base
        def initialize(table:, article:, presenter:)
          @table = table
          @article = article
          @presenter = presenter
        end

        def view_template
          @table.row do
            render_title
            render_status
            render_published
            render_excerpt
            render_actions
          end
        end

        private

        def render_title
          @table.cell(class: "font-medium") { @article.title }
        end

        def render_status
          @table.cell do
            render Components::Ui::Badge.new(variant: status_variant) do
              status_label
            end
          end
        end

        def render_published
          @table.cell(class: "text-sm text-muted-foreground") { published_label }
        end

        def render_excerpt
          @table.cell(class: "text-sm text-muted-foreground") do
            if has_excerpt?
              span(class: "block line-clamp-2 max-w-[36ch]") { excerpt_text }
            else
              span(class: "italic") { t("admin.articles.index.no_excerpt") }
            end
          end
        end

        def render_actions
          @table.cell(class: "text-right") do
            render Index::RowActions.new(article: @article)
          end
        end

        def status_variant
          return @presenter.status_variant if @presenter

          case @article.status
          when "published"
            :default
          when "draft"
            :secondary
          else
            :outline
          end
        end

        def status_label
          return @presenter.status_label if @presenter

          t("studio.articles.index.statuses.#{@article.status}", default: @article.status.humanize)
        end

        def published_label
          return @presenter.published_label if @presenter
          return t("admin.articles.index.never") unless @article.published_at

          l(@article.published_at, format: :short)
        end

        def has_excerpt?
          return @presenter.has_excerpt? if @presenter

          @article.excerpt.present?
        end

        def excerpt_text
          return @presenter.excerpt_text if @presenter

          @article.excerpt
        end
      end
    end
  end
end
