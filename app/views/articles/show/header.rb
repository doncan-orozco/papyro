# frozen_string_literal: true

module Views
  module Articles
    class Show::Header < Views::Base
      def initialize(back_path:)
        @back_path = back_path
      end

      def view_template
        header(class: "sticky top-0 z-20 border-b border-border bg-background/95 px-4 py-4 backdrop-blur sm:px-6") do
          div(class: "mx-auto flex w-full max-w-6xl items-center justify-between") do
            link_to @back_path,
              class: "inline-flex items-center gap-2 text-muted-foreground hover:text-foreground transition",
              data: { turbo_frame: "_top", action: "click->fullscreen#exit" } do
              render Components::Ui::Icon.new(:arrow_left, class: "w-5 h-5")
              span(class: "text-sm font-medium") { t("articles.show.back_to_list") }
            end

            div(class: "flex items-center gap-3") do
              render Components::Shared::LanguageToggle.new
              render Components::Shared::ThemeToggle.new
              button(
                type: "button",
                data: { action: "fullscreen#toggle:prevent", fullscreen_target: "button" },
                class: "inline-flex items-center gap-2 rounded-md border border-border px-3 py-1.5 text-sm text-muted-foreground transition hover:bg-muted hover:text-foreground",
                aria: { label: t("articles.show.fullscreen") }
              ) do
                render Components::Ui::Icon.new(:maximize, class: "h-5 w-5")
                span { t("articles.show.fullscreen") }
              end
            end
          end
        end
      end
    end
  end
end
