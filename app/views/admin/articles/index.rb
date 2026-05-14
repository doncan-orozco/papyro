# frozen_string_literal: true

module Views
  module Admin
    module Articles
      class Index < Views::Base
        def initialize(articles:, article_presenters_by_article: {})
          @articles = articles
          @article_presenters_by_article = article_presenters_by_article
        end

        def view_template
          turbo_frame_tag "admin_articles_list" do
            div(class: "bg-background") do
              div(class: "mx-auto max-w-6xl px-4 py-8") do
                render_breadcrumb
                render Components::Ui::Card.new do |card|
                  render_header(card)
                  render_articles(card)
                end
              end
            end
          end
        end

        private

        def render_breadcrumb
          render Components::Ui::Breadcrumb.new(class: "mb-6") do |breadcrumb|
            breadcrumb.list do
              breadcrumb.item do
                breadcrumb.link(href: mine_articles_path) { t("admin.articles.breadcrumbs.home") }
              end
              breadcrumb.separator
              breadcrumb.item do
                breadcrumb.page { t("admin.articles.breadcrumbs.articles") }
              end
            end
          end
        end

        def render_header(card)
          card.header(class: "flex flex-row items-center justify-between space-y-0") do
            div do
              card.title(as: :h1) { t("admin.articles.index.title") }
              card.description { t("admin.articles.index.subtitle") }
            end

            render Components::Ui::Button.new(
              as: :a,
              href: new_article_path,
              data: { turbo_frame: "_top" }
            ) { t("admin.articles.index.new_article") }
          end
        end

        def render_articles(card)
          card.content do
            if @articles.empty?
              render EmptyState.new
            else
              render Components::Ui::Table.new do |table|
                table.header do
                  table.row do
                    table.head { t("admin.articles.index.columns.article") }
                    table.head { t("admin.articles.index.columns.status") }
                    table.head { t("admin.articles.index.columns.published") }
                    table.head { t("admin.articles.index.columns.excerpt") }
                    table.head(class: "text-right") { t("admin.articles.index.columns.actions") }
                  end
                end

                table.body do
                  @articles.each do |article|
                    render Row.new(
                      table: table,
                      article: article,
                      presenter: @article_presenters_by_article[article]
                    )
                  end
                end
              end
            end
          end
        end
      end
    end
  end
end
