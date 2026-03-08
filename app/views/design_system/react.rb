# frozen_string_literal: true

include Phlex::Rails::Helpers::ContentFor

module Views
  module DesignSystem
    class React < Views::Base
      def view_template
        content_for :head do
          tag(:meta, name: "turbo-cache-control", content: "no-cache")
          tag(:meta, name: "turbo-visit-control", content: "reload")
        end

        div(class: "min-h-screen bg-background text-foreground font-['Manrope']") do
          header(class: "border-b border-border bg-card/50 sticky top-0 z-40") do
            div(class: "max-w-7xl mx-auto px-6 py-4 lg:px-10") do
              div(class: "flex items-center justify-between") do
                div(class: "flex items-center gap-6") do
                  h1(class: "text-xl font-bold") { t("design_system.react.title") }

                  nav(class: "flex gap-2 text-sm") do
                    link_to(
                      t("design_system.react.back_to_phlex"),
                      design_system_path,
                      class: "px-3 py-2 rounded-lg hover:bg-muted transition-colors"
                    )
                    link_to(
                      t("design_system.react.compare"),
                      design_system_compare_path,
                      class: "px-3 py-2 rounded-lg hover:bg-muted transition-colors"
                    )
                  end
                end

                div(class: "text-xs text-muted-foreground") do
                  t("design_system.react.subtitle")
                end
              end
            end
          end

          # React catalog iframe
          main(class: "relative w-full h-[calc(100vh-65px)]") do
            iframe(
              src: "/react-catalog/",
              title: t("design_system.react.iframe_title"),
              class: "w-full h-full border-0"
            )
          end
        end
      end
    end
  end
end
