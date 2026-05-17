# frozen_string_literal: true

module Views
  module Authors
    class Show::ArticlesSection < Views::Base
      def initialize(presenter:, articles:, pagy:)
        @presenter = presenter
        @articles = articles
        @pagy = pagy
      end

      def view_template
        div(class: "space-y-6") do
          h2(class: "text-xl font-semibold tracking-tight") { t("authors.show.articles_by", name: @presenter.display_name) }

          if @articles.empty?
            div(class: "rounded-lg border border-dashed border-border py-16 text-center") do
              p(class: "text-muted-foreground text-sm") { t("authors.show.no_articles") }
            end
          else
            div(class: "grid grid-cols-1 gap-5 sm:grid-cols-2") do
              @articles.each do |article|
                render Components::Landing::ArticleCard.new(article: article)
              end
            end

            render Show::Pagination.new(pagy: @pagy, username: @presenter.username) if @pagy.pages > 1
          end
        end
      end
    end
  end
end
