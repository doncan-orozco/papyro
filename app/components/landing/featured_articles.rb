module Components
  module Landing
    class FeaturedArticles < Components::Base
      def initialize(articles)
        @articles = articles
      end

      def view_template
        section(class: "py-20 px-4 bg-slate-50") do
          div(class: "max-w-4xl mx-auto") do
            h2(class: "text-4xl md:text-5xl font-bold text-slate-900 mb-12 text-center") { t("components.landing.featured_articles.title") }

            if @articles.any?
              div(class: "grid md:grid-cols-2 gap-6") do
                @articles.each do |article|
                  render Components::Landing::ArticleCard.new(
                    title: article.title,
                    description: article.excerpt || article.content.to_plain_text.truncate(150),
                    date: I18n.l(article.published_at.to_date, format: :short),
                    reading_time: "#{(article.content.to_plain_text.split.size / 200.0).ceil} min read",
                    data: { turbo_frame: "_top", turbo_action: "advance" }
                  )
                end
              end

              div(class: "text-center mt-12") do
                render Components::Ui::Button.new(
                  variant: :outline,
                  size: :lg
                ) { t("components.landing.featured_articles.view_all") }
              end
            else
              p(class: "text-center text-slate-600") { t("components.landing.featured_articles.no_articles") }
            end
          end
        end
      end
    end
  end
end
