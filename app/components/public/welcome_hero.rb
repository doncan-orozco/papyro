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

          div(class: "relative mx-auto w-full max-w-6xl") do
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

              div(class: "mt-8 flex flex-wrap items-center gap-3") do
                render Components::Ui::Button.new(
                  as: :a,
                  href: sign_up_path,
                  size: :lg,
                  data: { turbo_frame: "_top", turbo_action: "advance" }
                ) do
                  t("components.public.welcome_hero.primary_cta")
                end

                link_to(
                  t("components.public.welcome_hero.secondary_cta"),
                  new_session_path,
                  class: "px-2 py-1 text-sm font-medium text-muted-foreground transition-colors hover:text-foreground",
                  data: { turbo_frame: "_top", turbo_action: "advance" }
                )
              end
            end
          end
        end
      end
    end
  end
end
