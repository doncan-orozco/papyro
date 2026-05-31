# frozen_string_literal: true

# Global theme toggle rendered in both admin and public navbars.
#
# A sun/moon icon button opens a 3-option dropdown:
#   Light · Dark · System
#
# "System" (the default) respects prefers-color-scheme automatically via CSS.
# The active option shows a checkmark driven by the `data-theme` attribute
# that the ui--theme Stimulus controller writes to <html>.
#
# Usage:
#   render Components::Shared::ThemeToggle.new
module Components
  module Shared
    class ThemeToggle < Components::Base
      def initialize(**attrs)
        @attrs = attrs
      end

      def view_template
        div(data: { controller: "ui--theme" }, **attrs_without_class) do
          render Components::Ui::DropdownMenu.new do |menu|
            menu.trigger(
              class: "size-10 p-0",
              aria: { label: t("design_system.theme.toggle_label") }
            ) do
              render Components::Ui::Icon.new(:sun, class: "size-4 dark:hidden")
              render Components::Ui::Icon.new(:moon, class: "hidden size-4 dark:block")
            end

            menu.content(class: "w-36") do
              menu.item(data: { action: "click->ui--theme#setLight" }) do
                render Components::Ui::Icon.new(:sun, class: "mr-2 size-4 shrink-0")
                span { t("design_system.theme.light") }
                render Components::Ui::Icon.new(:check, class: "ml-auto size-4 shrink-0 theme-check-light opacity-0 transition-opacity")
              end

              menu.item(data: { action: "click->ui--theme#setDark" }) do
                render Components::Ui::Icon.new(:moon, class: "mr-2 size-4 shrink-0")
                span { t("design_system.theme.dark") }
                render Components::Ui::Icon.new(:check, class: "ml-auto size-4 shrink-0 theme-check-dark opacity-0 transition-opacity")
              end

              menu.item(data: { action: "click->ui--theme#setSystem" }) do
                render Components::Ui::Icon.new(:monitor, class: "mr-2 size-4 shrink-0")
                span { t("design_system.theme.system") }
                render Components::Ui::Icon.new(:check, class: "ml-auto size-4 shrink-0 theme-check-system opacity-0 transition-opacity")
              end
            end
          end
        end
      end
    end
  end
end
