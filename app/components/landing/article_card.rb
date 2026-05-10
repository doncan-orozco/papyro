module Components
  module Landing
    class ArticleCard < Components::Base
      include Phlex::Rails::Helpers::ImageTag

      def initialize(article:, **attrs)
        @article = article
        @attrs = attrs
      end

      def view_template
        link_to article_path(@article), class: card_classes, **attrs_without_class do
          if @article.cover_image.attached?
            div(class: "w-full overflow-hidden border-b border-border/50") do
              image_tag(
                @article.cover_image,
                alt: @article.title,
                class: "aspect-[2/1] w-full transform object-cover grayscale opacity-80 transition-all duration-700 ease-in-out group-hover:scale-105 group-hover:grayscale-0 group-hover:opacity-100"
              )
            end
          end

          div(class: "flex flex-1 flex-col justify-between p-6") do
            div(class: "flex flex-col gap-4") do
              div(class: "flex items-center gap-2") do
                div(class: "flex h-6 w-6 items-center justify-center rounded-full border border-border bg-muted text-[10px] font-bold text-muted-foreground") do
                  plain article_author_initial
                end

                span(class: "text-sm font-medium text-foreground") do
                  article_author_name
                end
              end

              div do
                h3(class: "mb-2 text-xl font-bold leading-tight text-card-foreground decoration-muted-foreground/50 underline-offset-4 group-hover:underline") do
                  @article.title
                end

                p(class: "line-clamp-3 text-sm leading-relaxed text-muted-foreground") do
                  article_description
                end
              end
            end

            div(class: "mt-6 flex items-center gap-1.5 text-xs text-muted-foreground") do
              if @article.published_at.present?
                span { I18n.l(@article.published_at.to_date, format: :short) }
                span { "·" }
              end

              span { t("components.landing.article_card.reading_time", minutes: reading_time_for(@article)) }
            end
          end
        end
      end

      private

      def card_classes
        cn(
          "group flex h-full flex-col overflow-hidden rounded-xl border border-border bg-card p-0 transition-all hover:border-foreground/30 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring",
          @attrs&.dig(:class)
        )
      end

      def article_description
        @article.excerpt.presence || @article.searchable_content.to_s.truncate(180)
      end

      def article_author_name
        @article.user&.author_display_name || t("components.landing.article_card.unknown_author")
      end

      def article_author_initial
        article_author_name.first.to_s.upcase.presence || "?"
      end

      def reading_time_for(article)
        words = article.searchable_content.to_s.split.size
        [ (words / Article::WORDS_PER_MINUTE.to_f).ceil, 1 ].max
      end
    end
  end
end
