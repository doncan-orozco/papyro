# frozen_string_literal: true

module Views
  module Articles
    class Show < Views::Base
      include Phlex::Rails::Helpers::ImageTag

      def initialize(article:, more_from_author: [], more_from_platform: [])
        @article = article
        @more_from_author = more_from_author
        @more_from_platform = more_from_platform
      end

      def view_template
        div(class: "article-reader min-h-screen bg-background text-foreground", data: { controller: "fullscreen" }) do
          render_header
          main(class: "px-4 pb-14 sm:px-6 sm:pb-16") do
            div(class: "mx-auto w-full max-w-3xl") do
              render_translation_fallback_banner if translation_fallback?
              render_article_intro
              render_editorial_byline
              render_cover_image
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
              render Components::Ui::Icon.new(:arrow_left, class: "w-5 h-5")
              span(class: "text-sm font-medium") { t("articles.show.back_to_list") }
            end


            div(class: "flex items-center gap-3") do
              render Components::Shared::LanguageToggle.new
              render Components::Shared::ThemeToggle.new
              button(
                type: "button",
                data: { action: "fullscreen#toggle:prevent", fullscreen_target: "button" },
                class: "inline-flex items-center gap-2 rounded-md border border-border px-3 py-1.5 text-sm text-muted-foreground transition hover:bg-muted hover:text-foreground",
                aria: { label: t("articles.show.fullscreen") }
              ) do
                render Components::Ui::Icon.new(:maximize, class: "h-5 w-5")
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

      def render_translation_fallback_banner
        div(class: "mb-8 rounded-lg bg-muted/50 px-4 py-3 text-sm text-muted-foreground") do
          t("articles.show.translation_fallback_notice")
        end
      end

      def render_editorial_byline
        section(class: "mt-8 mb-12") do
          if article_author_username.present?
            link_to author_path(article_author_username, locale: I18n.locale),
              class: "group inline-flex items-center gap-3",
              data: { turbo_frame: "_top" } do
              render_byline_identity
            end
          else
            div(class: "inline-flex items-center gap-3") do
              render_byline_identity
            end
          end
        end
      end

      def render_byline_identity
        div(
          class: "h-10 w-10 shrink-0 rounded-full border border-border bg-muted flex items-center justify-center text-sm font-bold text-muted-foreground transition-all group-hover:ring-2 group-hover:ring-primary/20"
        ) { article_author_name.first.upcase }

        div(class: "flex flex-col") do
          span(class: "font-medium text-foreground group-hover:underline decoration-muted-foreground/50 underline-offset-4") do
            article_author_name
          end

          div(class: "mt-0.5 flex items-center gap-1.5 text-sm text-muted-foreground") do
            if @article.published_at
              time(datetime: @article.published_at.iso8601) do
                I18n.l(@article.published_at.to_date, format: :short)
              end
            end
            span(class: "text-muted-foreground/50") { "·" }
            span { t("articles.show.minutes_read", count: content_analysis.estimated_reading_time_minutes) }
          end
        end
      end

      def render_content
        article(class: "py-10 sm:py-12") do
          div(class: "article-prose max-w-none text-foreground") do
            raw content_analysis.html_body
          end
        end
      end

      def render_cover_image
        return unless @article.cover_image.attached?

        figure(class: "mt-8 mb-12 flex w-full flex-col items-center") do
          image_tag(
            @article.cover_image,
            alt: @article.title,
            class: "w-full aspect-[2/1] rounded-2xl border border-border object-cover shadow-sm md:aspect-[21/9]"
          )

          return unless @article.cover_image_caption.present?

          figcaption(class: "mx-auto mt-3 max-w-2xl text-center text-sm text-muted-foreground") do
            @article.cover_image_caption
          end
        end
      end

      def render_footer_navigation
        return if continuation_articles.blank?

        footer(class: "border-t border-border/40 px-4 py-8 sm:px-6") do
          div(class: "mx-auto w-full max-w-3xl") do
            render_author_outro

            div do
              h2(class: "mb-8 text-sm font-bold uppercase tracking-[0.16em] text-muted-foreground") do
                continuation_heading
              end

              nav(class: "grid grid-cols-1 gap-8 sm:grid-cols-2") do
                continuation_articles.each do |related_article|
                  render Components::Landing::ArticleCard.new(
                    article: related_article,
                    data: { turbo_frame: "_top" }
                  )
                end
              end
            end
          end
        end
      end

      def render_author_outro
        div(class: "mb-12 flex flex-col items-start justify-between gap-6 rounded-2xl bg-muted/30 p-6 sm:flex-row sm:items-center sm:p-8") do
          div(class: "flex items-center gap-4") do
            div(class: "h-16 w-16 shrink-0 rounded-full border border-border bg-background flex items-center justify-center text-xl font-bold text-muted-foreground") do
              article_author_name.first.upcase
            end

            div do
              span(class: "text-xs font-semibold uppercase tracking-[0.16em] text-muted-foreground") { t("articles.show.written_by") }
              h3(class: "mt-0.5 text-xl font-bold text-foreground") { article_author_name }
              if @article.user&.profile&.bio.present?
                p(class: "mt-1 max-w-md line-clamp-2 text-sm text-muted-foreground") { @article.user.profile.bio }
              end
            end
          end

          if article_author_username.present?
            render Components::Ui::Button.new(
              as: :a,
              href: author_path(article_author_username, locale: I18n.locale),
              variant: :outline,
              size: :sm,
              class: "whitespace-nowrap",
              data: { turbo_frame: "_top" }
            ) { t("articles.show.view_profile") }
          end
        end
      end

      def continuation_articles
        @continuation_articles ||= @more_from_author.presence || @more_from_platform
      end

      def continuation_heading
        if @more_from_author.present?
          t("articles.show.more_from_author", author: article_author_name)
        else
          t("articles.show.more_from_platform")
        end
      end

      def article_author_name
        @article.user&.author_display_name || t("articles.show.unknown_author")
      end

      def article_author_username
        @article.user&.profile&.username
      end

      def content_analysis
        @content_analysis ||= ::Articles::ContentAnalysis.new(@article)
      end

      def back_path
        articles_path
      end

      def translation_fallback?
        I18n.locale.to_s != "en" && !@article.translation_published?
      end
    end
  end
end
