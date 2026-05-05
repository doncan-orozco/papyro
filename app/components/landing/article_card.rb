module Components
  module Landing
    class ArticleCard < Components::Base
      def initialize(title:, description:, date:, reading_time:, href: nil, bordered: true, **attrs)
        @title = title
        @description = description
        @date = date
        @reading_time = reading_time
        @href = href
        @bordered = bordered
        @attrs = attrs
      end

      def view_template
        tag_name = @href.present? ? :a : :div
        border_classes = @bordered ? "border border-border hover:border-border/80" : ""
        attrs = {
          class: "group block bg-card p-6 rounded-lg #{border_classes} hover:shadow-lg transition-all cursor-pointer focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring".strip
        }
        attrs[:href] = @href if @href.present?

        public_send(tag_name, **attrs, **@attrs) do
          div(class: "flex justify-between items-start mb-3") do
            span(class: "text-sm text-muted-foreground") { @date }
            span(class: "text-xs bg-muted text-muted-foreground px-2 py-1 rounded") { @reading_time }
          end

          h3(class: "text-xl font-semibold text-card-foreground mb-2 group-hover:text-foreground") { @title }
          p(class: "text-muted-foreground text-sm leading-relaxed") { @description }

          div(class: "mt-4 flex items-center text-card-foreground text-sm font-medium group-hover:gap-2 gap-0 transition-all") do
            span { t("components.landing.article_card.read_more") }
            span { "→" }
          end
        end
      end
    end
  end
end
