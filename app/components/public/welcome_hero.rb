# frozen_string_literal: true

module Components
  module Public
    class WelcomeHero < Components::Base
      def view_template
        section(class: "relative overflow-hidden border-b border-border px-4 py-14 sm:py-16 lg:py-20") do
          div(class: "pointer-events-none absolute inset-0") do
            div(class: "absolute left-1/2 top-0 h-64 w-64 -translate-x-1/2 rounded-full bg-primary/5 blur-3xl")
            div(class: "absolute -left-16 bottom-10 h-48 w-48 rounded-full bg-primary/10 blur-3xl")
          end

          div(class: "relative mx-auto grid w-full max-w-6xl gap-8 lg:grid-cols-[1.2fr_0.8fr] lg:items-center") do
            div do
              p(class: "mb-4 text-sm font-medium uppercase tracking-[0.18em] text-muted-foreground") do
                t("components.public.welcome_hero.eyebrow")
              end

              h1(class: "max-w-3xl font-serif text-4xl font-semibold tracking-tight sm:text-5xl md:text-6xl") do
                t("components.public.welcome_hero.title")
              end

              p(class: "mt-5 max-w-2xl text-lg leading-relaxed text-muted-foreground sm:text-xl") do
                t("components.public.welcome_hero.description")
              end
            end

            render Components::Ui::Card.new(class: "border-border/70 bg-card/95 shadow-sm") do
              render Components::Ui::CardHeader.new do
                render Components::Ui::CardTitle.new(class: "font-serif text-2xl tracking-tight") do
                  t("components.public.welcome_hero.join_title")
                end
              end

              render Components::Ui::CardContent.new(class: "space-y-4") do
                p(class: "text-muted-foreground") do
                  t("components.public.welcome_hero.join_description")
                end

                render Components::Ui::Button.new(
                  as: :a,
                  href: "mailto:info@papyro.net?subject=Join%20Papyro%20Community&body=I%20would%20like%20to%20join%20the%20Papyro%20community.",
                  variant: :outline,
                  class: "w-full",
                  size: :lg
                ) do
                  t("components.public.welcome_hero.join_cta")
                end
              end
            end
          end
        end
      end
    end
  end
end
