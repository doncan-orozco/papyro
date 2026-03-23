# frozen_string_literal: true

module Views
  module Articles
    class Show < Views::Base
      def initialize(article:, prev_article: nil, next_article: nil)
        @article = article
        @prev_article = prev_article
        @next_article = next_article
      end

      def view_template
        div(class: "article-reader flex flex-col min-h-screen bg-background", data: { controller: "lightbox fullscreen" }) do
          render_header
          div(class: "flex flex-1 overflow-hidden") do
            render_sidebar
            div(class: "flex-1 overflow-y-auto") do
              render_content
            end
          end
          render_footer_navigation
        end
      end

      private

      def render_header
        header(class: "sticky top-0 z-20 bg-card border-b border-border px-6 py-4 shadow-sm") do
          div(class: "flex items-center justify-between") do
            a(href: root_path,
              class: "inline-flex items-center gap-2 text-muted-foreground hover:text-foreground transition",
              data: { turbo_frame: "_top" }) do
              svg(class: "w-5 h-5", fill: "none", stroke: "currentColor", viewbox: "0 0 24 24") do |s|
                s.path(stroke_linecap: "round", stroke_linejoin: "round", stroke_width: "2", d: "M15 19l-7-7 7-7")
              end
              span(class: "text-sm font-medium") { t("articles.show.back_to_list") }
            end

            button(
              type: "button",
              data: { action: "fullscreen#toggle:prevent", fullscreen_target: "button" },
              class: "inline-flex items-center gap-2 text-muted-foreground hover:text-foreground transition",
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
        aside(class: "w-80 border-r border-border p-6 flex-shrink-0 space-y-6 bg-card/50 overflow-y-auto") do
          div do
            h1(class: "text-2xl font-bold text-foreground mb-2") { @article.title }
            if @article.excerpt.present?
              p(class: "text-sm text-muted-foreground") { @article.excerpt }
            end
          end

          div(class: "space-y-3 text-sm text-muted-foreground") do
            if @article.published_at
              div(class: "flex items-center gap-2") do
                span(class: "font-medium text-foreground") { t("articles.show.published") }
                time(datetime: @article.published_at.iso8601) do
                  I18n.l(@article.published_at, format: :long)
                end
              end
            end

            if @article.user
              div(class: "flex items-center gap-2") do
                span(class: "font-medium text-foreground") { t("articles.show.author") }
                span { @article.user.email_address }
              end
            end

            div(class: "flex items-center gap-2") do
              span(class: "font-medium text-foreground") { t("articles.show.status") }
              render Components::Ui::Badge.new(variant: status_variant(@article)) do
                @article.status.humanize
              end
            end
          end

          if @article.body.present?
            div(class: "pt-4 border-t border-border") do
              p(class: "text-xs font-medium text-foreground mb-2 uppercase tracking-wide") do
                t("articles.show.content_length")
              end
              p(class: "text-sm text-muted-foreground") do
                "#{@article.body.to_s.split.length} #{t('articles.show.words')}"
              end
            end
          end
        end
      end

      def render_content
        article(class: "max-w-3xl mx-auto px-6 py-12") do
          div(class: "prose prose-lg max-w-none text-foreground dark:prose-invert") do
            raw @article.html_body
          end
        end
      end

      def render_footer_navigation
        footer(class: "border-t border-border bg-card/50 px-6 py-8") do
          div(class: "max-w-6xl mx-auto") do
            if @prev_article.present? || @next_article.present?
              nav(class: "grid grid-cols-2 gap-4") do
                if @prev_article.present?
                  render_nav_card(@prev_article, t("articles.show.previous"), is_next: false)
                else
                  div
                end

                if @next_article.present?
                  render_nav_card(@next_article, t("articles.show.next"), is_next: true)
                else
                  div
                end
              end
            end
          end
        end
      end

      def render_nav_card(article, label, is_next: false)
        a(href: article.to_param,
          class: "p-4 rounded-lg border border-border bg-background hover:bg-muted transition group #{is_next ? 'text-right' : ''}",
          data: { turbo_frame: "_top" }) do
          span(class: "text-xs font-medium text-muted-foreground group-hover:text-foreground") { label }
          p(class: "font-medium text-foreground mt-1 group-hover:text-primary line-clamp-2") { article.title }
          if article.published_at
            time(datetime: article.published_at.iso8601,
                 class: "text-xs text-muted-foreground block mt-2") do
              I18n.l(article.published_at, format: :short)
            end
          end
        end
      end

      def status_variant(article)
        case article.status
        when "draft" then :secondary
        when "published" then :default
        when "archived" then :outline
        else :default
        end
      end
    end
  end
end
