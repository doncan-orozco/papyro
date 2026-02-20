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

        div(class: "min-h-screen bg-background text-foreground font-['Manrope']") do
          render_background

          main(class: "relative mx-auto max-w-6xl px-6 py-12 lg:px-10") do
            render_header
            render_navigation

            div(class: "mt-12 space-y-14") do
              render_buttons_section
              render_forms_section
              render_feedback_section
              render_data_display_section
              render_layout_section
              render_interactive_section
              render_media_section
              render_navigation_section
              render_advanced_forms_section
              render_overlays_section
              render_toggles_section
              render_data_display_advanced_section
              render_notifications_section
            end
          end
        end
      end

      private

      def render_background
        div(class: "pointer-events-none absolute inset-0 overflow-hidden") do
          div(class: "absolute -top-40 left-1/2 h-80 w-[48rem] -translate-x-1/2 rounded-full bg-gradient-to-br from-primary/15 via-transparent to-secondary/25 blur-3xl")
          div(class: "absolute -bottom-32 right-0 h-72 w-72 rounded-full bg-gradient-to-tr from-accent/20 via-transparent to-primary/15 blur-2xl")
        end
      end

      def render_header
        div(class: "space-y-6 border-b border-border pb-10 motion-safe:animate-[catalog-fade_0.6s_ease-out]") do
          render Components::Ui::Badge.new(variant: :secondary, class: "uppercase tracking-[0.2em]") do
            t("design_system.page.badge")
          end

          h1(class: "text-4xl font-['Fraunces'] tracking-tight md:text-5xl") do
            t("design_system.page.title")
          end

          p(class: "max-w-2xl text-lg text-muted-foreground") do
            t("design_system.page.description")
          end

          div(class: "flex flex-wrap gap-3 text-sm text-muted-foreground") do
            render Components::Ui::Badge.new(variant: :outline) { t("design_system.page.chip_one") }
            render Components::Ui::Badge.new(variant: :outline) { t("design_system.page.chip_two") }
            render Components::Ui::Badge.new(variant: :outline) { t("design_system.page.chip_three") }
          end

          p(class: "text-sm text-muted-foreground") do
            t("design_system.page.note")
          end
        end
      end

      def render_navigation
        nav(class: "mt-8 flex flex-wrap gap-2 text-sm text-muted-foreground") do
          nav_link("design_system.sections.buttons.title", "#buttons")
          nav_link("design_system.sections.forms.title", "#forms")
          nav_link("design_system.sections.feedback.title", "#feedback")
          nav_link("design_system.sections.data_display.title", "#data-display")
          nav_link("design_system.sections.layout.title", "#layout")
          nav_link("Interactive", "#interactive")
          nav_link("design_system.sections.media.title", "#media")
          nav_link("Navigation", "#navigation")
          nav_link("Advanced Forms", "#advanced-forms")
          nav_link("Overlays", "#overlays")
          nav_link("Toggles", "#toggles")
          nav_link("Data Display Advanced", "#data-display-advanced")
          nav_link("Notifications", "#notifications")
        end
      end

      def nav_link(label_key, href)
        a(
          href: href,
          class: "rounded-full border border-border px-3 py-1 transition-colors hover:bg-muted"
        ) { t(label_key) }
      end

      def render_buttons_section
        section(
          id: "buttons",
          class: "space-y-6 motion-safe:animate-[catalog-fade_0.6s_ease-out]",
          style: "animation-delay: 80ms"
        ) do
          render_section_header("design_system.sections.buttons.title", "design_system.sections.buttons.description")

          div(class: "grid gap-6 lg:grid-cols-3") do
            render_card("design_system.buttons.variants.title", "design_system.buttons.variants.description") do
              div(class: "flex flex-wrap gap-3") do
                render Components::Ui::Button.new(variant: :default) { t("design_system.buttons.variants.default") }
                render Components::Ui::Button.new(variant: :secondary) { t("design_system.buttons.variants.secondary") }
                render Components::Ui::Button.new(variant: :outline) { t("design_system.buttons.variants.outline") }
                render Components::Ui::Button.new(variant: :ghost) { t("design_system.buttons.variants.ghost") }
                render Components::Ui::Button.new(variant: :destructive) { t("design_system.buttons.variants.destructive") }
                render Components::Ui::Button.new(variant: :link) { t("design_system.buttons.variants.link") }
              end
            end

            render_card("design_system.buttons.sizes.title", "design_system.buttons.sizes.description") do
              div(class: "flex flex-wrap items-center gap-3") do
                render Components::Ui::Button.new(size: :xs) { t("design_system.buttons.sizes.xs") }
                render Components::Ui::Button.new(size: :sm) { t("design_system.buttons.sizes.sm") }
                render Components::Ui::Button.new(size: :default) { t("design_system.buttons.sizes.default") }
                render Components::Ui::Button.new(size: :lg) { t("design_system.buttons.sizes.lg") }
              end
            end

            render_card("design_system.buttons.icons.title", "design_system.buttons.icons.description") do
              div(class: "flex flex-wrap items-center gap-3") do
                render Components::Ui::Button.new(size: :"icon-xs", aria: { label: t("design_system.buttons.icons.label") }) do
                  span(class: "block h-3 w-3 rounded-full bg-foreground/40")
                end
                render Components::Ui::Button.new(size: :"icon-sm", aria: { label: t("design_system.buttons.icons.label") }) do
                  span(class: "block h-3.5 w-3.5 rounded-full bg-foreground/40")
                end
                render Components::Ui::Button.new(size: :icon, aria: { label: t("design_system.buttons.icons.label") }) do
                  span(class: "block h-4 w-4 rounded-full bg-foreground/40")
                end
                render Components::Ui::Button.new(size: :"icon-lg", aria: { label: t("design_system.buttons.icons.label") }) do
                  span(class: "block h-5 w-5 rounded-full bg-foreground/40")
                end
              end

              div(class: "mt-4 flex flex-wrap gap-3") do
                render Components::Ui::Button.new(disabled: true) { t("design_system.buttons.states.disabled") }
                render Components::Ui::Button.new("aria-invalid": "true") { t("design_system.buttons.states.invalid") }
                render Components::Ui::Button.new("aria-expanded": "true") { t("design_system.buttons.states.expanded") }
              end
            end
          end
        end
      end

      def render_forms_section
        section(
          id: "forms",
          class: "space-y-6 motion-safe:animate-[catalog-fade_0.6s_ease-out]",
          style: "animation-delay: 140ms"
        ) do
          render_section_header("design_system.sections.forms.title", "design_system.sections.forms.description")

          div(class: "grid gap-6 lg:grid-cols-2") do
            render_card("design_system.forms.inputs.title", "design_system.forms.inputs.description") do
              div(class: "space-y-4") do
                div(class: "space-y-2") do
                  render Components::Ui::Label.new(for: "catalog-email") { t("design_system.forms.inputs.email_label") }
                  render Components::Ui::Input.new(
                    id: "catalog-email",
                    type: :email,
                    placeholder: t("design_system.forms.inputs.email_placeholder")
                  )
                end

                div(class: "space-y-2") do
                  render Components::Ui::Label.new(for: "catalog-message") { t("design_system.forms.inputs.message_label") }
                  render Components::Ui::Textarea.new(
                    id: "catalog-message",
                    placeholder: t("design_system.forms.inputs.message_placeholder")
                  )
                end

                div(class: "space-y-2") do
                  render Components::Ui::Label.new(for: "catalog-role") { t("design_system.forms.inputs.role_label") }
                  render Components::Ui::Select.new(id: "catalog-role") do
                    option(value: "") { t("design_system.forms.inputs.role_placeholder") }
                    option(value: "admin") { t("design_system.forms.inputs.role_admin") }
                    option(value: "editor") { t("design_system.forms.inputs.role_editor") }
                    option(value: "viewer") { t("design_system.forms.inputs.role_viewer") }
                  end
                end
              end
            end

            render_card("design_system.forms.toggles.title", "design_system.forms.toggles.description") do
              div(class: "space-y-4") do
                div(class: "flex items-center space-x-2") do
                  render Components::Ui::Checkbox.new(id: "catalog-terms")
                  render Components::Ui::Label.new(for: "catalog-terms") { t("design_system.forms.toggles.terms_label") }
                end

                div(class: "space-y-2") do
                  render Components::Ui::Label.new { t("design_system.forms.toggles.notifications_label") }
                  div(class: "space-y-2") do
                    div(class: "flex items-center space-x-2") do
                      render Components::Ui::Radio.new(id: "catalog-email-radio", name: "notifications", value: "email")
                      render Components::Ui::Label.new(for: "catalog-email-radio") { t("design_system.forms.toggles.notification_email") }
                    end
                    div(class: "flex items-center space-x-2") do
                      render Components::Ui::Radio.new(id: "catalog-sms-radio", name: "notifications", value: "sms")
                      render Components::Ui::Label.new(for: "catalog-sms-radio") { t("design_system.forms.toggles.notification_sms") }
                    end
                  end
                end

                div(class: "flex items-center space-x-3") do
                  render Components::Ui::Switch.new(id: "catalog-switch", checked: true) do
                    render Components::Ui::SwitchThumb.new(data: { state: "checked" })
                  end
                  render Components::Ui::Label.new(for: "catalog-switch") { t("design_system.forms.toggles.switch_label") }
                end

                div(class: "space-y-2") do
                  render Components::Ui::Label.new(for: "catalog-disabled") { t("design_system.forms.toggles.disabled_label") }
                  render Components::Ui::Input.new(
                    id: "catalog-disabled",
                    placeholder: t("design_system.forms.toggles.disabled_placeholder"),
                    disabled: true
                  )
                end

                div(class: "space-y-2") do
                  render Components::Ui::Label.new(for: "catalog-invalid") { t("design_system.forms.toggles.invalid_label") }
                  render Components::Ui::Input.new(
                    id: "catalog-invalid",
                    placeholder: t("design_system.forms.toggles.invalid_placeholder"),
                    aria: { invalid: true }
                  )
                end
              end
            end
          end
        end
      end

      def render_feedback_section
        section(
          id: "feedback",
          class: "space-y-6 motion-safe:animate-[catalog-fade_0.6s_ease-out]",
          style: "animation-delay: 200ms"
        ) do
          render_section_header("design_system.sections.feedback.title", "design_system.sections.feedback.description")

          div(class: "grid gap-6 lg:grid-cols-2") do
            render_card("design_system.feedback.badges.title", "design_system.feedback.badges.description") do
              div(class: "flex flex-wrap gap-3") do
                render Components::Ui::Badge.new(variant: :default) { t("design_system.feedback.badges.default") }
                render Components::Ui::Badge.new(variant: :secondary) { t("design_system.feedback.badges.secondary") }
                render Components::Ui::Badge.new(variant: :destructive) { t("design_system.feedback.badges.destructive") }
                render Components::Ui::Badge.new(variant: :outline) { t("design_system.feedback.badges.outline") }
              end
            end

            render_card("design_system.feedback.alerts.title", "design_system.feedback.alerts.description") do
              div(class: "space-y-4") do
                render Components::Ui::Alert.new(variant: :default) do
                  render Components::Ui::AlertTitle.new { t("design_system.feedback.alerts.info_title") }
                  render Components::Ui::AlertDescription.new { t("design_system.feedback.alerts.info_body") }
                end

                render Components::Ui::Alert.new(variant: :destructive) do
                  render Components::Ui::AlertTitle.new { t("design_system.feedback.alerts.destructive_title") }
                  render Components::Ui::AlertDescription.new { t("design_system.feedback.alerts.destructive_body") }
                end
              end
            end
          end
        end
      end

      def render_data_display_section
        section(
          id: "data-display",
          class: "space-y-6 motion-safe:animate-[catalog-fade_0.6s_ease-out]",
          style: "animation-delay: 260ms"
        ) do
          render_section_header("design_system.sections.data_display.title", "design_system.sections.data_display.description")

          div(class: "grid gap-6 lg:grid-cols-2") do
            render_card("design_system.data_display.table.title", "design_system.data_display.table.description") do
              render Components::Ui::TableContainer.new do
                render Components::Ui::Table.new do
                  render Components::Ui::TableHeader.new do
                    render Components::Ui::TableRow.new do
                      render Components::Ui::TableHead.new { t("design_system.data_display.table.head_name") }
                      render Components::Ui::TableHead.new { t("design_system.data_display.table.head_status") }
                      render Components::Ui::TableHead.new(class: "text-right") { t("design_system.data_display.table.head_amount") }
                    end
                  end
                  render Components::Ui::TableBody.new do
                    render Components::Ui::TableRow.new do
                      render Components::Ui::TableCell.new(class: "font-medium") { t("design_system.data_display.table.row_one_name") }
                      render Components::Ui::TableCell.new do
                        render Components::Ui::Badge.new(variant: :outline) { t("design_system.data_display.table.row_one_status") }
                      end
                      render Components::Ui::TableCell.new(class: "text-right") { t("design_system.data_display.table.row_one_amount") }
                    end
                    render Components::Ui::TableRow.new do
                      render Components::Ui::TableCell.new(class: "font-medium") { t("design_system.data_display.table.row_two_name") }
                      render Components::Ui::TableCell.new do
                        render Components::Ui::Badge.new(variant: :secondary) { t("design_system.data_display.table.row_two_status") }
                      end
                      render Components::Ui::TableCell.new(class: "text-right") { t("design_system.data_display.table.row_two_amount") }
                    end
                  end
                end
              end
            end

            render_card("design_system.data_display.progress.title", "design_system.data_display.progress.description") do
              div(class: "space-y-4") do
                div(class: "space-y-2") do
                  p(class: "text-sm text-muted-foreground") { t("design_system.data_display.progress.step_one") }
                  render Components::Ui::Progress.new(value: 25)
                end
                div(class: "space-y-2") do
                  p(class: "text-sm text-muted-foreground") { t("design_system.data_display.progress.step_two") }
                  render Components::Ui::Progress.new(value: 62)
                end
                div(class: "space-y-2") do
                  p(class: "text-sm text-muted-foreground") { t("design_system.data_display.progress.step_three") }
                  render Components::Ui::Progress.new(value: 100)
                end
              end
            end
          end

          div(class: "grid gap-6 lg:grid-cols-2") do
            render_card("design_system.data_display.skeleton.title", "design_system.data_display.skeleton.description") do
              div(class: "space-y-4") do
                div(class: "flex items-center space-x-4") do
                  render Components::Ui::Skeleton.new(class: "h-12 w-12 rounded-full")
                  div(class: "space-y-2 flex-1") do
                    render Components::Ui::Skeleton.new(class: "h-4 w-full")
                    render Components::Ui::Skeleton.new(class: "h-4 w-3/4")
                  end
                end
                render Components::Ui::Skeleton.new(class: "h-20 w-full")
              end
            end

            render_card("design_system.data_display.avatars.title", "design_system.data_display.avatars.description") do
              div(class: "flex items-center gap-4") do
                render Components::Ui::Avatar.new do
                  render Components::Ui::AvatarImage.new(
                    src: "https://github.com/shadcn.png",
                    alt: t("design_system.data_display.avatars.primary_alt")
                  )
                  render Components::Ui::AvatarFallback.new { t("design_system.data_display.avatars.primary_fallback") }
                end

                render Components::Ui::Avatar.new do
                  render Components::Ui::AvatarFallback.new { t("design_system.data_display.avatars.secondary_fallback") }
                end
              end
            end
          end
        end
      end

      def render_layout_section
        section(
          id: "layout",
          class: "space-y-6 motion-safe:animate-[catalog-fade_0.6s_ease-out]",
          style: "animation-delay: 320ms"
        ) do
          render_section_header("design_system.sections.layout.title", "design_system.sections.layout.description")

          div(class: "grid gap-6 lg:grid-cols-2") do
            render_card("design_system.layout.cards.title", "design_system.layout.cards.description") do
              div(class: "grid gap-4") do
                render Components::Ui::Card.new do
                  render Components::Ui::CardHeader.new do
                    render Components::Ui::CardTitle.new { t("design_system.layout.cards.primary_title") }
                    render Components::Ui::CardDescription.new { t("design_system.layout.cards.primary_description") }
                  end
                  render Components::Ui::CardContent.new do
                    p(class: "text-sm text-muted-foreground") { t("design_system.layout.cards.primary_body") }
                  end
                end

                render Components::Ui::Card.new do
                  render Components::Ui::CardHeader.new do
                    render Components::Ui::CardTitle.new { t("design_system.layout.cards.secondary_title") }
                    render Components::Ui::CardDescription.new { t("design_system.layout.cards.secondary_description") }
                  end
                  render Components::Ui::CardContent.new do
                    p(class: "text-sm text-muted-foreground") { t("design_system.layout.cards.secondary_body") }
                  end
                  render Components::Ui::CardFooter.new(class: "gap-2") do
                    render Components::Ui::Button.new(variant: :outline) { t("design_system.layout.cards.secondary_action") }
                    render Components::Ui::Button.new { t("design_system.layout.cards.secondary_primary") }
                  end
                end
              end
            end

            render_card("design_system.layout.tabs.title", "design_system.layout.tabs.description") do
              render Components::Ui::Tabs.new do
                render Components::Ui::TabsList.new do
                  render Components::Ui::TabsTrigger.new(data: { state: "active" }) { t("design_system.layout.tabs.first") }
                  render Components::Ui::TabsTrigger.new { t("design_system.layout.tabs.second") }
                end
                render Components::Ui::TabsContent.new do
                  p(class: "text-sm text-muted-foreground") { t("design_system.layout.tabs.first_body") }
                end
                render Components::Ui::TabsContent.new(class: "hidden") do
                  p(class: "text-sm text-muted-foreground") { t("design_system.layout.tabs.second_body") }
                end
              end
            end
          end

          div(class: "grid gap-6 lg:grid-cols-2") do
            render_card("design_system.layout.accordion.title", "design_system.layout.accordion.description") do
              render Components::Ui::Accordion.new do
                render Components::Ui::AccordionItem.new do
                  render Components::Ui::AccordionTrigger.new(data: { state: "open" }, controls_id: "catalog-accordion-one") do
                    t("design_system.layout.accordion.first_title")
                  end
                  render Components::Ui::AccordionContent.new(id: "catalog-accordion-one", data: { state: "open" }) do
                    render Components::Ui::AccordionContentInner.new do
                      p(class: "text-sm text-muted-foreground") { t("design_system.layout.accordion.first_body") }
                    end
                  end
                end

                render Components::Ui::AccordionItem.new do
                  render Components::Ui::AccordionTrigger.new(controls_id: "catalog-accordion-two") do
                    t("design_system.layout.accordion.second_title")
                  end
                  render Components::Ui::AccordionContent.new(id: "catalog-accordion-two") do
                    render Components::Ui::AccordionContentInner.new do
                      p(class: "text-sm text-muted-foreground") { t("design_system.layout.accordion.second_body") }
                    end
                  end
                end
              end
            end

            render_card("design_system.layout.separator.title", "design_system.layout.separator.description") do
              div(class: "space-y-4") do
                div(class: "space-y-2") do
                  p(class: "text-sm text-muted-foreground") { t("design_system.layout.separator.horizontal_label") }
                  render Components::Ui::Separator.new(orientation: :horizontal)
                end

                div(class: "flex h-16 items-center gap-4") do
                  p(class: "text-sm text-muted-foreground") { t("design_system.layout.separator.vertical_left") }
                  render Components::Ui::Separator.new(orientation: :vertical)
                  p(class: "text-sm text-muted-foreground") { t("design_system.layout.separator.vertical_right") }
                end
              end
            end
          end
        end
      end

      def render_interactive_section
        section(
          id: "interactive",
          class: "space-y-6 motion-safe:animate-[catalog-fade_0.6s_ease-out]",
          style: "animation-delay: 360ms"
        ) do
          render_section_header("Interactive Components (with Stimulus)", "Fully interactive components with keyboard navigation and accessibility")

          div(class: "grid gap-6 lg:grid-cols-2") do
            # Switch
            render_card("Switch", "Toggle on/off with click or Space/Enter") do
              div(class: "space-y-4") do
                div(class: "flex items-center space-x-2") do
                  render Components::Ui::Switch.new(
                    data: {
                      controller: "ui--switch",
                      ui__switch_checked_value: false,
                      action: "click->ui--switch#toggle"
                    }
                  ) do
                    render Components::Ui::SwitchThumb.new(data: { ui__switch_target: "thumb" })
                  end
                  span { "Airplane Mode" }
                end
                p(class: "text-xs text-muted-foreground") { "Try clicking or pressing Space" }
              end
            end

            # Tabs
            render_card("Tabs", "Keyboard navigation with Arrow keys") do
              render Components::Ui::Tabs.new(
                data: {
                  controller: "ui--tabs",
                  ui__tabs_active_index_value: 0
                }
              ) do
                render Components::Ui::TabsList.new do
                  render Components::Ui::TabsTrigger.new(
                    data: {
                      ui__tabs_target: "trigger",
                      action: "click->ui--tabs#select keydown->ui--tabs#keydown"
                    }
                  ) { "Account" }
                  render Components::Ui::TabsTrigger.new(
                    data: {
                      ui__tabs_target: "trigger",
                      action: "click->ui--tabs#select keydown->ui--tabs#keydown"
                    }
                  ) { "Settings" }
                end
                render Components::Ui::TabsContent.new(data: { ui__tabs_target: "content" }) do
                  p(class: "text-sm text-muted-foreground") { "Account settings..." }
                end
                render Components::Ui::TabsContent.new(data: { ui__tabs_target: "content" }) do
                  p(class: "text-sm text-muted-foreground") { "Preferences..." }
                end
              end
            end

            # Accordion
            render_card("Accordion", "Expand/collapse with Arrow keys") do
              render Components::Ui::Accordion.new(
                data: {
                  controller: "ui--accordion",
                  ui__accordion_allow_multiple_value: false
                }
              ) do
                render Components::Ui::AccordionItem.new do
                  render Components::Ui::AccordionTrigger.new(
                    data: {
                      ui__accordion_target: "trigger",
                      action: "click->ui--accordion#toggle keydown->ui--accordion#keydown"
                    }
                  ) do
                    plain "Is it interactive?"
                    svg(xmlns: "http://www.w3.org/2000/svg", class: "h-4 w-4 shrink-0 transition-transform duration-200", fill: "none", viewBox: "0 0 24 24", stroke: "currentColor") do |s|
                      s.path(stroke_linecap: "round", stroke_linejoin: "round", stroke_width: "2", d: "M19 9l-7 7-7-7")
                    end
                  end
                  render Components::Ui::AccordionContent.new(
                    data: { ui__accordion_target: "content" },
                    style: "max-height: 0"
                  ) do
                    render Components::Ui::AccordionContentInner.new do
                      plain "Yes! Click to toggle or use arrow keys."
                    end
                  end
                end
              end
            end

            # Tooltip
            render_card("Tooltip", "Hover or focus to see tooltip") do
              div(
                data: {
                  controller: "ui--tooltip",
                  ui__tooltip_delay_value: 200,
                  ui__tooltip_placement_value: "top"
                }
              ) do
                render Components::Ui::TooltipTrigger.new(
                  data: {
                    ui__tooltip_target: "trigger",
                    action: "mouseenter->ui--tooltip#show mouseleave->ui--tooltip#hide focus->ui--tooltip#show blur->ui--tooltip#hide"
                  }
                ) do
                  render Components::Ui::Button.new(variant: :outline) { "Hover or focus" }
                end
                render Components::Ui::TooltipContent.new(data: { ui__tooltip_target: "content" }) do
                  plain "Tooltip with auto-positioning"
                end
              end
            end

            # Dropdown
            render_card("Dropdown", "Arrow keys, ESC, click outside") do
              div(
                data: {
                  controller: "ui--dropdown",
                  ui__dropdown_placement_value: "bottom-start"
                }
              ) do
                render Components::Ui::DropdownMenuTrigger.new(
                  data: {
                    ui__dropdown_target: "trigger",
                    action: "click->ui--dropdown#toggle"
                  }
                ) { "Menu" }
                render Components::Ui::DropdownMenuContent.new(data: { ui__dropdown_target: "content" }) do
                  render Components::Ui::DropdownMenuLabel.new { "Actions" }
                  render Components::Ui::DropdownMenuSeparator.new
                  render Components::Ui::DropdownMenuItem.new(
                    data: {
                      ui__dropdown_target: "item",
                      action: "click->ui--dropdown#select keydown->ui--dropdown#itemKeydown"
                    }
                  ) { "Option 1" }
                  render Components::Ui::DropdownMenuItem.new(
                    data: {
                      ui__dropdown_target: "item",
                      action: "click->ui--dropdown#select keydown->ui--dropdown#itemKeydown"
                    }
                  ) { "Option 2" }
                end
              end
            end

            # Dialog
            render_card("Dialog", "Focus trap, ESC to close") do
              div(
                data: {
                  controller: "ui--dialog",
                  ui__dialog_open_value: false,
                  ui__dialog_close_on_overlay_click_value: true,
                  ui__dialog_close_on_esc_value: true
                }
              ) do
                render Components::Ui::Button.new(data: { action: "click->ui--dialog#open" }) { "Open Dialog" }
                render Components::Ui::DialogOverlay.new(data: { "ui--dialog-target": "overlay" }, hidden: true)
                render Components::Ui::DialogContent.new(data: { "ui--dialog-target": "content" }, hidden: true) do
                  render Components::Ui::DialogHeader.new do
                    render Components::Ui::DialogTitle.new { "Confirm Action" }
                  end
                  render Components::Ui::DialogFooter.new do
                    render Components::Ui::Button.new(variant: :outline, data: { action: "click->ui--dialog#close" }) { "Cancel" }
                    render Components::Ui::Button.new(data: { action: "click->ui--dialog#close" }) { "Continue" }
                  end
                end
              end
            end
          end
        end
      end

      def render_media_section
        section(
          id: "media",
          class: "space-y-6 motion-safe:animate-[catalog-fade_0.6s_ease-out]",
          style: "animation-delay: 440ms"
        ) do
          render_section_header("design_system.sections.media.title", "design_system.sections.media.description")

          div(class: "grid gap-6 lg:grid-cols-2") do
            render_card("design_system.media.social.title", "design_system.media.social.description") do
              div(class: "flex items-center gap-3") do
                render Components::Ui::SocialLink.new(platform: "twitter", url: "https://twitter.com")
                render Components::Ui::SocialLink.new(platform: "github", url: "https://github.com")
                render Components::Ui::SocialLink.new(platform: "linkedin", url: "https://linkedin.com")
              end
            end
          end
        end
      end

      def render_navigation_section
        section(
          id: "navigation",
          class: "space-y-6 motion-safe:animate-[catalog-fade_0.6s_ease-out]",
          style: "animation-delay: 500ms"
        ) do
          render_section_header("Navigation Components", "Components for navigating content")

          div(class: "grid gap-6 lg:grid-cols-2") do
            render_card("Breadcrumb", "Navigation path showing location hierarchy") do
              render Components::Ui::Breadcrumb.new do
                plain "Home / Products / Electronics"
              end
            end

            render_card("Pagination", "Navigate through pages of content") do
              render Components::Ui::Pagination.new do
                plain "1 2 3 ... 10"
              end
            end
          end
        end
      end

      def render_advanced_forms_section
        section(
          id: "advanced-forms",
          class: "space-y-6 motion-safe:animate-[catalog-fade_0.6s_ease-out]",
          style: "animation-delay: 560ms"
        ) do
          render_section_header("Advanced Form Components", "Complex form inputs and pickers")

          div(class: "grid gap-6 lg:grid-cols-2") do
            render_card("Calendar", "Date selection with calendar UI") do
              render Components::Ui::Calendar.new(
                mode: :single,
                data: {
                  controller: "ui--calendar",
                  ui__calendar_month_value: Date.today.month - 1,
                  ui__calendar_year_value: Date.today.year
                }
              ) do
                render Components::Ui::CalendarHeader.new do
                  render Components::Ui::Button.new(
                    variant: :outline,
                    size: :icon,
                    data: { action: "click->ui--calendar#previousMonth" }
                  ) { "←" }
                  render Components::Ui::CalendarHeading.new(
                    data: { ui__calendar_target: "monthYear" }
                  ) { "#{Date::MONTHNAMES[Date.today.month]} #{Date.today.year}" }
                  render Components::Ui::Button.new(
                    variant: :outline,
                    size: :icon,
                    data: { action: "click->ui--calendar#nextMonth" }
                  ) { "→" }
                end
                render Components::Ui::CalendarGrid.new do
                  render Components::Ui::CalendarHead.new do
                    render Components::Ui::CalendarHeadRow.new do
                      %w[Su Mo Tu We Th Fr Sa].each do |day|
                        render Components::Ui::CalendarHeadCell.new { day }
                      end
                    end
                  end
                  render Components::Ui::CalendarBody.new(
                    data: { ui__calendar_target: "days" }
                  )
                end
              end
            end

            render_card("Collapsible", "Expandable/collapsible content sections") do
              render Components::Ui::Collapsible.new(
                open: false,
                data: {
                  controller: "ui--collapsible",
                  ui__collapsible_open_value: false
                }
              ) do
                render Components::Ui::CollapsibleTrigger.new(
                  data: {
                    ui__collapsible_target: "trigger",
                    action: "click->ui--collapsible#toggle"
                  }
                ) { "Click to expand" }
                render Components::Ui::CollapsibleContent.new(
                  data: {
                    ui__collapsible_target: "content"
                  }
                ) do
                  p(class: "text-sm text-muted-foreground") { "Hidden content that can be toggled" }
                end
              end
            end

            render_card("Radio Group", "Select one option from a group") do
              render Components::Ui::RadioGroup.new(
                name: "demo-radio",
                data: {
                  controller: "ui--radio-group",
                  ui__radio_group_value_value: "option1"
                }
              ) do
                div(class: "flex items-center space-x-2") do
                  render Components::Ui::Radio.new(
                    id: "option1",
                    value: "option1",
                    name: "demo-radio",
                    checked: true,
                    data: {
                      ui__radio_group_target: "item",
                      action: "click->ui--radio-group#select"
                    }
                  )
                  render Components::Ui::Label.new(for: "option1") { "Option 1" }
                end
                div(class: "flex items-center space-x-2") do
                  render Components::Ui::Radio.new(
                    id: "option2",
                    value: "option2",
                    name: "demo-radio",
                    data: {
                      ui__radio_group_target: "item",
                      action: "click->ui--radio-group#select"
                    }
                  )
                  render Components::Ui::Label.new(for: "option2") { "Option 2" }
                end
              end
            end

            render_card("Slider", "Numeric range selection") do
              render Components::Ui::Slider.new(
                min: 0,
                max: 100,
                step: 1,
                value: 50,
                data: {
                  controller: "ui--slider",
                  ui__slider_value_value: 50,
                  ui__slider_min_value: 0,
                  ui__slider_max_value: 100,
                  action: "keydown->ui--slider#keydown mousedown->ui--slider#startDrag"
                }
              ) do
                render Components::Ui::SliderTrack.new(
                  data: { ui__slider_target: "track" }
                ) do
                  render Components::Ui::SliderRange.new(
                    data: { ui__slider_target: "range" },
                    style: "width: 50%"
                  )
                end
                render Components::Ui::SliderThumb.new(
                  data: { ui__slider_target: "thumb" },
                  style: "left: 50%"
                )
              end
              p(class: "mt-2 text-xs text-muted-foreground") { "Value: 50" }
            end
          end
        end
      end

      def render_overlays_section
        section(
          id: "overlays",
          class: "space-y-6 motion-safe:animate-[catalog-fade_0.6s_ease-out]",
          style: "animation-delay: 620ms"
        ) do
          render_section_header("Overlay Components", "Floating panels and popovers")

          div(class: "grid gap-6 lg:grid-cols-2") do
            render_card("Popover", "Floating content anchored to a trigger") do
              render Components::Ui::Popover.new(
                data: {
                  controller: "ui--popover",
                  ui__popover_open_value: false,
                  ui__popover_placement_value: "top"
                }
              ) do
                render Components::Ui::Button.new(
                  variant: :outline,
                  data: {
                    ui__popover_target: "trigger",
                    action: "click->ui--popover#toggle"
                  }
                ) { "Open Popover" }
                render Components::Ui::PopoverContent.new(
                  data: {
                    ui__popover_target: "content"
                  },
                  class: "z-50 rounded-md border bg-popover p-4 text-popover-foreground shadow-md outline-none",
                  style: "opacity: 0; transition: opacity 150ms ease-in-out"
                ) do
                  p(class: "text-sm") { "Popover content goes here" }
                end
              end
            end

            render_card("Hover Card", "Content revealed on hover") do
              render Components::Ui::HoverCard.new(
                data: {
                  controller: "ui--hover-card",
                  ui__hover_card_open_value: false,
                  ui__hover_card_delay_value: 200,
                  ui__hover_card_placement_value: "top"
                }
              ) do
                render Components::Ui::HoverCardTrigger.new(
                  data: {
                    ui__hover_card_target: "trigger",
                    action: "mouseenter->ui--hover-card#show mouseleave->ui--hover-card#hide focus->ui--hover-card#show blur->ui--hover-card#hide"
                  }
                ) do
                  render Components::Ui::Button.new(variant: :outline) { "Hover for more" }
                end
                render Components::Ui::HoverCardContent.new(
                  data: {
                    ui__hover_card_target: "content"
                  },
                  class: "z-50 rounded-md border bg-popover p-4 text-popover-foreground shadow-md outline-none",
                  style: "opacity: 0; visibility: hidden; transition: opacity 150ms ease-in-out"
                ) do
                  p(class: "text-sm") { "Additional information appears on hover" }
                end
              end
            end

            render_card("Sheet", "Side panel that slides in") do
              render Components::Ui::Sheet.new(
                data: {
                  controller: "ui--dialog",
                  ui__dialog_open_value: false,
                  ui__dialog_close_on_overlay_click_value: true
                }
              ) do
                div(class: "space-y-4") do
                  render Components::Ui::Button.new(
                    variant: :outline,
                    data: {
                      action: "click->ui--dialog#open"
                    }
                  ) { "Open Sheet" }
                  p(class: "text-xs text-muted-foreground") do
                    "Sheet is a slide-out panel variant of Dialog for displaying content from the side"
                  end
                end

                div(
                  data: {
                    ui__dialog_target: "overlay",
                    dialog_transition: "fade"
                  },
                  class: "fixed inset-0 z-40 bg-background/80 backdrop-blur-sm",
                  style: "opacity: 0; transition: opacity 150ms ease-in-out",
                  hidden: true
                )

                div(
                  data: {
                    ui__dialog_target: "content",
                    dialog_transition: "slide"
                  },
                  class: "fixed right-0 top-0 z-50 h-screen w-3/4 border-l bg-background shadow-lg md:w-1/2 lg:w-[400px]",
                  role: "dialog",
                  aria: { modal: true },
                  style: "transform: translateX(100%); transition: transform 300ms ease-in-out",
                  hidden: true
                ) do
                  div(class: "space-y-4 p-6") do
                    div(class: "flex items-center justify-between") do
                      h2(class: "text-lg font-semibold") { "Sheet Title" }
                      render Components::Ui::Button.new(
                        variant: :ghost,
                        size: :sm,
                        data: {
                          action: "click->ui--dialog#close",
                          ui__dialog_target: "closeButton"
                        }
                      ) { "✕" }
                    end
                    p(class: "text-sm text-muted-foreground") { "Sheet content goes here" }
                  end
                end
              end
            end
          end
        end
      end

      def render_toggles_section
        section(
          id: "toggles",
          class: "space-y-6 motion-safe:animate-[catalog-fade_0.6s_ease-out]",
          style: "animation-delay: 680ms"
        ) do
          render_section_header("Toggle Components", "State indicators and selectors")

          div(class: "grid gap-6 lg:grid-cols-2") do
            render_card("Toggle", "Button that toggles between two states") do
              render Components::Ui::Toggle.new(
                variant: :default,
                pressed: false,
                data: {
                  controller: "ui--toggle",
                  ui__toggle_pressed_value: false,
                  action: "click->ui--toggle#toggle"
                }
              ) do
                plain "Bold"
              end
            end

            render_card("Toggle Group", "Multiple toggleable options") do
              render Components::Ui::ToggleGroup.new(
                type: :single,
                data: {
                  controller: "ui--toggle-group",
                  ui__toggle_group_type_value: "single",
                  ui__toggle_group_value_value: ""
                }
              ) do
                render Components::Ui::Toggle.new(
                  data: {
                    ui__toggle_group_target: "toggle",
                    action: "click->ui--toggle-group#selectToggle",
                    value: "a"
                  }
                ) { "Option A" }
                render Components::Ui::Toggle.new(
                  data: {
                    ui__toggle_group_target: "toggle",
                    action: "click->ui--toggle-group#selectToggle",
                    value: "b"
                  }
                ) { "Option B" }
                render Components::Ui::Toggle.new(
                  data: {
                    ui__toggle_group_target: "toggle",
                    action: "click->ui--toggle-group#selectToggle",
                    value: "c"
                  }
                ) { "Option C" }
              end
            end
          end
        end
      end

      def render_data_display_advanced_section
        section(
          id: "data-display-advanced",
          class: "space-y-6 motion-safe:animate-[catalog-fade_0.6s_ease-out]",
          style: "animation-delay: 740ms"
        ) do
          render_section_header("Advanced Data Display", "Tables, carousels, and complex layouts")

          div(class: "grid gap-6 lg:grid-cols-1") do
            render_card("Carousel", "Rotating carousel of items") do
              render Components::Ui::Carousel.new(
                data: {
                  controller: "ui--carousel",
                  ui__carousel_current_index_value: 0,
                  ui__carousel_loop_value: true,
                  ui__carousel_auto_play_value: false
                }
              ) do
                div(class: "relative w-full") do
                  div(class: "flex overflow-hidden", data: { ui__carousel_target: "viewport" }) do
                    div(class: "min-w-0 shrink-0 grow-0 basis-full bg-muted p-8 rounded text-center", data: { ui__carousel_target: "item" }) { "Slide 1" }
                    div(class: "min-w-0 shrink-0 grow-0 basis-full bg-muted p-8 rounded text-center", data: { ui__carousel_target: "item" }) { "Slide 2" }
                    div(class: "min-w-0 shrink-0 grow-0 basis-full bg-muted p-8 rounded text-center", data: { ui__carousel_target: "item" }) { "Slide 3" }
                  end

                  div(class: "absolute inset-0 flex items-center justify-between px-4 pointer-events-none") do
                    render Components::Ui::Button.new(
                      variant: :outline,
                      size: :icon,
                      class: "pointer-events-auto",
                      data: { action: "click->ui--carousel#previous" }
                    ) { "←" }
                    render Components::Ui::Button.new(
                      variant: :outline,
                      size: :icon,
                      class: "pointer-events-auto",
                      data: { action: "click->ui--carousel#next" }
                    ) { "→" }
                  end
                end
              end
            end

            render_card("Data Table", "Structured data with sorting and filtering") do
              div(
                data: {
                  controller: "ui--data-table",
                  ui__data_table_sort_by_value: "",
                  ui__data_table_sort_order_value: "asc"
                }
              ) do
                render Components::Ui::Table.new(class: "w-full") do
                  render Components::Ui::TableHeader.new do
                    render Components::Ui::TableRow.new do
                      render Components::Ui::TableHead.new(
                        data: {
                          ui__data_table_target: "sortable",
                          column: "name",
                          action: "click->ui--data-table#sort"
                        },
                        class: "cursor-pointer"
                      ) { "Name" }
                      render Components::Ui::TableHead.new(
                        data: {
                          ui__data_table_target: "sortable",
                          column: "status",
                          action: "click->ui--data-table#sort"
                        },
                        class: "cursor-pointer"
                      ) { "Status" }
                      render Components::Ui::TableHead.new(class: "text-right") { "Amount" }
                    end
                  end
                  render Components::Ui::TableBody.new(
                    data: { ui__data_table_target: "body" }
                  ) do
                    render Components::Ui::TableRow.new(data: { ui__data_table_target: "row", name: "Alice" }) do
                      render Components::Ui::TableCell.new(class: "font-medium") { "Alice" }
                      render Components::Ui::TableCell.new do
                        render Components::Ui::Badge.new(variant: :outline) { "Active" }
                      end
                      render Components::Ui::TableCell.new(class: "text-right") { "$250.00" }
                    end
                    render Components::Ui::TableRow.new(data: { ui__data_table_target: "row", name: "Bob" }) do
                      render Components::Ui::TableCell.new(class: "font-medium") { "Bob" }
                      render Components::Ui::TableCell.new do
                        render Components::Ui::Badge.new(variant: :secondary) { "Pending" }
                      end
                      render Components::Ui::TableCell.new(class: "text-right") { "$150.00" }
                    end
                  end
                end
              end
            end

            render_card("Scroll Area", "Content with custom scrolling") do
              render Components::Ui::ScrollArea.new(class: "h-48 w-full rounded-md border") do
                div(class: "space-y-2 p-4") do
                  p { "Item 1" }
                  p { "Item 2" }
                  p { "Item 3" }
                  p { "Item 4" }
                  p { "Item 5" }
                end
              end
            end
          end
        end
      end

      def render_notifications_section
        section(
          id: "notifications",
          class: "space-y-6 motion-safe:animate-[catalog-fade_0.6s_ease-out]",
          style: "animation-delay: 800ms"
        ) do
          render_section_header("Notifications", "Toast and notification components")

          div(
            data: {
              controller: "ui--sonner",
              ui__sonner_max_toasts_value: 3,
              ui__sonner_position_value: "bottom-right"
            }
          ) do
            render Components::Ui::SonnerToaster.new(
              position: :bottom_right,
              data: {
                ui__sonner_target: "viewport"
              }
            )

            div(class: "grid gap-6 lg:grid-cols-2") do
              render_card("Toast", "Temporary notification messages") do
                div(class: "space-y-4") do
                  p(class: "text-sm text-muted-foreground") { "Toast notifications appear in corners and auto-dismiss" }
                  render Components::Ui::Button.new(
                    variant: :outline,
                    data: {
                      action: "click->ui--sonner#showDemo",
                      message: "Toast notification example",
                      type: "default"
                    }
                  ) { "Show Toast" }
                end
              end

              render_card("Sonner", "Advanced toast notification system") do
                div(class: "space-y-4") do
                  p(class: "text-sm text-muted-foreground") { "Rich toast notifications with customization" }
                  render Components::Ui::Button.new(
                    variant: :outline,
                    data: {
                      action: "click->ui--sonner#showDemo",
                      message: "Sonner notification example!",
                      type: "success"
                    }
                  ) { "Show Sonner Toast" }
                end
              end
            end
          end
        end
      end

      def render_section_header(title_key, description_key)
        div(class: "space-y-2") do
          h2(class: "text-2xl font-['Fraunces'] tracking-tight") { t(title_key) }
          p(class: "text-muted-foreground") { t(description_key) }
        end
      end

      def render_card(title_key, description_key = nil, &block)
        render Components::Ui::Card.new(class: "h-full") do
          render Components::Ui::CardHeader.new do
            render Components::Ui::CardTitle.new(class: "text-base") { t(title_key) }
            if description_key
              render Components::Ui::CardDescription.new { t(description_key) }
            end
          end
          render Components::Ui::CardContent.new, &block
        end
      end
    end
  end
end
