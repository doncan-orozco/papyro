module Views
  module Users
    class Show < Views::Base
      def initialize(user:, viewer_user_id: nil)
        @user = user
        @viewer_user_id = viewer_user_id
      end

      def view_template
        div(class: "min-h-screen bg-background text-foreground") do
          render Components::Public::Navbar.new

          main(class: "mx-auto w-full max-w-3xl px-4 py-10") do
            render Components::Ui::Card.new do |card|
              card.header do
                card.title { t("users.show.title") }
                card.description { t("users.show.description") }
              end

              card.content(class: "space-y-4") do
                p(class: "text-sm text-foreground/80") { t("users.show.display_name_label") }
                p(class: "text-base font-medium") { @user.author_display_name }

                if @viewer_user_id == @user.id
                  render Components::Ui::Button.new(as: :a, href: edit_settings_profile_path) do
                    t("users.show.edit_profile")
                  end
                end
              end
            end
          end
        end
      end
    end
  end
end
