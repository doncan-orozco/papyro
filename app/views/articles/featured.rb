module Views
  module Articles
    class Featured < Views::Base
      def view_template
        turbo_frame_tag("featured_articles") do
          render Components::Landing::FeaturedArticles.new
        end
      end
    end
  end
end
