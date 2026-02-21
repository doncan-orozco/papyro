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
              div(class: "flex justify-between items-center mb-6") do
                h1(class: "font-bold text-4xl") { t(".title") }
                link_to t(".new_article"),
                  new_admin_article_path,
                  class: "rounded-lg py-3 px-5 bg-blue-600 text-white hover:bg-blue-700 font-medium",
                  target: "_top"
              end

              render_articles
            end
          end
        end

        private

        def render_articles
          if @articles.empty?
            p(class: "text-gray-500 italic") { t(".no_articles") }
          else
            div(class: "grid grid-cols-1 gap-4") do
              @articles.each do |article|
                render_article_card(article)
              end
            end
          end
        end

        def render_article_card(article)
          div(class: "bg-white border rounded-lg p-4 shadow-sm hover:shadow-md transition") do
            div(class: "flex justify-between items-start") do
              div(class: "flex-1") do
                h3(class: "font-bold text-xl mb-2") { article.title }
                p(class: "text-gray-600 text-sm mb-2") { "/articles/#{article.slug}" }

                if article.excerpt.present?
                  p(class: "text-gray-700 mb-2") { article.excerpt }
                end

                div(class: "flex items-center gap-2") do
                  render_status_badge(article)
                  if article.published_at
                    span(class: "text-sm text-gray-500") do
                      t(".published_date", date: I18n.l(article.published_at, format: :long))
                    end
                  end
                end
              end

              div(class: "flex flex-col gap-2 ml-4") do
                link_to t(".edit"),
                  edit_admin_article_path(article),
                  class: "text-blue-600 hover:text-blue-800 text-sm font-medium",
                  target: "_top"

                if article.status_published?
                  link_to t(".show"),
                    article_path(article),
                    class: "text-indigo-600 hover:text-indigo-800 text-sm font-medium",
                    target: "_blank"
                end

                if article.status_draft?
                  button_to t(".publish"),
                    publish_admin_article_path(article, publish_action: "publish"),
                    method: :patch,
                    class: "text-green-600 hover:text-green-800 text-sm font-medium text-left"
                elsif article.status_published?
                  button_to t(".unpublish"),
                    publish_admin_article_path(article, publish_action: "unpublish"),
                    method: :patch,
                    class: "text-orange-600 hover:text-orange-800 text-sm font-medium text-left"
                end

                button_to t(".delete"),
                  admin_article_path(article),
                  method: :delete,
                  data: { turbo_confirm: t(".confirm_delete") },
                  class: "text-red-600 hover:text-red-800 text-sm font-medium text-left"
              end
            end
          end
        end

        def render_status_badge(article)
          color_class = case article.status
          when "draft"
            "bg-gray-200 text-gray-800"
          when "published"
            "bg-green-200 text-green-800"
          when "archived"
            "bg-yellow-200 text-yellow-800"
          else
            "bg-gray-200 text-gray-800"
          end

          span(class: "px-2 py-1 rounded text-xs font-medium #{color_class}") do
            t(".#{article.status}")
          end
        end
      end
    end
  end
end
