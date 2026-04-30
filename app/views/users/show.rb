module Views
  module Users
    class Show < Views::Base
      def initialize(user:)
        @user = user
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
                p(class: "text-sm text-muted-foreground") { t("users.show.display_name_label") }
                p(class: "text-base font-medium") { @user.author_display_name }

                p(class: "text-sm text-muted-foreground") { t("users.show.email_label") }
                p(class: "text-base font-medium") { @user.email_address }

                if Current.user&.id == @user.id
                  render Components::Ui::Button.new(as: :a, href: edit_user_path(@user)) do
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
