# frozen_string_literal: true

module Views
  module Articles
    class Show::Byline < Views::Base
      def initialize(presenter:)
        @presenter = presenter
      end

      def view_template
        section(class: "mt-8 mb-16") do
          if @presenter.author_username.present?
            link_to author_path(@presenter.author_username, locale: I18n.locale),
              class: "group inline-flex items-center gap-3",
              data: { turbo_frame: "_top" } do
              render_identity
            end
          else
            div(class: "inline-flex items-center gap-3") do
              render_identity
            end
          end
        end
      end

      private

      def render_identity
        div(
          class: "h-10 w-10 shrink-0 rounded-full border border-border bg-muted flex items-center justify-center text-sm font-bold text-foreground/80 transition-all group-hover:ring-2 group-hover:ring-primary/20 group-focus-visible:ring-2 group-focus-visible:ring-primary/20"
        ) { @presenter.author_initial }

        div(class: "flex flex-col") do
          span(class: "font-medium text-foreground group-hover:underline group-focus-visible:underline decoration-muted-foreground/50 underline-offset-4") do
            @presenter.author_name
          end

          div(class: "mt-0.5 flex items-center gap-1.5 text-sm text-foreground/80") do
            if @presenter.published_at
              time(datetime: @presenter.published_at.iso8601) do
                I18n.l(@presenter.published_at.to_date, format: :short)
              end
            end
            span(class: "text-foreground/50") { "·" }
            span { t("articles.show.minutes_read", count: @presenter.reading_time_minutes) }
          end
        end
      end
    end
  end
end
