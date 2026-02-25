module Components
  module Landing
    class Hero < Components::Base
      def view_template
        section(class: "relative grid grid-cols-1 md:grid-cols-2 bg-background text-foreground") do
          # Photo Section - Left Side
          div(class: "relative h-96 md:h-[75vh]") do
            img(
              src: "/doncan-photo.png",
              alt: "Doncan Orozco",
              class: "w-full h-full object-cover"
            )
          end

          # Content Section - Right Side
          div(class: "flex items-start md:items-center px-6 md:px-12 py-16 md:py-24 bg-primary text-primary-foreground") do
            div(class: "max-w-xl") do
              h1(class: "text-5xl md:text-6xl lg:text-7xl font-bold mb-4 tracking-tight") { t("components.landing.hero.title") }

              p(class: "text-xl md:text-2xl opacity-90 mb-6 font-medium") do
                t("components.landing.hero.subtitle")
              end

              p(class: "text-base md:text-lg opacity-80 mb-10 leading-relaxed") do
                t("components.landing.hero.description")
              end

              render Components::Ui::Button.new(
                variant: :secondary,
                size: :lg
              ) { t("components.landing.hero.cta") }
            end
          end
        end
      end
    end
  end
end
