# frozen_string_literal: true

module Views
  module Articles
    class Index < Views::Base
      def initialize(articles:, show_welcome_hero: false, pagy: nil)
        @articles = articles
        @show_welcome_hero = show_welcome_hero
        @pagy = pagy
      end

      def view_template
        div(class: "min-h-screen bg-background text-foreground") do
          render Components::Public::Navbar.new

          main(class: "relative overflow-hidden") do
            render Components::Public::WelcomeHero.new if @show_welcome_hero

            div(class: "pointer-events-none absolute inset-x-0 top-0 h-80 bg-[radial-gradient(circle_at_top,rgba(15,23,42,0.06),transparent_60%)]")

            section(class: "px-4 pb-8 pt-12 sm:pb-10 sm:pt-16") do
              div(class: "mx-auto w-full max-w-2xl") do
                p(class: "text-xs font-semibold uppercase tracking-[0.2em] text-foreground/80") do
                  t("articles.index.eyebrow")
                end

                div(class: "mt-4 max-w-3xl") do
                  h1(class: "font-serif text-4xl font-semibold tracking-tight text-foreground sm:text-5xl md:text-6xl") do
                    t("articles.index.title")
                  end
                  p(class: "mt-4 max-w-2xl text-base leading-relaxed text-foreground/75 sm:text-lg") do
                    t("articles.index.subtitle")
                  end
                  div(class: "mt-4 inline-block rounded-full border border-border bg-card/80 px-4 py-2 text-sm text-foreground/80 shadow-sm") do
                    span(class: "font-medium text-foreground") { @pagy&.count || @articles.size }
                    plain " "
                    plain t("articles.index.results")
                  end
                end
              end
            end

            section(class: "px-4 pb-14 sm:pb-16") do
              div(class: "mx-auto w-full max-w-2xl") do
                if @articles.any?
                  div(id: "articles_feed", class: "flex flex-col divide-y divide-border/40") do
                    @articles.each do |article|
                      div(class: "py-12") do
                        render Components::Landing::ArticleCard.new(
                          article: article,
                          data: { turbo_frame: "_top", turbo_action: "advance" }
                        )
                      end
                    end
                  end

                  if @pagy&.next
                    div(id: "load_more_container", class: "mt-12 flex justify-center pb-4") do
                      link_to t("articles.index.load_more"),
                        articles_path(page: @pagy.next),
                        data: { turbo_stream: true },
                        class: "inline-flex items-center justify-center rounded-full border border-border bg-background px-6 py-2.5 text-sm font-medium text-foreground/80 transition-colors hover:bg-muted hover:text-foreground focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring"
                    end
                  end
                else
                  div(class: "rounded-2xl border border-border bg-card p-8 text-center shadow-sm") do
                    p(class: "text-base font-medium text-foreground") { t("articles.index.empty_title") }
                    p(class: "mt-2 text-sm text-muted-foreground") { t("articles.index.empty_description") }
                  end
                end

                render Components::Public::Footer.new
              end
            end
          end
        end
      end
    end
  end
end
