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

                  div(class: "flex items-center gap-3") do
                    # use the shared Button component so style matches React catalog
                    render Components::Ui::Button.new(
                      variant: :outline,
                      size: :sm,
                      type: :button,
                      data: {
                        controller: "ui--theme",
                        action: "click->ui--theme#toggle",
                        ui_theme_dark_label: t("design_system.catalog.toggle_dark"),
                        ui_theme_light_label: t("design_system.catalog.toggle_light")
                      }
                    ) do
                      span(class: "dark:hidden") { "🌙 #{t("design_system.catalog.dark")}" }
                      span(class: "hidden dark:inline") { "☀️ #{t("design_system.catalog.light")}" }
                    end
                  end
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
                  category_button(id: "complex", label: t("design_system.catalog.categories.complex"))
                end
              end
            end

            main(class: "max-w-7xl mx-auto px-4 py-8") do
              foundation_section
              forms_section
              feedback_section
              overlays_section
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
        render Components::Ui::Card.new(class: "mb-6") do
          render Components::Ui::CardHeader.new do
            render Components::Ui::CardTitle.new { title }
            render Components::Ui::CardDescription.new { description }
          end

          render Components::Ui::CardContent.new(class: "space-y-4", &block)
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
                  id: "notifications",
                  data: {
                    controller: "ui--switch",
                    action: "click->ui--switch#toggle keydown->ui--switch#keydown"
                  }
                ) do
                  render Components::Ui::SwitchThumb.new(data: { ui__switch_target: "thumb" })
                end
                render Components::Ui::Label.new(for: "notifications") { t("design_system.catalog.forms.switch.label") }
              end

              div(class: "flex items-center space-x-2") do
                render Components::Ui::Switch.new(
                  checked: true,
                  id: "notifications-checked",
                  data: {
                    controller: "ui--switch",
                    ui__switch_checked_value: true,
                    action: "click->ui--switch#toggle keydown->ui--switch#keydown"
                  }
                ) do
                  render Components::Ui::SwitchThumb.new(data: { ui__switch_target: "thumb" })
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
              render Components::Ui::Select.new do
                option(value: "") { t("design_system.catalog.forms.select.placeholder") }
                option(value: "option-1") { t("design_system.catalog.forms.select.option_one") }
                option(value: "option-2") { t("design_system.catalog.forms.select.option_two") }
                option(value: "option-3") { t("design_system.catalog.forms.select.option_three") }
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
              render Components::Ui::Alert.new do
                render Components::Ui::AlertTitle.new { t("design_system.catalog.feedback.alert.info_title") }
                render Components::Ui::AlertDescription.new { t("design_system.catalog.feedback.alert.info_body") }
              end

              render Components::Ui::Alert.new(variant: :destructive) do
                render Components::Ui::AlertTitle.new { t("design_system.catalog.feedback.alert.error_title") }
                render Components::Ui::AlertDescription.new { t("design_system.catalog.feedback.alert.error_body") }
              end
            end

            component_card(
              title: t("design_system.catalog.feedback.tabs.title"),
              description: t("design_system.catalog.feedback.tabs.description")
            ) do
              div(data: { controller: "ui--tabs", ui__tabs_active_index_value: 0 }) do
                # tabs list
                div(role: :tablist, class: "inline-flex h-9 items-center justify-center rounded-lg bg-muted p-1 text-muted-foreground") do
                  [
                    t("design_system.catalog.feedback.tabs.tab_one"),
                    t("design_system.catalog.feedback.tabs.tab_two"),
                    t("design_system.catalog.feedback.tabs.tab_three")
                  ].each do |label|
                    button(
                      type: :button,
                      role: :tab,
                      class: "inline-flex items-center justify-center whitespace-nowrap rounded-md px-3 py-1 text-sm font-medium ring-offset-background transition-all focus-visible:outline-none focus-visible:ring-3 focus-visible:ring-ring/20 disabled:pointer-events-none disabled:opacity-50 data-[state=active]:bg-background data-[state=active]:text-foreground data-[state=active]:shadow",
                      data: { ui__tabs_target: "trigger", action: "click->ui--tabs#select keydown->ui--tabs#keydown" }
                    ) { label }
                  end
                end

                # panels
                [
                  t("design_system.catalog.feedback.tabs.content_one"),
                  t("design_system.catalog.feedback.tabs.content_two"),
                  t("design_system.catalog.feedback.tabs.content_three")
                ].each do |content|
                  div(
                    data: { ui__tabs_target: "content" },
                    role: :tabpanel,
                    class: "mt-2 ring-offset-background focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2"
                  ) { content }
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

            dialog_card
            alert_dialog_card
            sheet_card
            tooltip_card
          end
        end
      end

      def dialog_card
        component_card(
          title: t("design_system.catalog.overlays.dialog.title"),
          description: t("design_system.catalog.overlays.dialog.description")
        ) do
          div(data: { controller: "ui--dialog", ui__dialog_open_value: false }) do
            render Components::Ui::Button.new(
              variant: :outline,
              data: { action: "click->ui--dialog#open" }
            ) { t("design_system.catalog.overlays.dialog.trigger") }

            render Components::Ui::DialogOverlay.new(
              hidden: true,
              data: { ui__dialog_target: "overlay" }
            )

            render Components::Ui::DialogContent.new(
              hidden: true,
              data: { ui__dialog_target: "content" }
            ) do
              render Components::Ui::DialogHeader.new do
                render Components::Ui::DialogTitle.new { t("design_system.catalog.overlays.dialog.content_title") }
                render Components::Ui::DialogDescription.new { t("design_system.catalog.overlays.dialog.content_body") }
              end

              render Components::Ui::DialogFooter.new(class: "mt-4") do
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
          div(data: { controller: "ui--dialog", ui__dialog_open_value: false }) do
            render Components::Ui::Button.new(
              variant: :destructive,
              data: { action: "click->ui--dialog#open" }
            ) { t("design_system.catalog.overlays.alert_dialog.trigger") }

            render Components::Ui::AlertDialogOverlay.new(
              hidden: true,
              data: { ui__dialog_target: "overlay" }
            )

            render Components::Ui::AlertDialogContent.new(
              hidden: true,
              data: { ui__dialog_target: "content" }
            ) do
              render Components::Ui::AlertDialogHeader.new do
                render Components::Ui::AlertDialogTitle.new { t("design_system.catalog.overlays.alert_dialog.content_title") }
                render Components::Ui::AlertDialogDescription.new do
                  t("design_system.catalog.overlays.alert_dialog.content_body")
                end
              end

              render Components::Ui::AlertDialogFooter.new(class: "mt-4") do
                render Components::Ui::AlertDialogCancel.new(data: { action: "click->ui--dialog#close" }) do
                  t("design_system.catalog.overlays.alert_dialog.cancel")
                end
                render Components::Ui::AlertDialogAction.new(data: { action: "click->ui--dialog#close" }) do
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
          div(data: { controller: "ui--dialog", ui__dialog_open_value: false }) do
            render Components::Ui::Button.new(
              variant: :outline,
              data: { action: "click->ui--dialog#open" }
            ) { t("design_system.catalog.overlays.sheet.trigger") }

            render Components::Ui::SheetOverlay.new(
              hidden: true,
              data: { ui__dialog_target: "overlay" }
            )

            render Components::Ui::SheetContent.new(
              hidden: true,
              side: :right,
              data: {
                ui__dialog_target: "content",
                dialog_transition: "slide"
              }
            ) do
              render Components::Ui::SheetHeader.new do
                render Components::Ui::SheetTitle.new { t("design_system.catalog.overlays.sheet.content_title") }
                render Components::Ui::SheetDescription.new { t("design_system.catalog.overlays.sheet.content_body") }
              end

              render Components::Ui::SheetFooter.new(class: "mt-4") do
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
          div(
            class: "inline-block",
            data: {
              controller: "ui--tooltip",
              ui__tooltip_delay_value: 200
            }
          ) do
            render Components::Ui::TooltipTrigger.new(
              data: {
                ui__tooltip_target: "trigger",
                action: "mouseenter->ui--tooltip#show mouseleave->ui--tooltip#hide focus->ui--tooltip#show blur->ui--tooltip#hide"
              }
            ) do
              render Components::Ui::Button.new(variant: :outline) { t("design_system.catalog.overlays.tooltip.trigger") }
            end

            render Components::Ui::TooltipContent.new(
              hidden: true,
              data: { ui__tooltip_target: "content" }
            ) do
              t("design_system.catalog.overlays.tooltip.content")
            end
          end
        end
      end

      def complex_section
        section_container(id: "complex") do
          div(class: "space-y-8") do
            h2(class: "text-2xl font-bold") { t("design_system.catalog.complex.title") }

            render Components::Ui::Card.new do
              render Components::Ui::CardHeader.new do
                render Components::Ui::CardTitle.new { t("design_system.catalog.complex.card_title") }
                render Components::Ui::CardDescription.new do
                  t("design_system.catalog.complex.card_description")
                end
              end

              render Components::Ui::CardContent.new do
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
