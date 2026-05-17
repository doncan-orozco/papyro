# frozen_string_literal: true

module Views
  module DesignSystem
    class Index::OverlaysSection::ModalCards < Views::Base
      include Index::Shared::SectionHelpers

      def view_template
        dialog_card
        alert_dialog_card
        sheet_card
        tooltip_card
      end

      private

      def dialog_card
        component_card(
          title: t("design_system.catalog.overlays.dialog.title"),
          description: t("design_system.catalog.overlays.dialog.description")
        ) do
          render Components::Ui::Dialog.new do |dialog|
            dialog.trigger do
              render Components::Ui::Button.new(variant: :outline) { t("design_system.catalog.overlays.dialog.trigger") }
            end

            dialog.content(hidden: true) do
              dialog.header do
                dialog.title { t("design_system.catalog.overlays.dialog.content_title") }
                dialog.description { t("design_system.catalog.overlays.dialog.content_body") }
              end

              dialog.footer(class: "mt-4") do
                render Components::Ui::Button.new(
                  variant: :outline,
                  data: { action: "click->ui--dialog#close" }
                ) { t("design_system.catalog.overlays.dialog.cancel") }
                render Components::Ui::Button.new(
                  data: { action: "click->ui--dialog#close" }
                ) { t("design_system.catalog.overlays.dialog.continue") }
              end
            end
          end
        end
      end

      def alert_dialog_card
        component_card(
          title: t("design_system.catalog.overlays.alert_dialog.title"),
          description: t("design_system.catalog.overlays.alert_dialog.description")
        ) do
          render Components::Ui::AlertDialog.new do |dialog|
            dialog.trigger do
              render Components::Ui::Button.new(variant: :destructive) do
                t("design_system.catalog.overlays.alert_dialog.trigger")
              end
            end

            dialog.content(hidden: true) do
              dialog.header do
                dialog.title { t("design_system.catalog.overlays.alert_dialog.content_title") }
                dialog.description do
                  t("design_system.catalog.overlays.alert_dialog.content_body")
                end
              end

              dialog.footer(class: "mt-4") do
                dialog.cancel do
                  t("design_system.catalog.overlays.alert_dialog.cancel")
                end
                dialog.action do
                  t("design_system.catalog.overlays.alert_dialog.continue")
                end
              end
            end
          end
        end
      end

      def sheet_card
        component_card(
          title: t("design_system.catalog.overlays.sheet.title"),
          description: t("design_system.catalog.overlays.sheet.description")
        ) do
          render Components::Ui::Sheet.new do |sheet|
            sheet.trigger do
              render Components::Ui::Button.new(variant: :outline) do
                t("design_system.catalog.overlays.sheet.trigger")
              end
            end

            sheet.content(hidden: true, side: :right) do
              sheet.header do
                sheet.title { t("design_system.catalog.overlays.sheet.content_title") }
                sheet.description { t("design_system.catalog.overlays.sheet.content_body") }
              end

              sheet.footer(class: "mt-4") do
                render Components::Ui::Button.new(
                  variant: :outline,
                  data: { action: "click->ui--dialog#close" }
                ) { t("design_system.catalog.overlays.sheet.cancel") }
                render Components::Ui::Button.new(
                  data: { action: "click->ui--dialog#close" }
                ) { t("design_system.catalog.overlays.sheet.save") }
              end
            end
          end
        end
      end

      def tooltip_card
        component_card(
          title: t("design_system.catalog.overlays.tooltip.title"),
          description: t("design_system.catalog.overlays.tooltip.description")
        ) do
          render Components::Ui::TooltipProvider.new do |provider|
            provider.tooltip(delay: 200, class: "inline-block") do |tooltip|
              tooltip.trigger do
                render Components::Ui::Button.new(variant: :outline) { t("design_system.catalog.overlays.tooltip.trigger") }
              end

              tooltip.content(hidden: true) do
                t("design_system.catalog.overlays.tooltip.content")
              end
            end
          end
        end
      end
    end
  end
end
