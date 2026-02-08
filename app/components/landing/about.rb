module Components
  module Landing
    class About < Components::Base
      def view_template
        section(class: "py-20 px-4 bg-white") do
          div(class: "max-w-4xl mx-auto") do
            h2(class: "text-4xl md:text-5xl font-bold text-slate-900 mb-8") { t(".title") }

            div(class: "grid md:grid-cols-2 gap-8") do
              div(class: "prose prose-slate max-w-none") do
                p(class: "text-lg text-slate-700 leading-relaxed mb-4") { t(".bio_paragraph_1") }
                p(class: "text-lg text-slate-700 leading-relaxed mb-4") { t(".bio_paragraph_2") }
                p(class: "text-lg text-slate-700 leading-relaxed") { t(".bio_paragraph_3") }
              end

              div(class: "flex flex-col gap-4") do
                div(class: "bg-slate-50 p-6 rounded-lg") do
                  h3(class: "font-semibold text-slate-900 mb-2") { t(".expertise_title") }
                  ul(class: "space-y-2 text-slate-700") do
                    li { t(".expertise_1") }
                    li { t(".expertise_2") }
                    li { t(".expertise_3") }
                    li { t(".expertise_4") }
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
