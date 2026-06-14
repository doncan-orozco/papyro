# frozen_string_literal: true

module Components
  module Public
    class SearchResults < Components::Base
      def initialize(query:, articles:, authors:)
        @query = query
        @articles = articles
        @authors = authors
      end

      def view_template
        turbo_frame_tag :search_results do
          if @query.blank?
            # State A: No query — render nothing inside the frame
          elsif @articles.empty? && @authors.empty?
            # State B: Has query but no results
            render_empty_state
          else
            # State C: Has results
            render_results
          end
        end
      end

      private

      def render_empty_state
        div(class: "p-6 text-center") do
          render Components::Ui::Icon.new(:search, class: "mx-auto h-8 w-8 text-muted-foreground mb-3")
          p(class: "text-sm font-medium text-foreground") do
            t("search.results.empty_title", query: @query)
          end
          p(class: "mt-1 text-xs text-muted-foreground") do
            t("search.results.empty_description")
          end
          div(class: "mt-3") do
            a(
              href: root_path,
              class: "text-xs text-foreground/80 underline hover:text-foreground",
              data: { turbo_frame: "_top" }
            ) do
              t("search.results.browse_latest")
            end
          end
        end
      end

      def render_results
        div(class: "max-h-96 overflow-y-auto divide-y divide-border/40") do
          if @authors.any?
            render_authors_section
          end
          if @articles.any?
            render_articles_section
          end
        end
      end

      def render_authors_section
        div(class: "p-2") do
          p(class: "px-2 py-1 text-[11px] font-semibold uppercase tracking-widest text-muted-foreground") do
            t("search.results.authors")
          end
          @authors.each do |author|
            render_author_item(author)
          end
        end
      end

      def render_author_item(author)
        profile = author.profile
        a(
          href: author_path(profile.username),
          class: "flex items-center gap-3 rounded-lg px-2 py-2 transition-colors hover:bg-muted",
          data: { turbo_frame: "_top" }
        ) do
          # Avatar: portrait image or initial fallback
          div(class: "flex h-8 w-8 shrink-0 items-center justify-center overflow-hidden rounded-full bg-muted text-xs font-bold uppercase text-foreground") do
            if profile.portrait.attached?
              img(
                src: helpers.url_for(profile.portrait),
                alt: profile.display_name,
                class: "h-full w-full object-cover"
              )
            else
              span { profile.display_name.first.upcase }
            end
          end
          # Display name and @username
          div(class: "min-w-0 flex-1") do
            p(class: "truncate text-sm font-medium text-foreground") { profile.display_name }
            p(class: "truncate text-xs text-muted-foreground") { "@#{profile.username}" }
          end
        end
      end

      def render_articles_section
        div(class: "p-2") do
          p(class: "px-2 py-1 text-[11px] font-semibold uppercase tracking-widest text-muted-foreground") do
            t("search.results.articles")
          end
          @articles.each do |article|
            render_article_item(article)
          end
        end
      end

      def render_article_item(article)
        a(
          href: article_path(article),
          class: "flex items-center justify-between gap-4 rounded-lg px-2 py-2 transition-colors hover:bg-muted",
          data: { turbo_frame: "_top" }
        ) do
          p(class: "min-w-0 flex-1 truncate text-sm font-medium text-foreground") { article.title }
          if article.published_at.present?
            span(class: "shrink-0 text-xs text-muted-foreground") do
              I18n.l(article.published_at.to_date, format: :short)
            end
          end
        end
      end
    end
  end
end
