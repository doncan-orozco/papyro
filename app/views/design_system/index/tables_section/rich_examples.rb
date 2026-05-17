# frozen_string_literal: true

module Views
  module DesignSystem
    class Index::TablesSection::RichExamples < Views::Base
      include Index::Shared::SectionHelpers

      def view_template
        render_badges_table
        render_actions_table
      end

      private

      def render_badges_table
        component_card(
          title: t("design_system.catalog.tables.with_badges.title"),
          description: t("design_system.catalog.tables.with_badges.description")
        ) do
          render Components::Ui::Table.new do |table|
            table.header do
              table.row do
                table.head { t("design_system.catalog.tables.with_badges.head_task") }
                table.head { t("design_system.catalog.tables.with_badges.head_status") }
                table.head { t("design_system.catalog.tables.with_badges.head_priority") }
              end
            end

            table.body do
              table.row do
                table.cell(class: "font-medium") { t("design_system.catalog.tables.with_badges.task_1") }
                table.cell do
                  render Components::Ui::Badge.new { t("design_system.catalog.tables.with_badges.status_completed") }
                end
                table.cell do
                  render Components::Ui::Badge.new(variant: :destructive) { t("design_system.catalog.tables.with_badges.priority_high") }
                end
              end

              table.row do
                table.cell(class: "font-medium") { t("design_system.catalog.tables.with_badges.task_2") }
                table.cell do
                  render Components::Ui::Badge.new(variant: :secondary) { t("design_system.catalog.tables.with_badges.status_progress") }
                end
                table.cell do
                  render Components::Ui::Badge.new(variant: :outline) { t("design_system.catalog.tables.with_badges.priority_medium") }
                end
              end

              table.row do
                table.cell(class: "font-medium") { t("design_system.catalog.tables.with_badges.task_3") }
                table.cell do
                  render Components::Ui::Badge.new(variant: :outline) { t("design_system.catalog.tables.with_badges.status_pending") }
                end
                table.cell do
                  render Components::Ui::Badge.new(variant: :secondary) { t("design_system.catalog.tables.with_badges.priority_low") }
                end
              end
            end
          end
        end
      end

      def render_actions_table
        component_card(
          title: t("design_system.catalog.tables.with_actions.title"),
          description: t("design_system.catalog.tables.with_actions.description")
        ) do
          render Components::Ui::Table.new do |table|
            table.header do
              table.row do
                table.head { t("design_system.catalog.tables.with_actions.head_product") }
                table.head { t("design_system.catalog.tables.with_actions.head_price") }
                table.head(class: "text-right") { t("design_system.catalog.tables.with_actions.head_actions") }
              end
            end

            table.body do
              3.times do |i|
                table.row do
                  table.cell(class: "font-medium") { t("design_system.catalog.tables.with_actions.product_#{i + 1}") }
                  table.cell { t("design_system.catalog.tables.with_actions.price_#{i + 1}") }
                  table.cell(class: "text-right") do
                    render Components::Ui::DropdownMenu.new(
                      data: { ui__dropdown_placement_value: "bottom-end" }
                    ) do |dropdown|
                      dropdown.trigger(
                        variant: :ghost,
                        size: :icon,
                        class: "size-8"
                      ) do
                        render Components::Ui::Icon.new(:"more-horizontal", class: "h-4 w-4")
                        span(class: "sr-only") { t("design_system.catalog.tables.with_actions.menu_trigger") }
                      end

                      dropdown.content(hidden: true, align: :end) do
                        dropdown.item { t("design_system.catalog.tables.with_actions.menu_edit") }
                        dropdown.item { t("design_system.catalog.tables.with_actions.menu_duplicate") }
                        dropdown.separator
                        dropdown.item(variant: :destructive) { t("design_system.catalog.tables.with_actions.menu_delete") }
                      end
                    end
                  end
                end
              end
            end
          end
        end
      end
    end
  end
end
