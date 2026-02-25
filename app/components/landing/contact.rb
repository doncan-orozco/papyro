module Components
  module Landing
    class Contact < Components::Base
      def view_template
        section(class: "py-20 px-4 bg-background") do
          div(class: "max-w-2xl mx-auto text-center") do
            h2(class: "text-4xl md:text-5xl font-bold text-foreground mb-6") { t("components.landing.contact.title") }
            p(class: "text-xl text-muted-foreground mb-12") { t("components.landing.contact.description") }

            div(class: "flex flex-col sm:flex-row gap-4 justify-center") do
              render Components::Ui::Button.new(
                variant: :default,
                size: :lg
              ) { t("components.landing.contact.email") }

              div(class: "flex gap-4 justify-center") do
                render Components::Ui::SocialLink.new(
                  platform: "twitter",
                  url: "https://twitter.com/YOUR_HANDLE"
                )
                render Components::Ui::SocialLink.new(
                  platform: "github",
                  url: "https://github.com/YOUR_HANDLE"
                )
                render Components::Ui::SocialLink.new(
                  platform: "linkedin",
                  url: "https://linkedin.com/in/YOUR_PROFILE"
                )
              end
            end
          end
        end
      end
    end
  end
end
