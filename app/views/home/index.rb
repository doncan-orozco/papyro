module Views
  module Home
    class Index < Views::Base
      def view_template
        div(class: "min-h-screen bg-white") do
          render Components::Ui::Card.new(class: "mx-auto mt-10 max-w-2xl") do
            render Components::Ui::CardHeader.new do
              render Components::Ui::CardTitle.new do
                "Welcome to the Home Page"
              end
              render Components::Ui::CardDescription.new do
                "This is the home page of our application. Explore the features and enjoy your stay!"
              end
            end
          end

          # render Components::Landing::Hero.new
          # render Components::Landing::About.new

          # turbo_frame_tag("featured_articles", src: featured_articles_path, loading: :lazy)

          # render Components::Landing::Contact.new
        end
      end
    end
  end
end
