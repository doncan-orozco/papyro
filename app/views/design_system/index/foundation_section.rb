# frozen_string_literal: true

module Views
  module DesignSystem
    class Index::FoundationSection < Views::Base
      include Index::Shared::SectionHelpers

      def view_template
        section_container(id: "foundation", hidden: false) do
          div do
            h2(class: "text-2xl font-bold mb-4") { t("design_system.catalog.foundation.title") }

            component_card(
              title: t("design_system.catalog.foundation.badge.title"),
              description: t("design_system.catalog.foundation.badge.description")
            ) do
              div(class: "flex gap-2") do
                render Components::Ui::Badge.new { t("design_system.catalog.labels.default") }
                render Components::Ui::Badge.new(variant: :secondary) { t("design_system.catalog.labels.secondary") }
                render Components::Ui::Badge.new(variant: :destructive) { t("design_system.catalog.labels.destructive") }
                render Components::Ui::Badge.new(variant: :outline) { t("design_system.catalog.labels.outline") }
              end
            end

            component_card(
              title: t("design_system.catalog.foundation.button.title"),
              description: t("design_system.catalog.foundation.button.description")
            ) do
              div(class: "flex flex-wrap gap-2") do
                render Components::Ui::Button.new { t("design_system.catalog.labels.default") }
                render Components::Ui::Button.new(variant: :secondary) { t("design_system.catalog.labels.secondary") }
                render Components::Ui::Button.new(variant: :destructive) { t("design_system.catalog.labels.destructive") }
                render Components::Ui::Button.new(variant: :outline) { t("design_system.catalog.labels.outline") }
                render Components::Ui::Button.new(variant: :ghost) { t("design_system.catalog.labels.ghost") }
                render Components::Ui::Button.new(disabled: true) { t("design_system.catalog.labels.disabled") }
              end

              div(class: "flex flex-wrap gap-2") do
                render Components::Ui::Button.new(size: :xs) { t("design_system.catalog.labels.small") }
                render Components::Ui::Button.new(size: :default) { t("design_system.catalog.labels.default") }
                render Components::Ui::Button.new(size: :lg) { t("design_system.catalog.labels.large") }
              end
            end

            component_card(
              title: t("design_system.catalog.foundation.separator.title"),
              description: t("design_system.catalog.foundation.separator.description")
            ) do
              div(class: "space-y-2") do
                p { t("design_system.catalog.foundation.separator.section_one") }
                render Components::Ui::Separator.new
                p { t("design_system.catalog.foundation.separator.section_two") }
                render Components::Ui::Separator.new
                p { t("design_system.catalog.foundation.separator.section_three") }
              end
            end

            component_card(
              title: t("design_system.catalog.foundation.skeleton.title"),
              description: t("design_system.catalog.foundation.skeleton.description")
            ) do
              render Components::Ui::Skeleton.new(class: "h-12 w-12 rounded-full")
              render Components::Ui::Skeleton.new(class: "h-4 w-[250px]")
              render Components::Ui::Skeleton.new(class: "h-4 w-[200px]")
            end
          end
        end
      end
    end
  end
end
