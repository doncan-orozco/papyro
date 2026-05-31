module Components
  module Landing
    class ArticleCard < Components::Base
      include Phlex::Rails::Helpers::ImageTag

      def initialize(article:, **attrs)
        @article = article
        @attrs = attrs
      end

      def view_template
        link_to article_path(@article), class: card_classes, **link_attributes do
          cover_image_section

          div(class: "flex flex-1 flex-col justify-between p-6") do
            div(class: "flex flex-col gap-4") do
              div(class: "flex items-center gap-2") do
                div(class: "flex h-6 w-6 items-center justify-center rounded-full border border-border bg-muted text-[10px] font-bold text-foreground/80", aria_hidden: "true") do
                  plain article_author_initial
                end

                span(class: "text-sm font-medium text-foreground") do
                  article_author_name
                end
              end

              div do
                h3(class: "mb-2 text-xl font-bold leading-tight text-card-foreground decoration-muted-foreground/50 underline-offset-4 group-hover:underline group-focus-visible:underline") do
                  @article.title
                end

                p(class: "line-clamp-3 text-sm leading-relaxed text-foreground/80") do
                  article_description
                end
              end
            end

            div(class: "mt-6 flex items-center gap-1.5 text-xs text-foreground/80") do
              if @article.published_at.present?
                time(datetime: @article.published_at.iso8601) { I18n.l(@article.published_at.to_date, format: :short) }
                span { "·" }
              end

              span { t("components.landing.article_card.reading_time", minutes: reading_time_for(@article)) }
            end
          end
        end
      end

      private

      def cover_image_section
        div(class: "w-full overflow-hidden border-b border-border/50") do
          if @article.cover_image.attached?
            image_tag(
              @article.cover_image,
              alt: @article.title,
              class: "aspect-[2/1] w-full transform object-cover grayscale opacity-80 motion-safe:transition-all motion-safe:duration-700 ease-in-out group-hover:scale-105 group-hover:grayscale-0 group-hover:opacity-100 group-focus-visible:scale-105 group-focus-visible:grayscale-0 group-focus-visible:opacity-100"
            )
          else
            div(class: "relative aspect-[2/1] w-full overflow-hidden bg-gradient-to-br from-muted/55 via-muted/35 to-muted/70 motion-safe:transition-colors motion-safe:duration-700 group-hover:from-blue-500/10 group-hover:to-blue-500/5 group-focus-visible:from-blue-500/10 group-focus-visible:to-blue-500/5 dark:group-hover:from-blue-400/20 dark:group-hover:to-blue-400/10 dark:group-focus-visible:from-blue-400/20 dark:group-focus-visible:to-blue-400/10") do
              div(class: "pointer-events-none absolute inset-0 bg-blue-500/5 opacity-0 motion-safe:transition-opacity motion-safe:duration-700 group-hover:opacity-100 group-focus-visible:opacity-100 dark:bg-blue-400/10")

              span(
                class: "pointer-events-none absolute -inset-4 text-[4rem] font-black uppercase leading-[0.85] tracking-tighter text-foreground/10 dark:text-foreground/20 select-none break-words motion-safe:transition-transform motion-safe:duration-700 ease-in-out group-hover:scale-105 group-focus-visible:scale-105 md:text-[5rem]",
                aria_hidden: "true"
              ) do
                plain fallback_texture_text
              end

              div(class: "relative z-10 flex h-full w-full items-center justify-center p-6") do
                div(class: "rounded-full border border-foreground/10 bg-background/65 px-4 py-1.5 text-[10px] font-bold uppercase tracking-[0.2em] text-foreground shadow-sm backdrop-blur-md motion-safe:transition-colors motion-safe:duration-700 group-hover:border-rose-600 group-hover:bg-rose-600 group-hover:text-white group-focus-visible:border-rose-600 group-focus-visible:bg-rose-600 group-focus-visible:text-white") do
                  plain "PAPYRO"
                end
              end
            end
          end
        end
      end

      def fallback_texture_text
        seed = @article.title.to_s.strip
        seed = article_author_name if seed.blank?

        (("#{seed} ") * 6).upcase
      end

      def card_classes
        cn(
          "group flex h-full flex-col overflow-hidden rounded-xl border border-border bg-card p-0 motion-safe:transition-all hover:border-foreground/30 focus-visible:border-foreground/40 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring dark:border-foreground/15",
          @attrs&.dig(:class)
        )
      end

      def link_attributes
        attrs_without_class.deep_dup.tap do |attributes|
          attributes[:aria] = attributes.fetch(:aria, {}).merge(label: article_accessibility_label)
        end
      end

      def article_description
        @article.excerpt.presence || content_analysis.searchable_content.to_s.truncate(180)
      end

      def article_author_name
        @article.user&.author_display_name || t("components.landing.article_card.unknown_author")
      end

      def article_author_initial
        article_author_name.first.to_s.upcase.presence || "?"
      end

      def article_accessibility_label
        t(
          "components.landing.article_card.link_label",
          title: @article.title,
          author: article_author_name,
          minutes: reading_time_for(@article)
        )
      end

      def reading_time_for(article)
        return content_analysis.estimated_reading_time_minutes if article == @article

        self.class.content_analysis_for(article, locale: I18n.locale).estimated_reading_time_minutes
      end

      def content_analysis
        @content_analysis ||= self.class.content_analysis_for(@article, locale: I18n.locale)
      end

      def self.content_analysis_for(article, locale: nil)
        Articles::Service::ContentAnalysis.new(article, locale: locale)
      end
    end
  end
end
