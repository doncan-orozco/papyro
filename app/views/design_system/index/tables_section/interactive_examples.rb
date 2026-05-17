# frozen_string_literal: true

module Views
  module DesignSystem
    class Index::TablesSection::InteractiveExamples < Views::Base
      include Index::Shared::SectionHelpers

      def view_template
        render_select_table
        render_input_table
      end

      private

      def render_select_table
        component_card(
          title: t("design_system.catalog.tables.with_select.title"),
          description: t("design_system.catalog.tables.with_select.description")
        ) do
          render Components::Ui::Table.new do |table|
            table.header do
              table.row do
                table.head { t("design_system.catalog.tables.with_select.head_task") }
                table.head { t("design_system.catalog.tables.with_select.head_assigned") }
                table.head { t("design_system.catalog.tables.with_select.head_status") }
              end
            end

            table.body do
              table.row do
                table.cell(class: "font-medium") { t("design_system.catalog.tables.with_select.task_1") }
                table.cell { t("design_system.catalog.tables.with_select.user_1") }
                table.cell { render_status_select(default: "progress") }
              end

              table.row do
                table.cell(class: "font-medium") { t("design_system.catalog.tables.with_select.task_2") }
                table.cell { t("design_system.catalog.tables.with_select.user_2") }
                table.cell { render_status_select(default: "pending") }
              end

              table.row do
                table.cell(class: "font-medium") { t("design_system.catalog.tables.with_select.task_3") }
                table.cell { t("design_system.catalog.tables.with_select.user_3") }
                table.cell { render_status_select(default: "not-started") }
              end
            end
          end
        end
      end

      def render_input_table
        component_card(
          title: t("design_system.catalog.tables.with_input.title"),
          description: t("design_system.catalog.tables.with_input.description")
        ) do
          render Components::Ui::Table.new do |table|
            table.header do
              table.row do
                table.head { t("design_system.catalog.tables.with_input.head_product") }
                table.head { t("design_system.catalog.tables.with_input.head_quantity") }
                table.head(class: "text-right") { t("design_system.catalog.tables.with_input.head_total") }
              end
            end

            table.body do
              table.row do
                table.cell(class: "font-medium") { t("design_system.catalog.tables.with_input.product_1") }
                table.cell do
                  render Components::Ui::Input.new(type: :number, value: "1", class: "w-20")
                end
                table.cell(class: "text-right") { t("design_system.catalog.tables.with_input.price_1") }
              end

              table.row do
                table.cell(class: "font-medium") { t("design_system.catalog.tables.with_input.product_2") }
                table.cell do
                  render Components::Ui::Input.new(type: :number, value: "2", class: "w-20")
                end
                table.cell(class: "text-right") { t("design_system.catalog.tables.with_input.price_2") }
              end

              table.row do
                table.cell(class: "font-medium") { t("design_system.catalog.tables.with_input.product_3") }
                table.cell do
                  render Components::Ui::Input.new(type: :number, value: "1", class: "w-20")
                end
                table.cell(class: "text-right") { t("design_system.catalog.tables.with_input.price_3") }
              end
            end
          end
        end
      end

      def render_status_select(default:)
        render Components::Ui::Select.new(
          default_value: default,
          placeholder: t("design_system.catalog.tables.with_select.status_placeholder"),
          class: "w-[140px]"
        ) do |select|
          select.trigger do
            select.value
            render Components::Ui::Icon.new(:"chevron-down", source: :lucide, class: "h-4 w-4 opacity-50")
          end

          select.content(hidden: true) do
            select.item(value: "progress", tabindex: "0") { t("design_system.catalog.tables.with_select.status_progress") }
            select.item(value: "pending", tabindex: "0") { t("design_system.catalog.tables.with_select.status_pending") }
            select.item(value: "not-started", tabindex: "0") { t("design_system.catalog.tables.with_select.status_not_started") }
          end
        end
      end
    end
  end
end
