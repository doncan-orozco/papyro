module Views
  module Home
    class Index < Views::Base
      def view_template
        div(class: "min-h-screen bg-background text-foreground") do
          render_header

          main(class: "relative") do
            render_hero
            render_curated_content
            render_bottom_cta
          end
        end
      end

      private

      def render_header
        header(class: "sticky top-0 z-50 border-b border-border bg-background/90 backdrop-blur supports-[backdrop-filter]:bg-background/70") do
          div(class: "mx-auto flex h-16 w-full max-w-6xl items-center justify-between px-4") do
            link_to root_path, class: "inline-flex items-center gap-3", data: { turbo_frame: "_top", turbo_action: "advance" } do
              img(src: "/icon.svg", alt: "Papyro", class: "h-7 w-auto")
            end

            render Components::Ui::Button.new(as: :a, href: new_session_path, variant: :outline, size: :sm) do
              t("pages.home.index.header.sign_in")
            end
          end
        end
      end

      def render_hero
        section(class: "relative overflow-hidden border-b border-border px-4 py-14 sm:py-16 lg:py-20") do
          div(class: "pointer-events-none absolute inset-0") do
            div(class: "absolute left-1/2 top-0 h-64 w-64 -translate-x-1/2 rounded-full bg-primary/5 blur-3xl")
            div(class: "absolute -left-16 bottom-10 h-48 w-48 rounded-full bg-primary/10 blur-3xl")
          end

          div(class: "relative mx-auto grid w-full max-w-6xl gap-8 lg:grid-cols-[1.2fr_0.8fr] lg:items-center") do
            div do
              p(class: "mb-4 text-sm font-medium uppercase tracking-[0.18em] text-muted-foreground") do
                t("pages.home.index.hero.eyebrow")
              end

              h1(class: "max-w-3xl font-serif text-4xl font-semibold tracking-tight sm:text-5xl md:text-6xl") do
                t("pages.home.index.hero.title")
              end

              p(class: "mt-5 max-w-2xl text-lg leading-relaxed text-muted-foreground sm:text-xl") do
                t("pages.home.index.hero.description")
              end

              div(class: "mt-9 flex flex-col gap-3 sm:flex-row sm:items-center") do
                render Components::Ui::Button.new(as: :a, href: new_session_path, size: :lg) do
                  t("pages.home.index.hero.create_blog")
                end

                render Components::Ui::Button.new(as: :a, href: new_session_path, variant: :ghost, size: :lg) do
                  t("pages.home.index.hero.sign_in")
                end
              end
            end

            render Components::Ui::Card.new(class: "border-border/70 bg-card/95 shadow-sm") do
              render Components::Ui::CardHeader.new do
                render Components::Ui::Badge.new(variant: :secondary, class: "w-fit") do
                  t("pages.home.index.hero.highlight_badge")
                end

                render Components::Ui::CardTitle.new(class: "font-serif text-2xl tracking-tight") do
                  t("pages.home.index.hero.highlight_title")
                end
              end

              render Components::Ui::CardContent.new(class: "space-y-4") do
                p(class: "text-muted-foreground") do
                  t("pages.home.index.hero.highlight_description")
                end

                render Components::Ui::Button.new(as: :a, href: new_session_path, class: "w-full", size: :lg) do
                  t("pages.home.index.hero.create_blog")
                end
              end
            end
          end
        end
      end

      def render_curated_content
        section(class: "px-4 py-14 sm:py-16 lg:py-20") do
          div(class: "mx-auto w-full max-w-6xl") do
            h2(class: "font-serif text-3xl font-semibold tracking-tight sm:text-4xl") do
              t("pages.home.index.curated.title")
            end

            p(class: "mt-3 max-w-3xl text-muted-foreground") do
              t("pages.home.index.curated.description")
            end

            div(class: "mt-6 flex flex-wrap gap-2") do
              render Components::Ui::Badge.new(variant: :secondary) { t("pages.home.index.curated.trending") }
              render Components::Ui::Badge.new(variant: :secondary) { t("pages.home.index.curated.featured") }
              render Components::Ui::Badge.new(variant: :secondary) { t("pages.home.index.curated.recent") }
            end

            turbo_frame_tag("featured_articles", src: featured_articles_path, loading: :lazy)
          end
        end
      end

      def render_bottom_cta
        section(class: "border-t border-border bg-muted/30 px-4 py-14 sm:py-16") do
          div(class: "mx-auto w-full max-w-4xl rounded-2xl border border-border bg-card px-6 py-10 text-center shadow-sm sm:px-10") do
            h2(class: "font-serif text-3xl font-semibold tracking-tight sm:text-4xl") do
              t("pages.home.index.bottom.title")
            end

            p(class: "mx-auto mt-4 max-w-2xl text-muted-foreground") do
              t("pages.home.index.bottom.description")
            end

            div(class: "mt-8 flex flex-col gap-3 sm:flex-row sm:justify-center") do
              render Components::Ui::Button.new(as: :a, href: new_session_path, size: :lg) do
                t("pages.home.index.bottom.create_blog")
              end

              render Components::Ui::Button.new(as: :a, href: new_session_path, variant: :outline, size: :lg) do
                t("pages.home.index.bottom.sign_in")
              end
            end
          end
        end
      end
    end
  end
end
