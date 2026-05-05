# frozen_string_literal: true

module Views
  module About
    class Index < Views::Base
      def view_template
        div(class: "min-h-screen bg-background text-foreground") do
          render Components::Public::Navbar.new

          main(class: "relative overflow-hidden") do
            div(class: "pointer-events-none absolute inset-x-0 top-0 h-80 bg-[radial-gradient(circle_at_top,rgba(15,23,42,0.06),transparent_60%)]")

            section(class: "px-4 pb-8 pt-12 sm:pb-10 sm:pt-16") do
              div(class: "mx-auto w-full max-w-3xl") do
                p(class: "text-xs font-semibold uppercase tracking-[0.2em] text-muted-foreground") do
                  t("pages.about.index.eyebrow")
                end

                h1(class: "mt-4 font-serif text-4xl font-semibold tracking-tight text-foreground sm:text-5xl") do
                  t("pages.about.index.title")
                end

                p(class: "mt-6 text-lg leading-relaxed text-muted-foreground") do
                  t("pages.about.index.intro")
                end
              end
            end

            section(class: "px-4 pb-10 sm:pb-14") do
              div(class: "mx-auto w-full max-w-3xl space-y-8") do
                div do
                  h2(class: "font-serif text-2xl font-semibold tracking-tight text-foreground") do
                    t("pages.about.index.philosophy_title")
                  end
                  p(class: "mt-4 text-base leading-relaxed text-muted-foreground") do
                    t("pages.about.index.philosophy_body")
                  end
                end

                div do
                  h2(class: "font-serif text-2xl font-semibold tracking-tight text-foreground") do
                    t("pages.about.index.built_for_title")
                  end
                  p(class: "mt-4 text-base leading-relaxed text-muted-foreground") do
                    t("pages.about.index.built_for_body")
                  end
                end

                div(class: "border-t border-border/40 pt-8") do
                  p(class: "text-xs font-semibold uppercase tracking-[0.2em] text-muted-foreground") do
                    t("pages.about.index.team_eyebrow")
                  end

                  div(class: "mt-6 grid grid-cols-1 gap-6 sm:grid-cols-2") do
                    div do
                      p(class: "text-base font-medium text-foreground") do
                        t("pages.about.index.engineer_name")
                      end
                      p(class: "mt-1 text-sm text-muted-foreground") do
                        t("pages.about.index.engineer_role")
                      end
                      p(class: "mt-2 text-sm leading-relaxed text-muted-foreground") do
                        t("pages.about.index.engineer_bio")
                      end
                    end

                    div do
                      p(class: "text-base font-medium text-foreground") do
                        t("pages.about.index.designer_name")
                      end
                      p(class: "mt-1 text-sm text-muted-foreground") do
                        t("pages.about.index.designer_role")
                      end
                      p(class: "mt-2 text-sm leading-relaxed text-muted-foreground") do
                        t("pages.about.index.designer_bio")
                      end
                    end
                  end
                end

                div(class: "rounded-xl border border-border bg-card/80 p-8") do
                  h2(class: "font-serif text-2xl font-semibold tracking-tight text-foreground") do
                    t("pages.about.index.join_title")
                  end
                  p(class: "mt-4 text-base leading-relaxed text-muted-foreground") do
                    t("pages.about.index.join_body")
                  end
                  div(class: "mt-6") do
                    render Components::Ui::Button.new(
                      as: :a,
                      href: "mailto:info@papyro.net?subject=Join%20Papyro%20Community&body=I%20would%20like%20to%20join%20the%20Papyro%20community.",
                      variant: :outline,
                      size: :lg
                    ) do
                      t("pages.about.index.join_cta")
                    end
                  end
                end
              end
            end
          end

          render Components::Public::Footer.new
        end
      end
    end
  end
end
