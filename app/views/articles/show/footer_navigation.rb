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
              h2(class: "mb-8 text-sm font-bold uppercase tracking-[0.16em] text-muted-foreground") do
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
        div(class: "mb-12 flex flex-col items-start justify-between gap-6 rounded-2xl bg-muted/30 p-6 sm:flex-row sm:items-center sm:p-8") do
          div(class: "flex items-center gap-4") do
            div(class: "h-16 w-16 shrink-0 rounded-full border border-border bg-background flex items-center justify-center text-xl font-bold text-muted-foreground") do
              @presenter.author_initial
            end

            div do
              span(class: "text-xs font-semibold uppercase tracking-[0.16em] text-muted-foreground") { t("articles.show.written_by") }
              h3(class: "mt-0.5 text-xl font-bold text-foreground") { @presenter.author_name }
              if @presenter.author_bio.present?
                p(class: "mt-1 max-w-md line-clamp-2 text-sm text-muted-foreground") { @presenter.author_bio }
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
