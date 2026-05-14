# frozen_string_literal: true

module Views
  module Authors
    class Show::MetaAndSocialLinks < Views::Base
      def initialize(presenter:)
        @presenter = presenter
      end

      def view_template
        div(class: "mt-4 flex flex-wrap items-center gap-4 text-sm text-muted-foreground") do
          if @presenter.location.present?
            div(class: "inline-flex items-center gap-1.5") do
              render Components::Ui::Icon.new(:map_pin, class: "size-4 shrink-0")
              span { @presenter.location }
            end
          end

          if @presenter.website_url.present?
            link_to(
              @presenter.website_url,
              target: "_blank",
              rel: "noopener noreferrer",
              class: "inline-flex items-center gap-1.5 hover:text-foreground transition-colors"
            ) do
              render Components::Ui::Icon.new(:link, class: "size-4 shrink-0")
              span(class: "truncate max-w-[180px]") { t("authors.show.website") }
            end
          end

          if @presenter.x_handle.present?
            link_to(
              @presenter.x_profile_url,
              target: "_blank",
              rel: "noopener noreferrer",
              class: "inline-flex items-center gap-1.5 hover:text-foreground transition-colors"
            ) do
              render Components::Ui::Icon.new(:twitter, class: "size-3.5")
              span(class: "font-medium") { "@#{@presenter.x_handle_without_prefix}" }
            end
          end

          if @presenter.linkedin_handle.present?
            link_to(
              @presenter.linkedin_url,
              target: "_blank",
              rel: "noopener noreferrer",
              class: "inline-flex items-center gap-1.5 hover:text-foreground transition-colors"
            ) do
              render Components::Ui::Icon.new(:linkedin, class: "size-4 shrink-0")
              span { t("authors.show.linkedin") }
            end
          end
        end
      end
    end
  end
end
