# frozen_string_literal: true

# Global theme toggle rendered in the public, article, Studio navbars and the design-system pages.
#
# A sun/moon icon button opens a 3-option dropdown:
#   Light · Dark · System
#
# "System" (the default) follows prefers-color-scheme. The active option shows a checkmark driven by the `data-theme`
# attribute that the chadcn--theme Stimulus controller writes to <html>. The choice persists under STORAGE_KEY, the key the
# layouts' pre-paint script reads. The menu content is portaled into <body>, so it carries its own chadcn--theme controller
# for the item actions.
#
# Only portaled content hosts chadcn--theme (the dropdown content here, the navbar's mobile-sheet theme buttons): two
# instances on one page do not stay in sync (upstream chadcn bug, evidence in the lesson note on epic item #291; upstream
# issue pending), so a long-lived wrapper instance would re-apply a stale theme on OS changes. Live OS following in system
# mode while menus are closed waits for the upstream fix; the layouts' pre-paint script applies the stored theme on load.
#
# Usage:
#   render Components::Shared::ThemeToggle.new
module Components
  module Shared
    class ThemeToggle < Components::Base
      STORAGE_KEY = "papyro-theme"
      # Stimulus data for an element that hosts the theme controller.
      CONTROLLER_DATA = { controller: "chadcn--theme", chadcn__theme_storage_key_value: STORAGE_KEY }.freeze
      Choice = Data.define(:theme, :action, :icon, :label_key) do
        def stimulus_action = "click->chadcn--theme##{action}"

        def check_hook = "theme-check-#{theme}"
      end
      CHOICES = [
        Choice.new(theme: "light", action: "setLight", icon: :sun, label_key: "design_system.theme.light"),
        Choice.new(theme: "dark", action: "setDark", icon: :moon, label_key: "design_system.theme.dark"),
        Choice.new(theme: "system", action: "setSystem", icon: :monitor, label_key: "design_system.theme.system")
      ].freeze

      def initialize(**attrs)
        @attrs = attrs
      end

      def view_template
        div(**attrs_without_class) do
          render Chadcn::DropdownMenu.new do |menu|
            menu.trigger(
              as_child: Chadcn::Button.new(variant: "ghost", size: "icon", class: "size-10"),
              aria: { label: t("design_system.theme.toggle_label") }
            ) do
              render Components::Shared::Icon.new(:sun, class: "size-4 dark:hidden")
              render Components::Shared::Icon.new(:moon, class: "hidden size-4 dark:block")
            end

            menu.content(class: "w-36", data: CONTROLLER_DATA) do
              CHOICES.each do |choice|
                menu.item(data: { action: choice.stimulus_action }) do
                  render Components::Shared::Icon.new(choice.icon, class: "size-4 shrink-0")
                  span { t(choice.label_key) }
                  render Components::Shared::Icon.new(:check, class: "ml-auto size-4 shrink-0 #{choice.check_hook} opacity-0 transition-opacity")
                end
              end
            end
          end
        end
      end
    end
  end
end
