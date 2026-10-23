# frozen_string_literal: true

# Global theme toggle rendered in both admin and public navbars.
#
# A sun/moon icon button opens a 3-option dropdown:
#   Light · Dark · System
#
# "System" (the default) follows prefers-color-scheme. The active option shows a checkmark driven by the `data-theme`
# attribute that the chadcn--theme Stimulus controller writes to <html>. The choice persists under STORAGE_KEY, the key the
# layouts' pre-paint script reads. The menu content is portaled into <body>, so it carries its own chadcn--theme controller
# for the item actions; the wrapper's keeps following the OS preference while the menu is closed.
#
# Usage:
#   render Components::Shared::ThemeToggle.new
module Components
  module Shared
    class ThemeToggle < Components::Base
      STORAGE_KEY = "papyro-theme"
      # Stimulus data for an element that hosts the theme controller.
      CONTROLLER_DATA = { controller: "chadcn--theme", chadcn__theme_storage_key_value: STORAGE_KEY }.freeze
      CHOICES = [
        { theme: "light", action: "setLight", icon: :sun },
        { theme: "dark", action: "setDark", icon: :moon },
        { theme: "system", action: "setSystem", icon: :monitor }
      ].freeze

      def initialize(**attrs)
        @attrs = attrs
      end

      def view_template
        div(data: CONTROLLER_DATA, **attrs_without_class) do
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
                menu.item(data: { action: "click->chadcn--theme##{choice[:action]}" }) do
                  render Components::Shared::Icon.new(choice[:icon], class: "size-4 shrink-0")
                  span { t("design_system.theme.#{choice[:theme]}") }
                  render Components::Shared::Icon.new(:check, class: "ml-auto size-4 shrink-0 theme-check-#{choice[:theme]} opacity-0 transition-opacity")
                end
              end
            end
          end
        end
      end
    end
  end
end
