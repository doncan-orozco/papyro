module Components
  module Landing
    class Hero < Components::Base
      def view_template
        section(class: "relative min-h-screen grid grid-cols-1 md:grid-cols-2 bg-gradient-to-br from-slate-900 to-slate-800 text-white") do
          # Content Section - Right Side (first on mobile)
          div(class: "flex items-center px-6 md:px-12 py-16 md:py-20 md:order-2") do
            div(class: "max-w-xl") do
              h1(class: "text-5xl md:text-6xl lg:text-7xl font-bold mb-4 tracking-tight") { t("components.landing.hero.title") }

              p(class: "text-xl md:text-2xl text-slate-200 mb-6 font-medium") do
                t("components.landing.hero.subtitle")
              end

              p(class: "text-base md:text-lg text-slate-400 mb-10 leading-relaxed") do
                t("components.landing.hero.description")
              end

              render Components::Ui::Button.new(
                variant: :ghost,
                size: :lg
              ) { t("components.landing.hero.cta") }
            end
          end

          # Photo Section - Left Side (second on mobile, first on desktop)
          div(class: "relative min-h-screen md:order-1") do
            img(
              src: "/doncan-photo.png",
              alt: "Doncan Orozco",
              class: "w-full h-full object-cover"
            )
          end
        end
      end
    end
  end
end
