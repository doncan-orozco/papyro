# frozen_string_literal: true

module Views
  module Articles
    class Show::FooterNavigation < Views::Base
      def initialize(presenter:)
        @presenter = presenter
      end

      def view_template
        return if @presenter.continuation_articles.blank?

        footer(class: "border-t border-border/40 px-4 py-8 sm:px-6") do
          div(class: "mx-auto w-full max-w-3xl") do
            render_author_outro

            div do
              h2(class: "mb-8 text-sm font-bold uppercase tracking-[0.16em] text-foreground/80") do
                @presenter.continuation_heading
              end

              nav(class: "grid grid-cols-1 gap-8 sm:grid-cols-2") do
                @presenter.continuation_articles.each do |related_article|
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

      private

      def render_author_outro
        div(class: "mb-16 flex flex-col items-start justify-between gap-6 border-y border-border/40 py-10 sm:flex-row sm:items-center") do
          div(class: "flex items-center gap-5") do
            div(class: "flex h-20 w-20 shrink-0 items-center justify-center rounded-full border border-border bg-background text-2xl font-bold text-foreground/80") do
              @presenter.author_initial
            end

            div do
              span(class: "text-[10px] font-bold uppercase tracking-[0.2em] text-foreground/80") { t("articles.show.written_by") }
              h3(class: "mt-1 text-2xl font-bold text-foreground") { @presenter.author_name }
              if @presenter.author_bio.present?
                p(class: "mt-2 max-w-md line-clamp-2 text-base text-foreground/75") { @presenter.author_bio }
              end
            end
          end

          return unless @presenter.author_username.present?

          render Components::Ui::Button.new(
            as: :a,
            href: author_path(@presenter.author_username, locale: I18n.locale),
            variant: :outline,
            size: :sm,
            class: "whitespace-nowrap",
            data: { turbo_frame: "_top" }
          ) { t("articles.show.view_profile") }
        end
      end
    end
  end
end
