# frozen_string_literal: true

module Views
  module Articles
    class Show < Views::Base
      def initialize(article, prev_article: nil, next_article: nil)
        @article = article
        @prev_article = prev_article
        @next_article = next_article
      end

      def view_template
        div(class: "article-reader flex flex-col min-h-screen bg-white", data: { controller: "lightbox fullscreen" }) do
          # Header Navigation
          render_header

          # Main Reader Layout
          div(class: "flex flex-1 overflow-hidden") do
            # Sidebar
            render_sidebar

            # Main Content
            div(class: "flex-1 overflow-y-auto") do
              render_content
            end
          end

          # Footer Navigation
          render_footer_navigation
        end
      end

      private

      def render_header
        header(class: "sticky top-0 z-20 bg-white border-b border-gray-200 px-6 py-4") do
          div(class: "flex items-center justify-between") do
            # Back Button
            a(href: root_path,
              class: "inline-flex items-center gap-2 text-gray-600 hover:text-gray-900 transition",
              data: { turbo_frame: "_top" }) do
              svg(class: "w-5 h-5", fill: "none", stroke: "currentColor", viewbox: "0 0 24 24") do |s|
                s.path(stroke_linecap: "round", stroke_linejoin: "round", stroke_width: "2", d: "M15 19l-7-7 7-7")
              end
              span(class: "text-sm font-medium") { t("articles.show.back_to_list") }
            end

            # Fullscreen Button
            button(
              type: "button",
              data: { action: "fullscreen#toggle:prevent", fullscreen_target: "button" },
              class: "inline-flex items-center gap-2 text-gray-600 hover:text-gray-900 transition",
              aria: { label: t("articles.show.fullscreen") }
            ) do
              svg(class: "w-5 h-5", fill: "none", stroke: "currentColor", viewbox: "0 0 24 24") do |s|
                s.path(stroke_linecap: "round", stroke_linejoin: "round", stroke_width: "2", d: "M10 6H6v4m12-4h4v4M6 18h4v-4m12 4h-4v-4")
              end
              span(class: "text-sm font-medium") { t("articles.show.fullscreen") }
            end
          end
        end
      end

      def render_sidebar
        aside(class: "w-80 border-r border-gray-200 p-6 sticky top-20 h-fit space-y-6") do
          # Article Title Section
          div do
            h1(class: "text-2xl font-bold text-gray-900 mb-2") { @article.title }

            if @article.excerpt.present?
              p(class: "text-sm text-gray-600") { @article.excerpt }
            end
          end

          # Metadata
          div(class: "space-y-3 text-sm text-gray-600") do
            if @article.published_at
              div(class: "flex items-center gap-2") do
                span(class: "font-medium text-gray-700") { t("articles.show.published") }
                time(datetime: @article.published_at.iso8601) do
                  I18n.l(@article.published_at, format: :long)
                end
              end
            end

            if @article.user
              div(class: "flex items-center gap-2") do
                span(class: "font-medium text-gray-700") { t("articles.show.author") }
                span { @article.user.email_address }
              end
            end

            div(class: "flex items-center gap-2") do
              span(class: "font-medium text-gray-700") { t("articles.show.status") }
              span(class: "px-2 py-1 rounded-full text-xs font-semibold bg-blue-100 text-blue-700") do
                @article.status.humanize
              end
            end
          end

          # Content Summary
          if @article.body.present?
            div(class: "pt-4 border-t border-gray-200") do
              p(class: "text-xs font-medium text-gray-700 mb-2 uppercase tracking-wide") do
                t("articles.show.content_length")
              end
              p(class: "text-sm text-gray-600") do
                "#{@article.body.to_s.split.length} #{t('articles.show.words')}"
              end
            end
          end
        end
      end

      def render_content
        article(class: "max-w-3xl mx-auto px-6 py-12") do
          div(class: "prose prose-lg max-w-none") do
            raw @article.html_body
          end
        end
      end

      def render_footer_navigation
        footer(class: "border-t border-gray-200 bg-gray-50 px-6 py-8") do
          div(class: "max-w-6xl mx-auto") do
            # Navigation Links
            if @prev_article.present? || @next_article.present?
              nav(class: "flex justify-between gap-4") do
                # Previous Article
                if @prev_article.present?
                  a(href: @prev_article.to_param,
                    class: "flex-1 p-4 rounded-lg border border-gray-200 hover:border-gray-400 hover:bg-white transition group",
                    data: { turbo_frame: "_top" }) do
                    span(class: "text-xs font-medium text-gray-500 group-hover:text-gray-700") { t("articles.show.previous") }
                    p(class: "font-medium text-gray-900 mt-1 group-hover:text-blue-600") { @prev_article.title }
                    if @prev_article.published_at
                      time(datetime: @prev_article.published_at.iso8601,
                           class: "text-xs text-gray-500 block mt-2") do
                        I18n.l(@prev_article.published_at, format: :short)
                      end
                    end
                  end
                else
                  div(class: "flex-1")
                end

                # Next Article
                if @next_article.present?
                  a(href: @next_article.to_param,
                    class: "flex-1 p-4 rounded-lg border border-gray-200 hover:border-gray-400 hover:bg-white transition group text-right",
                    data: { turbo_frame: "_top" }) do
                    span(class: "text-xs font-medium text-gray-500 group-hover:text-gray-700") { t("articles.show.next") }
                    p(class: "font-medium text-gray-900 mt-1 group-hover:text-blue-600") { @next_article.title }
                    if @next_article.published_at
                      time(datetime: @next_article.published_at.iso8601,
                           class: "text-xs text-gray-500 block mt-2") do
                        I18n.l(@next_article.published_at, format: :short)
                      end
                    end
                  end
                else
                  div(class: "flex-1")
                end
              end
            end
          end
        end
      end
    end
  end
end
