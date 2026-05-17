# frozen_string_literal: true

module Views
  module DesignSystem
    class Index::FeedbackSection < Views::Base
      include Index::Shared::SectionHelpers

      def view_template
        section_container(id: "feedback") do
          div(class: "space-y-8") do
            h2(class: "text-2xl font-bold") { t("design_system.catalog.feedback.title") }

            component_card(
              title: t("design_system.catalog.feedback.alert.title"),
              description: t("design_system.catalog.feedback.alert.description")
            ) do
              render Components::Ui::Alert.new do |alert|
                alert.title { t("design_system.catalog.feedback.alert.info_title") }
                alert.description { t("design_system.catalog.feedback.alert.info_body") }
              end

              render Components::Ui::Alert.new(variant: :destructive) do |alert|
                alert.title { t("design_system.catalog.feedback.alert.error_title") }
                alert.description { t("design_system.catalog.feedback.alert.error_body") }
              end
            end

            component_card(
              title: t("design_system.catalog.feedback.tabs.title"),
              description: t("design_system.catalog.feedback.tabs.description")
            ) do
              render Components::Ui::Tabs.new(data: { ui__tabs_active_index_value: 0 }) do |tabs|
                tabs.list do
                  [
                    t("design_system.catalog.feedback.tabs.tab_one"),
                    t("design_system.catalog.feedback.tabs.tab_two"),
                    t("design_system.catalog.feedback.tabs.tab_three")
                  ].each do |label|
                    tabs.trigger { label }
                  end
                end

                [
                  t("design_system.catalog.feedback.tabs.content_one"),
                  t("design_system.catalog.feedback.tabs.content_two"),
                  t("design_system.catalog.feedback.tabs.content_three")
                ].each do |content|
                  tabs.content { content }
                end
              end
            end
          end
        end
      end
    end
  end
end
