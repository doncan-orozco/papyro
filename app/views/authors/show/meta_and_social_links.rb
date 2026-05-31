# frozen_string_literal: true

module Views
  module Authors
    class Show::MetaAndSocialLinks < Views::Base
      def initialize(presenter:)
        @presenter = presenter
      end

      def view_template
        div(class: "mt-12 max-w-xl border-y border-border/40") do
          if @presenter.location.present?
            div(class: "flex items-center justify-between gap-4 border-b border-border/40 py-3") do
              span(class: "text-[10px] font-medium uppercase tracking-[0.2em] text-foreground/80") { t("authors.show.meta.location") }
              div(class: "inline-flex items-center gap-2 text-sm font-medium text-foreground") do
                render Components::Ui::Icon.new(:map_pin, class: "size-4 shrink-0 text-foreground/60")
                span { @presenter.location }
              end
            end
          end

          if @presenter.website_url.present?
            div(class: "flex items-center justify-between gap-4 border-b border-border/40 py-3") do
              span(class: "text-[10px] font-medium uppercase tracking-[0.2em] text-foreground/80") { t("authors.show.meta.website") }
              link_to(
                @presenter.website_url,
                target: "_blank",
                rel: "noopener noreferrer",
                class: "inline-flex items-center gap-2 text-sm font-medium text-foreground transition-colors hover:text-rose-600 hover:underline focus-visible:underline dark:hover:text-rose-500"
              ) do
                render Components::Ui::Icon.new(:link, class: "size-4 shrink-0")
                span(class: "truncate max-w-[220px]") { @presenter.website_display_value || t("authors.show.website") }
              end
            end
          end

          if @presenter.x_handle.present?
            div(class: "flex items-center justify-between gap-4 border-b border-border/40 py-3") do
              span(class: "text-[10px] font-medium uppercase tracking-[0.2em] text-foreground/80") { t("authors.show.meta.x") }
              link_to(
                @presenter.x_profile_url,
                target: "_blank",
                rel: "noopener noreferrer",
                class: "inline-flex items-center gap-2 text-sm font-medium text-foreground transition-colors hover:text-rose-600 hover:underline focus-visible:underline dark:hover:text-rose-500"
              ) do
                render Components::Ui::Icon.new(:twitter, class: "size-3.5")
                span(class: "font-medium") { "@#{@presenter.x_handle_without_prefix}" }
              end
            end
          end

          if @presenter.linkedin_handle.present?
            div(class: "flex items-center justify-between gap-4 py-3") do
              span(class: "text-[10px] font-medium uppercase tracking-[0.2em] text-foreground/80") { t("authors.show.meta.linkedin") }
              link_to(
                @presenter.linkedin_url,
                target: "_blank",
                rel: "noopener noreferrer",
                class: "inline-flex items-center gap-2 text-sm font-medium text-foreground transition-colors hover:text-rose-600 hover:underline focus-visible:underline dark:hover:text-rose-500"
              ) do
                render Components::Ui::Icon.new(:linkedin, class: "size-4 shrink-0")
                span { @presenter.linkedin_display_value || t("authors.show.linkedin") }
              end
            end
          end
        end
      end
    end
  end
end
