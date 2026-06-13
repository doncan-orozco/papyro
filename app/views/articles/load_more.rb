# frozen_string_literal: true

module Views
  module Articles
    class LoadMore < Views::Base
      def initialize(articles:, pagy:)
        @articles = articles
        @pagy = pagy
      end

      def view_template
        turbo_stream.append("articles_feed") do
          @articles.each do |article|
            div(class: "py-12") do
              render Components::Landing::ArticleCard.new(
                article: article,
                data: { turbo_frame: "_top", turbo_action: "advance" }
              )
            end
          end
        end

        turbo_stream.replace("load_more_container") do
          if @pagy.next
            div(id: "load_more_container", class: "mt-12 flex justify-center pb-4") do
              link_to t("articles.index.load_more"),
                articles_path(page: @pagy.next),
                data: { turbo_stream: true },
                class: "inline-flex items-center justify-center rounded-full border border-border bg-background px-6 py-2.5 text-sm font-medium text-foreground/80 transition-colors hover:bg-muted hover:text-foreground focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring"
            end
          else
            # No more pages — render nothing (removes the button)
            plain ""
          end
        end
      end
    end
  end
end
