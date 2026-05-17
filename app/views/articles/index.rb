# frozen_string_literal: true

module Views
  module Articles
    class Index < Views::Base
      def initialize(articles:, show_welcome_hero: false)
        @articles = articles
        @show_welcome_hero = show_welcome_hero
      end

      def view_template
        div(class: "min-h-screen bg-background text-foreground") do
          render Components::Public::Navbar.new

          main(class: "relative overflow-hidden") do
            render Components::Public::WelcomeHero.new if @show_welcome_hero

            div(class: "pointer-events-none absolute inset-x-0 top-0 h-80 bg-[radial-gradient(circle_at_top,rgba(15,23,42,0.06),transparent_60%)]")

            section(class: "px-4 pb-8 pt-12 sm:pb-10 sm:pt-16") do
              div(class: "mx-auto w-full max-w-6xl") do
                p(class: "text-xs font-semibold uppercase tracking-[0.2em] text-muted-foreground") do
                  t("articles.index.eyebrow")
                end

                div(class: "mt-4 flex flex-col gap-6 lg:flex-row lg:items-end lg:justify-between") do
                  div(class: "max-w-3xl") do
                    h1(class: "font-serif text-4xl font-semibold tracking-tight text-foreground sm:text-5xl md:text-6xl") do
                      t("articles.index.title")
                    end
                    p(class: "mt-4 max-w-2xl text-base leading-relaxed text-muted-foreground sm:text-lg") do
                      t("articles.index.subtitle")
                    end
                  end

                  div(class: "rounded-full border border-border bg-card/80 px-4 py-2 text-sm text-muted-foreground shadow-sm") do
                    span(class: "font-medium text-foreground") { @articles.size }
                    plain " "
                    plain t("articles.index.results")
                  end
                end
              end
            end

            section(class: "px-4 pb-14 sm:pb-16") do
              div(class: "mx-auto w-full max-w-6xl") do
                if @articles.any?
                  div(class: "grid grid-cols-1 gap-8 md:grid-cols-2") do
                    @articles.each do |article|
                      render Components::Landing::ArticleCard.new(
                        article: article,
                        data: { turbo_frame: "_top", turbo_action: "advance" }
                      )
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
