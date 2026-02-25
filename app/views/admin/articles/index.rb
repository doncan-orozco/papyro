# frozen_string_literal: true

module Views
  module Admin
    module Articles
      class Index < Views::Base
        include Phlex::Rails::Helpers::ButtonTo

        def initialize(articles)
          @articles = articles
        end

        def view_template
          turbo_frame_tag "admin_articles_list" do
            div(class: "min-h-screen bg-background") do
              div(class: "mx-auto max-w-6xl px-4 py-8") do
                render_header
                render_articles
              end
            end
          end
        end

        private

        def render_header
          div(class: "flex justify-between items-center mb-8") do
            div do
              h1(class: "text-3xl font-bold tracking-tight mb-1") { t(".title") }
              p(class: "text-muted-foreground") { t(".subtitle", default: "Manage and publish your articles") }
            end
            link_to t(".new_article"),
              new_admin_article_path,
              class: "inline-flex items-center justify-center whitespace-nowrap rounded-lg text-sm font-medium ring-offset-background transition-all focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 disabled:pointer-events-none disabled:opacity-50 h-10 px-4 py-2 bg-primary text-primary-foreground shadow hover:bg-primary/90",
              target: "_top"
          end
        end

        def render_articles
          if @articles.empty?
            render Components::Ui::Card.new do
              render Components::Ui::CardContent.new(class: "pt-6") do
                div(class: "text-center py-12") do
                  svg(class: "mx-auto h-12 w-12 text-muted-foreground mb-4", fill: "none", stroke: "currentColor", viewbox: "0 0 24 24") do |s|
                    s.path(stroke_linecap: "round", stroke_linejoin: "round", stroke_width: "1.5", d: "M19 12H5m7-7v14")
                  end
                  p(class: "text-muted-foreground") { t(".no_articles") }
                end
              end
            end
          else
            div(class: "grid grid-cols-1 gap-4") do
              @articles.each do |article|
                render_article_card(article)
              end
            end
          end
        end

        def render_article_card(article)
          render Components::Ui::Card.new(class: "hover:shadow-lg transition-shadow") do
            render Components::Ui::CardHeader.new do
              div(class: "flex justify-between items-start gap-4") do
                div(class: "flex-1") do
                  div(class: "flex items-center gap-2 mb-2") do
                    render Components::Ui::Badge.new(variant: status_variant(article)) do
                      t(".#{article.status}")
                    end
                    if article.published_at
                      span(class: "text-xs text-muted-foreground") do
                        t(".published_date", date: I18n.l(article.published_at, format: :short))
                      end
                    end
                  end
                  render Components::Ui::CardTitle.new { article.title }
                  p(class: "text-sm text-muted-foreground mt-1") { "/articles/#{article.slug}" }
                end
              end
            end

            if article.excerpt.present?
              render Components::Ui::CardContent.new(class: "pt-0") do
                p(class: "text-sm text-muted-foreground line-clamp-2") { article.excerpt }
              end
            end

            render Components::Ui::CardFooter.new do
              div(class: "flex gap-2") do
                link_to t(".edit"),
                  edit_admin_article_path(article),
                  class: "inline-flex items-center justify-center whitespace-nowrap rounded-md text-sm font-medium ring-offset-background transition-all focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 disabled:pointer-events-none disabled:opacity-50 h-9 px-3 border border-input bg-background hover:bg-muted",
                  target: "_top"

                if article.status_published?
                  link_to t(".show"),
                    article_path(article),
                    class: "inline-flex items-center justify-center whitespace-nowrap rounded-md text-sm font-medium ring-offset-background transition-all focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 disabled:pointer-events-none disabled:opacity-50 h-9 px-3 border border-input bg-background hover:bg-muted",
                    target: "_blank"
                end

                if article.status_draft?
                  button_to t(".publish"),
                    publish_admin_article_path(article, publish_action: "publish"),
                    method: :patch,
                    class: "inline-flex items-center justify-center whitespace-nowrap rounded-md text-sm font-medium ring-offset-background transition-all focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 disabled:pointer-events-none disabled:opacity-50 h-9 px-3 bg-green-600 text-white hover:bg-green-700"
                elsif article.status_published?
                  button_to t(".unpublish"),
                    publish_admin_article_path(article, publish_action: "unpublish"),
                    method: :patch,
                    class: "inline-flex items-center justify-center whitespace-nowrap rounded-md text-sm font-medium ring-offset-background transition-all focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 disabled:pointer-events-none disabled:opacity-50 h-9 px-3 bg-orange-600 text-white hover:bg-orange-700"
                end

                button_to t(".delete"),
                  admin_article_path(article),
                  method: :delete,
                  data: { turbo_confirm: t(".confirm_delete") },
                  class: "inline-flex items-center justify-center whitespace-nowrap rounded-md text-sm font-medium ring-offset-background transition-all focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 disabled:pointer-events-none disabled:opacity-50 h-9 px-3 border border-destructive bg-background text-destructive hover:bg-destructive hover:text-destructive-foreground"
              end
            end
          end
        end

        def status_variant(article)
          case article.status
          when "draft" then :secondary
          when "published" then :default
          when "archived" then :outline
          else :secondary
          end
        end
      end
    end
  end
end
