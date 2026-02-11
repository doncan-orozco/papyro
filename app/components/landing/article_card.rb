module Components
  module Landing
    class ArticleCard < Components::Base
      def initialize(title:, description:, date:, reading_time:, **attrs)
        @title = title
        @description = description
        @date = date
        @reading_time = reading_time
        @attrs = attrs
      end

      def view_template
        div(class: "group bg-white p-6 rounded-lg border border-slate-200 hover:border-slate-400 hover:shadow-lg transition-all cursor-pointer", **@attrs) do
          div(class: "flex justify-between items-start mb-3") do
            span(class: "text-sm text-slate-500") { @date }
            span(class: "text-xs bg-slate-100 text-slate-700 px-2 py-1 rounded") { @reading_time }
          end

          h3(class: "text-xl font-semibold text-slate-900 mb-2 group-hover:text-slate-700") { @title }
          p(class: "text-slate-600 text-sm leading-relaxed") { @description }

          div(class: "mt-4 flex items-center text-slate-900 text-sm font-medium group-hover:gap-2 gap-0 transition-all") do
            span { t("components.landing.article_card.read_more") }
            span { "→" }
          end
        end
      end
    end
  end
end
