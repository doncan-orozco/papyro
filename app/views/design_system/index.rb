# frozen_string_literal: true

include Phlex::Rails::Helpers::ContentFor

module Views
  module DesignSystem
    class Index < Views::Base
      def view_template
        content_for :head do
          tag(:meta, name: "turbo-cache-control", content: "no-cache")
          tag(:meta, name: "turbo-visit-control", content: "reload")
        end

        div(class: "min-h-screen bg-background text-foreground") do
          div(data: { controller: "design-system" }) do
            header(class: "border-b border-border bg-card") do
              div(class: "max-w-7xl mx-auto px-4 py-6") do
                div(class: "flex items-center justify-between") do
                  div do
                    h1(class: "text-3xl font-bold") { t("design_system.catalog.title") }
                    p(class: "text-muted-foreground mt-2") { t("design_system.catalog.subtitle") }
                  end

                  render Components::Shared::ThemeToggle.new
                end
              end
            end

            div(class: "border-b border-border bg-card/50") do
              div(class: "max-w-7xl mx-auto px-4 py-4") do
                div(class: "flex gap-2 flex-wrap") do
                  category_button(id: "foundation", label: t("design_system.catalog.categories.foundation"), active: true)
                  category_button(id: "forms", label: t("design_system.catalog.categories.forms"))
                  category_button(id: "feedback", label: t("design_system.catalog.categories.feedback"))
                  category_button(id: "overlays", label: t("design_system.catalog.categories.overlays"))
                  category_button(id: "tables", label: t("design_system.catalog.categories.tables"))
                  category_button(id: "complex", label: t("design_system.catalog.categories.complex"))
                end
              end
            end

            main(class: "max-w-7xl mx-auto px-4 py-8") do
              foundation_section
              forms_section
              feedback_section
              overlays_section
              tables_section
              complex_section

              div(class: "mt-12 p-6 bg-muted rounded-lg") do
                h3(class: "font-bold mb-2") { t("design_system.catalog.status.title") }
                ul(class: "text-sm text-muted-foreground space-y-1") do
                  t("design_system.catalog.status.items").each do |item|
                    li { item }
                  end
                end
              end
            end
          end
        end
      end

      private

      def category_button(id:, label:, active: false)
        render Components::Ui::Button.new(
          variant: :ghost,
          size: :sm,
          class: "data-[state=active]:bg-primary data-[state=active]:text-primary-foreground",
          data: {
            action: "click->design-system#select",
            design_system_target: "tab",
            category: id,
            state: active ? "active" : "inactive"
          }
        ) { label }
      end

      def section_container(id:, hidden: true, &block)
        classes = [ "space-y-8" ]
        classes << "hidden" if hidden

        div(
          class: classes.join(" "),
          data: {
            design_system_target: "category",
            category: id
          },
          &block
        )
      end

      def component_card(title:, description:, &block)
        render Components::Ui::Card.new(class: "mb-6") do |card|
          card.header do
            card.title { title }
            card.description { description }
          end

          card.content(class: "space-y-4", &block)
        end
      end

      def foundation_section
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

      def forms_section
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
                render Components::Ui::Switch.new(
                  id: "notifications"
                ) do |switch|
                  switch.thumb
                end
                render Components::Ui::Label.new(for: "notifications") { t("design_system.catalog.forms.switch.label") }
              end

              div(class: "flex items-center space-x-2") do
                render Components::Ui::Switch.new(
                  checked: true,
                  id: "notifications-checked"
                ) do |switch|
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
              render Components::Ui::Select.new(
                placeholder: t("design_system.catalog.forms.select.placeholder")
              ) do |select|
                select.trigger do
                  select.value
                  render Components::Ui::Icon.new(:"chevron-down", source: :lucide, class: "h-4 w-4 opacity-50")
                end

                select.content(hidden: true) do
                  select.item(
                    value: "apple",
                    tabindex: "0"
                  ) { t("design_system.catalog.forms.select.option_one") }

                  select.item(
                    value: "banana",
                    tabindex: "0"
                  ) { t("design_system.catalog.forms.select.option_two") }

                  select.item(
                    value: "orange",
                    tabindex: "0"
                  ) { t("design_system.catalog.forms.select.option_three") }
                end
              end
            end
          end
        end
      end

      def feedback_section
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

      def overlays_section
        section_container(id: "overlays") do
          div(class: "space-y-8") do
            h2(class: "text-2xl font-bold") { t("design_system.catalog.overlays.title") }

            popover_card
            hover_card_card
            dialog_card
            alert_dialog_card
            sheet_card
            tooltip_card
          end
        end
      end

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

      def tables_section
        section_container(id: "tables") do
          div(class: "space-y-8") do
            h2(class: "text-2xl font-bold") { t("design_system.catalog.tables.title") }

            # Basic Table
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

            # With Footer
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

            # Simple
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

            # With Badges
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

            # With Actions
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

                            dropdown.content(
                              hidden: true,
                              align: :end
                            ) do
                              dropdown.item(
                              ) { t("design_system.catalog.tables.with_actions.menu_edit") }
                              dropdown.item(
                              ) { t("design_system.catalog.tables.with_actions.menu_duplicate") }
                              dropdown.separator
                              dropdown.item(
                                variant: :destructive
                              ) { t("design_system.catalog.tables.with_actions.menu_delete") }
                            end
                          end
                        end
                      end
                    end
                  end
                end
            end

            # With Select
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
                      table.cell do
                        render Components::Ui::Select.new(
                          default_value: "progress",
                          placeholder: t("design_system.catalog.tables.with_select.status_placeholder"),
                          class: "w-[140px]"
                        ) do |select|
                          select.trigger do
                            select.value
                            render Components::Ui::Icon.new(:"chevron-down", source: :lucide, class: "h-4 w-4 opacity-50")
                          end

                          select.content(hidden: true) do
                            select.item(
                              value: "progress",
                              tabindex: "0"
                            ) { t("design_system.catalog.tables.with_select.status_progress") }

                            select.item(
                              value: "pending",
                              tabindex: "0"
                            ) { t("design_system.catalog.tables.with_select.status_pending") }

                            select.item(
                              value: "not-started",
                              tabindex: "0"
                            ) { t("design_system.catalog.tables.with_select.status_not_started") }
                          end
                        end
                      end
                    end

                    table.row do
                      table.cell(class: "font-medium") { t("design_system.catalog.tables.with_select.task_2") }
                      table.cell { t("design_system.catalog.tables.with_select.user_2") }
                      table.cell do
                        render Components::Ui::Select.new(
                          default_value: "pending",
                          placeholder: t("design_system.catalog.tables.with_select.status_placeholder"),
                          class: "w-[140px]"
                        ) do |select|
                          select.trigger do
                            select.value
                            render Components::Ui::Icon.new(:"chevron-down", source: :lucide, class: "h-4 w-4 opacity-50")
                          end

                          select.content(hidden: true) do
                            select.item(
                              value: "progress",
                              tabindex: "0"
                            ) { t("design_system.catalog.tables.with_select.status_progress") }

                            select.item(
                              value: "pending",
                              tabindex: "0"
                            ) { t("design_system.catalog.tables.with_select.status_pending") }

                            select.item(
                              value: "not-started",
                              tabindex: "0"
                            ) { t("design_system.catalog.tables.with_select.status_not_started") }
                          end
                        end
                      end
                    end

                    table.row do
                      table.cell(class: "font-medium") { t("design_system.catalog.tables.with_select.task_3") }
                      table.cell { t("design_system.catalog.tables.with_select.user_3") }
                      table.cell do
                        render Components::Ui::Select.new(
                          default_value: "not-started",
                          placeholder: t("design_system.catalog.tables.with_select.status_placeholder"),
                          class: "w-[140px]"
                        ) do |select|
                          select.trigger do
                            select.value
                            render Components::Ui::Icon.new(:"chevron-down", source: :lucide, class: "h-4 w-4 opacity-50")
                          end

                          select.content(hidden: true) do
                            select.item(
                              value: "progress",
                              tabindex: "0"
                            ) { t("design_system.catalog.tables.with_select.status_progress") }

                            select.item(
                              value: "pending",
                              tabindex: "0"
                            ) { t("design_system.catalog.tables.with_select.status_pending") }

                            select.item(
                              value: "not-started",
                              tabindex: "0"
                            ) { t("design_system.catalog.tables.with_select.status_not_started") }
                          end
                        end
                      end
                    end
                  end
                end
            end

            # With Input
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
        end
      end

      def complex_section
        section_container(id: "complex") do
          div(class: "space-y-8") do
            h2(class: "text-2xl font-bold") { t("design_system.catalog.complex.title") }

            render Components::Ui::Card.new do |card|
              card.header do
                card.title { t("design_system.catalog.complex.card_title") }
                card.description do
                  t("design_system.catalog.complex.card_description")
                end
              end

              card.content do
                p(class: "text-muted-foreground") { t("design_system.catalog.complex.body") }

                div(class: "mt-4 grid grid-cols-2 gap-2 text-sm") do
                  complex_components.each do |component_name|
                    div(class: "px-3 py-2 rounded-md border border-border bg-muted/40") { component_name }
                  end
                end
              end
            end
          end
        end
      end

      def complex_components
        [
          "accordion",
          "calendar",
          "carousel",
          "command",
          "context-menu",
          "navigation-menu",
          "pagination",
          "popover",
          "progress",
          "scroll-area",
          "slider",
          "sonner",
          "toggle-group"
        ]
      end
    end
  end
end
