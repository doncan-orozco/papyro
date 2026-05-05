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
                      div(class: "flex items-center gap-2") do
                        p(class: "text-base font-medium text-foreground") do
                          t("pages.about.index.engineer_name")
                        end
                        a(
                          href: "https://www.linkedin.com/in/doncan-orozco",
                          target: "_blank",
                          rel: "noopener noreferrer",
                          class: "text-muted-foreground hover:text-foreground transition-colors",
                          aria_label: "LinkedIn"
                        ) do
                          svg(
                            xmlns: "http://www.w3.org/2000/svg",
                            viewbox: "0 0 24 24",
                            fill: "currentColor",
                            class: "h-4 w-4"
                          ) do |s|
                            s.path(d: "M20.447 20.452h-3.554v-5.569c0-1.328-.027-3.037-1.852-3.037-1.853 0-2.136 1.445-2.136 2.939v5.667H9.351V9h3.414v1.561h.046c.477-.9 1.637-1.85 3.37-1.85 3.601 0 4.267 2.37 4.267 5.455v6.286zM5.337 7.433c-1.144 0-2.063-.926-2.063-2.065 0-1.138.92-2.063 2.063-2.063 1.14 0 2.064.925 2.064 2.063 0 1.139-.925 2.065-2.064 2.065zm1.782 13.019H3.555V9h3.564v11.452zM22.225 0H1.771C.792 0 0 .774 0 1.729v20.542C0 23.227.792 24 1.771 24h20.451C23.2 24 24 23.227 24 22.271V1.729C24 .774 23.2 0 22.222 0h.003z")
                          end
                        end
                      end
                      p(class: "mt-1 text-sm text-muted-foreground") do
                        t("pages.about.index.engineer_role")
                      end
                      p(class: "mt-2 text-sm leading-relaxed text-muted-foreground") do
                        t("pages.about.index.engineer_bio")
                      end
                    end

                    div do
                      div(class: "flex items-center gap-2") do
                        p(class: "text-base font-medium text-foreground") do
                          t("pages.about.index.designer_name")
                        end
                        a(
                          href: "https://www.linkedin.com/in/martha-ol%C3%A1n-067879304",
                          target: "_blank",
                          rel: "noopener noreferrer",
                          class: "text-muted-foreground hover:text-foreground transition-colors",
                          aria_label: "LinkedIn"
                        ) do
                          svg(
                            xmlns: "http://www.w3.org/2000/svg",
                            viewbox: "0 0 24 24",
                            fill: "currentColor",
                            class: "h-4 w-4"
                          ) do |s|
                            s.path(d: "M20.447 20.452h-3.554v-5.569c0-1.328-.027-3.037-1.852-3.037-1.853 0-2.136 1.445-2.136 2.939v5.667H9.351V9h3.414v1.561h.046c.477-.9 1.637-1.85 3.37-1.85 3.601 0 4.267 2.37 4.267 5.455v6.286zM5.337 7.433c-1.144 0-2.063-.926-2.063-2.065 0-1.138.92-2.063 2.063-2.063 1.14 0 2.064.925 2.064 2.063 0 1.139-.925 2.065-2.064 2.065zm1.782 13.019H3.555V9h3.564v11.452zM22.225 0H1.771C.792 0 0 .774 0 1.729v20.542C0 23.227.792 24 1.771 24h20.451C23.2 24 24 23.227 24 22.271V1.729C24 .774 23.2 0 22.222 0h.003z")
                          end
                        end
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
