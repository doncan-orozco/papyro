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
            div(class: "mx-auto w-full") do
              div(class: "flex justify-between items-center mb-8") do
                h1(class: "font-bold text-3xl") { t(".title") }
                link_to t(".new_article"),
                  new_admin_article_path,
                  class: "inline-flex items-center justify-center rounded-md font-medium transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-offset-2 h-10 px-4 py-2 text-sm bg-slate-900 text-slate-50 hover:bg-slate-900/90",
                  data: { turbo_frame: "_top" }
              end

              render_articles
            end
          end
        end

        private

        def render_articles
          if @articles.empty?
            render Components::Ui::Card.new do
              render Components::Ui::CardContent.new(class: "p-6") do
                p(class: "text-slate-500 text-center") { t(".no_articles") }
              end
            end
          else
            div(class: "grid grid-cols-1 gap-6") do
              @articles.each do |article|
                render_article_card(article)
              end
            end
          end
        end

        def render_article_card(article)
          render Components::Ui::Card.new do
            render Components::Ui::CardHeader.new do
              div(class: "flex justify-between items-start") do
                div(class: "flex-1 space-y-2") do
                  h3(class: "font-semibold text-xl leading-none tracking-tight") { article.title }
                  p(class: "text-sm text-slate-500") { "/articles/#{article.slug}" }
                end

                div(class: "flex gap-2") do
                  render_status_badge(article)
                end
              end
            end

            render Components::Ui::CardContent.new do
              if article.excerpt.present?
                p(class: "text-slate-700 mb-4") { article.excerpt }
              end

              div(class: "flex items-center justify-between") do
                if article.published_at
                  span(class: "text-sm text-slate-500") do
                    t(".published_date", date: I18n.l(article.published_at, format: :long))
                  end
                else
                  span(class: "text-sm text-slate-500") { t(".draft_status") }
                end

                div(class: "flex gap-2") do
                  link_to t(".edit"),
                    edit_admin_article_path(article),
                    class: "text-sm font-medium text-slate-900 hover:underline underline-offset-4"

                  if article.status_draft?
                    button_to t(".publish"),
                      publish_admin_article_path(article, publish_action: "publish"),
                      method: :patch,
                      class: "text-sm font-medium text-green-700 hover:underline underline-offset-4"
                  elsif article.status_published?
                    button_to t(".unpublish"),
                      publish_admin_article_path(article, publish_action: "unpublish"),
                      method: :patch,
                      class: "text-sm font-medium text-orange-700 hover:underline underline-offset-4"
                  end

                  button_to t(".delete"),
                    admin_article_path(article),
                    method: :delete,
                    data: { turbo_confirm: t(".confirm_delete") },
                    class: "text-sm font-medium text-red-700 hover:underline underline-offset-4"
                end
              end
            end
          end
        end

        def render_status_badge(article)
          variant = case article.status
          when "draft"
            :secondary
          when "published"
            :success
          when "archived"
            :warning
          else
            :secondary
          end

          render Components::Ui::Badge.new(variant: variant) do
            t(".#{article.status}")
          end
        end
      end
    end
  end
end
