module Components
  module Landing
    class FeaturedArticles < Components::Base
      def initialize(articles)
        @articles = articles
      end

      def view_template
        section(class: "py-20 px-4 bg-background") do
          div(class: "max-w-4xl mx-auto") do
            h2(class: "text-4xl md:text-5xl font-bold text-foreground mb-12 text-center") { t("components.landing.featured_articles.title") }

            if @articles.any?
              div(class: "grid md:grid-cols-2 gap-6") do
                @articles.each do |article|
                  render Components::Landing::ArticleCard.new(
                    title: article.title,
                    description: article.excerpt || article.searchable_content.truncate(150),
                    date: I18n.l(article.published_at.to_date, format: :short),
                    reading_time: t("components.landing.featured_articles.reading_time", minutes: reading_time_for(article)),
                    href: article_path(article),
                    data: { turbo_frame: "_top", turbo_action: "advance" }
                  )
                end
              end

              div(class: "text-center mt-12") do
                render Components::Ui::Button.new(
                  as: :a,
                  href: articles_path,
                  variant: :outline,
                  size: :lg,
                  data: { turbo_frame: "_top", turbo_action: "advance" }
                ) { t("components.landing.featured_articles.view_all") }
              end
            else
              p(class: "text-center text-muted-foreground") { t("components.landing.featured_articles.no_articles") }
            end
          end
        end
      end

      private

      def reading_time_for(article)
        words = article.searchable_content.to_s.split.size
        [ (words / 200.0).ceil, 1 ].max
      end
    end
  end
end
