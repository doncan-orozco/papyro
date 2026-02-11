module Views
  module Articles
    class Featured < Views::Base
      def initialize(articles)
        @articles = articles
      end

      def view_template
        turbo_frame_tag("featured_articles") do
          render Components::Landing::FeaturedArticles.new(@articles)
        end
      end
    end
  end
end
