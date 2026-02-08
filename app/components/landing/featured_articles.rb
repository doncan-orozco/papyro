module Components
  module Landing
    class FeaturedArticles < Components::Base
      def view_template
        section(class: "py-20 px-4 bg-slate-50") do
          div(class: "max-w-4xl mx-auto") do
            h2(class: "text-4xl md:text-5xl font-bold text-slate-900 mb-12 text-center") { t(".title") }

            div(class: "grid md:grid-cols-2 gap-6") do
              render Components::Landing::ArticleCard.new(
                title: "Getting Started with Rails 8",
                description: "Explore the latest features in Rails 8 and how to leverage them in your projects.",
                date: "Feb 7, 2026",
                reading_time: "5 min read"
              )

              render Components::Landing::ArticleCard.new(
                title: "Building Real-time Apps with Hotwire",
                description: "Learn how to create interactive applications using Hotwire and Action Cable.",
                date: "Feb 5, 2026",
                reading_time: "8 min read"
              )

              render Components::Landing::ArticleCard.new(
                title: "Scaling SQLite for Production",
                description: "Discover techniques for optimizing SQLite in production environments.",
                date: "Jan 30, 2026",
                reading_time: "12 min read"
              )

              render Components::Landing::ArticleCard.new(
                title: "The Future of Ruby Web Development",
                description: "Thoughts on where the Ruby ecosystem is heading and what's next.",
                date: "Jan 25, 2026",
                reading_time: "6 min read"
              )
            end

            div(class: "text-center mt-12") do
              render Components::Ui::Button.new(
                variant: :outline,
                size: :lg
              ) { t(".view_all") }
            end
          end
        end
      end
    end
  end
end
