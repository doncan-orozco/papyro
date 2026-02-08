module Views
  module Home
    class Index < Views::Base
      def view_template
        div(class: "min-h-screen bg-white") do
          render Components::Landing::Hero.new
          render Components::Landing::About.new

          turbo_frame_tag("featured_articles", src: featured_articles_path, loading: :lazy)

          render Components::Landing::Contact.new
        end
      end
    end
  end
end
