# frozen_string_literal: true

module Views
  module DesignSystem
    class Index::OverlaysSection::QuickCards < Views::Base
      include Index::Shared::SectionHelpers

      def view_template
        popover_card
        hover_card_card
      end

      private

      def popover_card
        component_card(
          title: t("design_system.popover.title"),
          description: t("design_system.popover.description")
        ) do
          render Components::Ui::Popover.new do |popover|
            popover.trigger do
              render Components::Ui::Button.new(variant: :outline) do
                t("design_system.popover.trigger")
              end
            end

            popover.content(hidden: true, class: "w-80") do
              div(class: "space-y-4") do
                div(class: "space-y-1") do
                  h4(class: "font-medium leading-none") { t("design_system.popover.heading") }
                end

                div(class: "grid gap-2") do
                  div(class: "grid grid-cols-[1fr_auto] items-center gap-4") do
                    span(class: "text-sm text-muted-foreground") { t("design_system.popover.width_label") }
                    span(class: "text-sm font-medium") { t("design_system.popover.width_value") }
                  end

                  div(class: "grid grid-cols-[1fr_auto] items-center gap-4") do
                    span(class: "text-sm text-muted-foreground") { t("design_system.popover.height_label") }
                    span(class: "text-sm font-medium") { t("design_system.popover.height_value") }
                  end
                end
              end
            end
          end
        end
      end

      def hover_card_card
        component_card(
          title: t("design_system.hover_card.title"),
          description: t("design_system.hover_card.description")
        ) do
          render Components::Ui::HoverCard.new(delay: 150) do |hover_card|
            hover_card.trigger do
              render Components::Ui::Button.new(variant: :outline) do
                t("design_system.hover_card.trigger")
              end
            end

            hover_card.content(hidden: true, class: "w-80") do
              div(class: "space-y-2") do
                p(class: "text-sm font-semibold") { t("design_system.hover_card.username") }
                p(class: "text-sm text-muted-foreground") { t("design_system.hover_card.bio") }
                p(class: "text-xs text-muted-foreground") { t("design_system.hover_card.joined") }
              end
            end
          end
        end
      end
    end
  end
end
