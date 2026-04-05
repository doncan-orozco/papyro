module Views
  module Home
    class Index < Views::Base
      def view_template
        div(class: "min-h-screen bg-background text-foreground") do
          render Components::Public::Navbar.new

          main(class: "relative") do
            render_hero
            render_curated_content
            render_bottom_cta
            render_creators_section
          end
        end
      end

      private

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
                render Components::Ui::Tooltip.new do |tooltip|
                  tooltip.trigger(class: "pointer-events-auto") do
                    render Components::Ui::Button.new(as: :button, size: :lg, disabled: true, class: "pointer-events-none") do
                      t("pages.home.index.hero.create_blog")
                    end
                  end
                  tooltip.content { t("pages.home.index.coming_soon") }
                end


                render Components::Ui::Button.new(as: :a, href: new_session_path, variant: :ghost, size: :lg) do
                  t("pages.home.index.hero.sign_in")
                end
              end
            end

            # Original highlight card (keeping for reference)
            # render Components::Ui::Card.new(class: "border-border/70 bg-card/95 shadow-sm") do
            #   render Components::Ui::CardHeader.new do
            #     render Components::Ui::Badge.new(variant: :secondary, class: "w-fit") do
            #       t("pages.home.index.hero.highlight_badge")
            #     end
            #
            #     render Components::Ui::CardTitle.new(class: "font-serif text-2xl tracking-tight") do
            #       t("pages.home.index.hero.highlight_title")
            #     end
            #   end
            #
            #   render Components::Ui::CardContent.new(class: "space-y-4") do
            #     p(class: "text-muted-foreground") do
            #       t("pages.home.index.hero.highlight_description")
            #     end
            #
            #     render Components::Ui::Button.new(as: :a, href: new_session_path, class: "w-full", size: :lg) do
            #       t("pages.home.index.hero.create_blog")
            #     end
            #   end
            # end

            # Coming soon notice
            render Components::Ui::Card.new(class: "border-border/70 bg-card/95 shadow-sm") do
              render Components::Ui::CardHeader.new do
                render Components::Ui::Badge.new(variant: :secondary, class: "w-fit") do
                  t("pages.home.index.coming_soon")
                end

                render Components::Ui::CardTitle.new(class: "font-serif text-2xl tracking-tight") do
                  t("pages.home.index.hero.join_community_title")
                end
              end

              render Components::Ui::CardContent.new(class: "space-y-4") do
                p(class: "text-muted-foreground") do
                  t("pages.home.index.hero.join_community_description")
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
              render Components::Ui::Tooltip.new do |tooltip|
                tooltip.trigger(class: "pointer-events-auto") do
                  render Components::Ui::Button.new(as: :button, size: :lg, disabled: true, class: "pointer-events-none") do
                    t("pages.home.index.bottom.create_blog")
                  end
                end
                tooltip.content { t("pages.home.index.coming_soon") }
              end

              render Components::Ui::Button.new(as: :a, href: new_session_path, variant: :outline, size: :lg) do
                t("pages.home.index.bottom.sign_in")
              end
            end
          end
        end
      end

      def render_creators_section
        section(class: "border-t border-border/70 bg-background px-4 py-6 sm:py-8") do
          div(class: "mx-auto w-full max-w-5xl") do
            div(class: "max-w-2xl") do
              p(class: "text-[11px] font-medium uppercase tracking-[0.18em] text-muted-foreground") do
                t("pages.home.index.creators.eyebrow")
              end
            end

            div(class: "mt-4 grid gap-4 border-t border-border/60 pt-4 md:grid-cols-2") do
              render_creator_card(
                name: t("pages.home.index.creators.engineer.name"),
                role: t("pages.home.index.creators.engineer.role"),
                url: "https://linkedin.com/in/doncan-orozco"
              )

              render_creator_card(
                name: t("pages.home.index.creators.designer.name"),
                role: t("pages.home.index.creators.designer.role"),
                url: "https://linkedin.com/in/martha-ol%C3%A1n-067879304"
              )
            end
          end
        end
      end

      def render_creator_card(name:, role:, url:)
        article(class: "space-y-1") do
          a(
            href: url,
            target: "_blank",
            rel: "noopener noreferrer",
            class: "inline-flex items-center gap-2 text-sm text-foreground transition hover:text-primary"
          ) do
            span { name }
            render_linkedin_icon
          end
          p(class: "text-[11px] uppercase tracking-[0.14em] text-muted-foreground") { role }
        end
      end

      def render_linkedin_icon
        svg(
          class: "h-3.5 w-3.5 text-muted-foreground",
          fill: "currentColor",
          viewBox: "0 0 24 24",
          "aria-hidden": "true"
        ) do |s|
          s.path(d: "M20.447 20.452h-3.554v-5.569c0-1.328-.027-3.037-1.852-3.037-1.853 0-2.136 1.445-2.136 2.939v5.667H9.351V9h3.414v1.561h.046c.477-.9 1.637-1.85 3.37-1.85 3.601 0 4.267 2.37 4.267 5.455v6.286zM5.337 7.433c-1.144 0-2.063-.926-2.063-2.065 0-1.138.92-2.063 2.063-2.063 1.14 0 2.064.925 2.064 2.063 0 1.139-.925 2.065-2.064 2.065zm1.782 13.019H3.555V9h3.564v11.452zM22.225 0H1.771C.792 0 0 .774 0 1.729v20.542C0 23.227.792 24 1.771 24h20.451C23.2 24 24 23.227 24 22.271V1.729C24 .774 23.2 0 22.222 0h.003z")
        end
      end
    end
  end
end
