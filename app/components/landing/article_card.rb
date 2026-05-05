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
          class: "group block rounded-xl bg-card/95 p-6 #{border_classes} shadow-sm transition-all duration-300 hover:-translate-y-0.5 hover:shadow-xl cursor-pointer focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring".strip
        }
        attrs[:href] = @href if @href.present?

        public_send(tag_name, **attrs, **@attrs) do
          div(class: "mb-4 flex items-center justify-between gap-3") do
            span(class: "text-xs uppercase tracking-[0.14em] text-muted-foreground/90") { @date }

            if @reading_time.present?
              span(class: "inline-flex items-center rounded-full border border-border bg-muted/50 px-2.5 py-1 text-[11px] font-medium text-muted-foreground") { @reading_time }
            end
          end

          h3(class: "text-xl font-semibold leading-tight text-card-foreground transition-colors duration-300 group-hover:text-foreground") do
            span(class: "line-clamp-2") { @title }
          end

          p(class: "mt-3 text-sm leading-relaxed text-muted-foreground") do
            span(class: "line-clamp-3") { @description }
          end

          div(class: "mt-5 inline-flex items-center gap-1 text-sm font-medium text-card-foreground transition-all duration-300 group-hover:gap-2") do
            span { t("components.landing.article_card.read_more") }
            span(class: "transition-transform duration-300 group-hover:translate-x-0.5") { "→" }
          end
        end
      end
    end
  end
end
