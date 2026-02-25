module Components
  module Landing
    class About < Components::Base
      def view_template
        section(class: "py-20 px-4 bg-background") do
          div(class: "max-w-4xl mx-auto") do
            h2(class: "text-4xl md:text-5xl font-bold text-foreground mb-8") { t("components.landing.about.title") }

            div(class: "grid md:grid-cols-2 gap-8") do
              div(class: "space-y-4 max-w-none") do
                p(class: "text-lg text-muted-foreground leading-relaxed mb-4") { t("components.landing.about.bio_paragraph_1") }
                p(class: "text-lg text-muted-foreground leading-relaxed mb-4") { t("components.landing.about.bio_paragraph_2") }
                p(class: "text-lg text-muted-foreground leading-relaxed") { t("components.landing.about.bio_paragraph_3") }
              end

              div(class: "flex flex-col gap-4") do
                div(class: "bg-muted p-6 rounded-lg") do
                  h3(class: "font-semibold text-foreground mb-2") { t("components.landing.about.expertise_title") }
                  ul(class: "space-y-2 text-muted-foreground") do
                    li { t("components.landing.about.expertise_1") }
                    li { t("components.landing.about.expertise_2") }
                    li { t("components.landing.about.expertise_3") }
                    li { t("components.landing.about.expertise_4") }
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
