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
        div(class: "article-reader min-h-screen bg-background text-foreground", data: { controller: "fullscreen" }) do
          render_header
          main(class: "px-4 pb-14 sm:px-6 sm:pb-16") do
            div(class: "mx-auto w-full max-w-3xl") do
              render_article_intro
              render_article_meta
              render_content
            end
          end
          render_footer_navigation
        end
      end

      private

      def render_header
        header(class: "sticky top-0 z-20 border-b border-border bg-background/95 px-4 py-4 backdrop-blur sm:px-6") do
          div(class: "mx-auto flex w-full max-w-6xl items-center justify-between") do
            link_to back_path,
              class: "inline-flex items-center gap-2 text-muted-foreground hover:text-foreground transition",
              data: { turbo_frame: "_top", action: "click->fullscreen#exit" } do
              svg(class: "w-5 h-5", fill: "none", stroke: "currentColor", viewbox: "0 0 24 24") do |s|
                s.path(stroke_linecap: "round", stroke_linejoin: "round", stroke_width: "2", d: "M15 19l-7-7 7-7")
              end
              span(class: "text-sm font-medium") { t("articles.show.back_to_list") }
            end


            div(class: "flex items-center gap-3") do
              render Components::Shared::ThemeToggle.new
              button(
                type: "button",
                data: { action: "fullscreen#toggle:prevent", fullscreen_target: "button" },
                class: "inline-flex items-center gap-2 rounded-md border border-border px-3 py-1.5 text-sm text-muted-foreground transition hover:bg-muted hover:text-foreground",
                aria: { label: t("articles.show.fullscreen") }
              ) do
                svg(class: "h-5 w-5", fill: "none", stroke: "currentColor", viewbox: "0 0 24 24") do |s|
                  s.path(stroke_linecap: "round", stroke_linejoin: "round", stroke_width: "2", d: "M10 6H6v4m12-4h4v4M6 16v4h4m12-4v4h-4")
                end
                span { t("articles.show.fullscreen") }
              end
            end
          end
        end
      end

      def render_article_intro
        section(class: "pt-10 sm:pt-14") do
          h1(class: "text-3xl font-bold tracking-tight text-foreground sm:text-4xl md:text-5xl") { @article.title }
          return unless @article.excerpt.present?

          p(class: "mt-4 text-base leading-relaxed text-muted-foreground sm:text-lg") { @article.excerpt }
        end
      end

      def render_article_meta
        section(class: "mt-8 rounded-xl border border-border bg-card/50 p-4 sm:p-5") do
          ul(class: "flex flex-wrap items-center gap-3 text-sm text-muted-foreground") do
            if @article.published_at
              li(class: "inline-flex items-center gap-1.5") do
                span(class: "font-medium text-foreground") { t("articles.show.published") }
                time(datetime: @article.published_at.iso8601) do
                  I18n.l(@article.published_at, format: :long)
                end
              end
            end

            if @article.user
              li(class: "inline-flex items-center gap-1.5") do
                span(class: "font-medium text-foreground") { t("articles.show.author") }
                span { @article.user.email_address }
              end
            end

            li(class: "inline-flex items-center gap-1.5") do
              span(class: "font-medium text-foreground") { t("articles.show.status") }
              render Components::Ui::Badge.new(variant: status_variant(@article)) do
                @article.status.humanize
              end
            end

            if @article.body.present?
              li(class: "inline-flex items-center gap-1.5") do
                span(class: "font-medium text-foreground") { t("articles.show.content_length") }
                span { t("articles.show.words_count", count: word_count) }
              end

              li(class: "inline-flex items-center gap-1.5") do
                span(class: "font-medium text-foreground") { t("articles.show.reading_time") }
                span { t("articles.show.minutes_read", count: reading_time_minutes) }
              end
            end
          end
        end
      end

      def render_content
        article(class: "py-10 sm:py-12") do
          div(class: "prose prose-lg max-w-none text-foreground prose-headings:text-foreground prose-a:text-primary hover:prose-a:text-primary/80") do
            raw @article.html_body
          end
        end
      end

      def render_footer_navigation
        footer(class: "border-t border-border bg-card/40 px-4 py-8 sm:px-6") do
          div(class: "mx-auto w-full max-w-3xl") do
            if @prev_article.present? || @next_article.present?
              nav(class: "grid grid-cols-1 gap-4 md:grid-cols-2") do
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
        link_to article_path(article),
          class: "rounded-lg border border-border bg-background p-4 transition hover:border-border/80 hover:bg-muted #{is_next ? 'text-right' : ''}",
          data: { turbo_frame: "_top" } do
          span(class: "text-xs font-medium text-muted-foreground") { label }
          p(class: "mt-1 line-clamp-2 font-medium text-foreground") { article.title }
          if article.published_at
            time(datetime: article.published_at.iso8601,
                 class: "mt-2 block text-xs text-muted-foreground") do
              I18n.l(article.published_at, format: :short)
            end
          end
        end
      end

      def word_count
        @article.body.to_s.split.size
      end

      def reading_time_minutes
        [ (word_count / 200.0).ceil, 1 ].max
      end

      def status_variant(article)
        case article.status
        when "draft" then :secondary
        when "published" then :default
        when "archived" then :outline
        else :default
        end
      end

      def back_path
        articles_path
      end
    end
  end
end
