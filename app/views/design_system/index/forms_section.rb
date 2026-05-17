# frozen_string_literal: true

module Views
  module DesignSystem
    class Index::FormsSection < Views::Base
      include Index::Shared::SectionHelpers

      def view_template
        section_container(id: "forms") do
          div(class: "space-y-8") do
            h2(class: "text-2xl font-bold") { t("design_system.catalog.forms.title") }

            component_card(
              title: t("design_system.catalog.forms.input.title"),
              description: t("design_system.catalog.forms.input.description")
            ) do
              div do
                render Components::Ui::Label.new(for: "input-email") { t("design_system.catalog.forms.input.email") }
                render Components::Ui::Input.new(id: "input-email", type: :email, placeholder: t("design_system.catalog.forms.input.placeholder"))
              end

              div do
                render Components::Ui::Label.new(for: "input-disabled") { t("design_system.catalog.labels.disabled") }
                render Components::Ui::Input.new(id: "input-disabled", placeholder: t("design_system.catalog.forms.input.disabled_placeholder"), disabled: true)
              end
            end

            component_card(
              title: t("design_system.catalog.forms.checkbox.title"),
              description: t("design_system.catalog.forms.checkbox.description")
            ) do
              div(class: "flex items-center space-x-2") do
                render Components::Ui::Checkbox.new(id: "terms")
                render Components::Ui::Label.new(for: "terms") { t("design_system.catalog.forms.checkbox.terms") }
              end

              div(class: "flex items-center space-x-2") do
                render Components::Ui::Checkbox.new(id: "checked", checked: true)
                render Components::Ui::Label.new(for: "checked") { t("design_system.catalog.forms.checkbox.checked") }
              end
            end

            component_card(
              title: t("design_system.catalog.forms.radio.title"),
              description: t("design_system.catalog.forms.radio.description")
            ) do
              div(
                class: "space-y-3",
                data: {
                  controller: "ui--radio-group",
                  ui__radio_group_value_value: "option-1"
                }
              ) do
                div(class: "flex items-center space-x-2") do
                  render Components::Ui::Radio.new(
                    value: "option-1",
                    id: "option-1",
                    name: "radio-options",
                    checked: true,
                    data: { ui__radio_group_target: "input" }
                  )
                  render Components::Ui::Label.new(for: "option-1") { t("design_system.catalog.forms.radio.option_one") }
                end

                div(class: "flex items-center space-x-2") do
                  render Components::Ui::Radio.new(
                    value: "option-2",
                    id: "option-2",
                    name: "radio-options",
                    data: { ui__radio_group_target: "input" }
                  )
                  render Components::Ui::Label.new(for: "option-2") { t("design_system.catalog.forms.radio.option_two") }
                end
              end
            end

            component_card(
              title: t("design_system.catalog.forms.switch.title"),
              description: t("design_system.catalog.forms.switch.description")
            ) do
              div(class: "flex items-center space-x-2") do
                render Components::Ui::Switch.new(id: "notifications") do |switch|
                  switch.thumb
                end
                render Components::Ui::Label.new(for: "notifications") { t("design_system.catalog.forms.switch.label") }
              end

              div(class: "flex items-center space-x-2") do
                render Components::Ui::Switch.new(checked: true, id: "notifications-checked") do |switch|
                  switch.thumb
                end
                render Components::Ui::Label.new(for: "notifications-checked") { t("design_system.catalog.forms.switch.checked") }
              end
            end

            component_card(
              title: t("design_system.catalog.forms.textarea.title"),
              description: t("design_system.catalog.forms.textarea.description")
            ) do
              render Components::Ui::Textarea.new(placeholder: t("design_system.catalog.forms.textarea.placeholder"))
            end

            component_card(
              title: t("design_system.catalog.forms.select.title"),
              description: t("design_system.catalog.forms.select.description")
            ) do
              render Components::Ui::Select.new(placeholder: t("design_system.catalog.forms.select.placeholder")) do |select|
                select.trigger do
                  select.value
                  render Components::Ui::Icon.new(:"chevron-down", source: :lucide, class: "h-4 w-4 opacity-50")
                end

                select.content(hidden: true) do
                  select.item(value: "apple", tabindex: "0") { t("design_system.catalog.forms.select.option_one") }
                  select.item(value: "banana", tabindex: "0") { t("design_system.catalog.forms.select.option_two") }
                  select.item(value: "orange", tabindex: "0") { t("design_system.catalog.forms.select.option_three") }
                end
              end
            end
          end
        end
      end
    end
  end
end
