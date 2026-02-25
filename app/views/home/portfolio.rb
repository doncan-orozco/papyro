module Views
  module Home
    class Portfolio < Views::Base
      def view_template
        render Components::Landing::Hero.new
        render Components::Landing::About.new

        turbo_frame_tag("featured_articles", src: featured_articles_path, loading: :lazy)

        render Components::Landing::Contact.new
      end
    end
  end
end
