# frozen_string_literal: true

module Views
  module DesignSystem
    class Index::TablesSection::BasicExamples < Views::Base
      include Index::Shared::SectionHelpers

      def view_template
        render_basic_table
        render_table_with_footer
        render_simple_table
      end

      private

      def render_basic_table
        component_card(
          title: t("design_system.catalog.tables.basic.title"),
          description: t("design_system.catalog.tables.basic.description")
        ) do
          render Components::Ui::Table.new do |table|
            table.header do
              table.row do
                table.head { t("design_system.catalog.tables.basic.head_invoice") }
                table.head { t("design_system.catalog.tables.basic.head_status") }
                table.head { t("design_system.catalog.tables.basic.head_method") }
                table.head(class: "text-right") { t("design_system.catalog.tables.basic.head_amount") }
              end
            end

            table.body do
              table.row do
                table.cell(class: "font-medium") { t("design_system.catalog.tables.basic.inv_001") }
                table.cell { t("design_system.catalog.tables.basic.status_paid") }
                table.cell { t("design_system.catalog.tables.basic.method_credit") }
                table.cell(class: "text-right") { t("design_system.catalog.tables.basic.amount_250") }
              end

              table.row do
                table.cell(class: "font-medium") { t("design_system.catalog.tables.basic.inv_002") }
                table.cell { t("design_system.catalog.tables.basic.status_pending") }
                table.cell { t("design_system.catalog.tables.basic.method_paypal") }
                table.cell(class: "text-right") { t("design_system.catalog.tables.basic.amount_150") }
              end

              table.row do
                table.cell(class: "font-medium") { t("design_system.catalog.tables.basic.inv_003") }
                table.cell { t("design_system.catalog.tables.basic.status_unpaid") }
                table.cell { t("design_system.catalog.tables.basic.method_bank") }
                table.cell(class: "text-right") { t("design_system.catalog.tables.basic.amount_350") }
              end
            end
          end
        end
      end

      def render_table_with_footer
        component_card(
          title: t("design_system.catalog.tables.with_footer.title"),
          description: t("design_system.catalog.tables.with_footer.description")
        ) do
          render Components::Ui::Table.new do |table|
            table.header do
              table.row do
                table.head { t("design_system.catalog.tables.basic.head_invoice") }
                table.head { t("design_system.catalog.tables.basic.head_status") }
                table.head { t("design_system.catalog.tables.basic.head_method") }
                table.head(class: "text-right") { t("design_system.catalog.tables.basic.head_amount") }
              end
            end

            table.body do
              table.row do
                table.cell(class: "font-medium") { t("design_system.catalog.tables.basic.inv_001") }
                table.cell { t("design_system.catalog.tables.basic.status_paid") }
                table.cell { t("design_system.catalog.tables.basic.method_credit") }
                table.cell(class: "text-right") { t("design_system.catalog.tables.basic.amount_250") }
              end

              table.row do
                table.cell(class: "font-medium") { t("design_system.catalog.tables.basic.inv_002") }
                table.cell { t("design_system.catalog.tables.basic.status_pending") }
                table.cell { t("design_system.catalog.tables.basic.method_paypal") }
                table.cell(class: "text-right") { t("design_system.catalog.tables.basic.amount_150") }
              end

              table.row do
                table.cell(class: "font-medium") { t("design_system.catalog.tables.basic.inv_003") }
                table.cell { t("design_system.catalog.tables.basic.status_unpaid") }
                table.cell { t("design_system.catalog.tables.basic.method_bank") }
                table.cell(class: "text-right") { t("design_system.catalog.tables.basic.amount_350") }
              end
            end

            table.footer do
              table.row do
                table.cell(colspan: 3) { t("design_system.catalog.tables.with_footer.total_label") }
                table.cell(class: "text-right") { t("design_system.catalog.tables.with_footer.total_amount") }
              end
            end
          end
        end
      end

      def render_simple_table
        component_card(
          title: t("design_system.catalog.tables.simple.title"),
          description: t("design_system.catalog.tables.simple.description")
        ) do
          render Components::Ui::Table.new do |table|
            table.header do
              table.row do
                table.head { t("design_system.catalog.tables.simple.head_name") }
                table.head { t("design_system.catalog.tables.simple.head_email") }
                table.head { t("design_system.catalog.tables.simple.head_role") }
              end
            end

            table.body do
              table.row do
                table.cell(class: "font-medium") { t("design_system.catalog.tables.simple.user_1_name") }
                table.cell { t("design_system.catalog.tables.simple.user_1_email") }
                table.cell { t("design_system.catalog.tables.simple.user_1_role") }
              end

              table.row do
                table.cell(class: "font-medium") { t("design_system.catalog.tables.simple.user_2_name") }
                table.cell { t("design_system.catalog.tables.simple.user_2_email") }
                table.cell { t("design_system.catalog.tables.simple.user_2_role") }
              end

              table.row do
                table.cell(class: "font-medium") { t("design_system.catalog.tables.simple.user_3_name") }
                table.cell { t("design_system.catalog.tables.simple.user_3_email") }
                table.cell { t("design_system.catalog.tables.simple.user_3_role") }
              end
            end
          end
        end
      end
    end
  end
end
