# frozen_string_literal: true

module Components
  module Shared
    class LanguageToggle < Components::Base
      def initialize(**attrs)
        @attrs = attrs
      end

      def view_template
        div(**attrs_without_class) do
          render Components::Ui::DropdownMenu.new do |menu|
            menu.trigger(
              class: "inline-flex h-8 items-center gap-2 rounded-full border border-border bg-background px-2.5 text-xs font-semibold uppercase tracking-[0.16em] text-foreground/80",
              aria: { label: t("components.shared.language_toggle.toggle_label") }
            ) do
              render Components::Ui::Icon.new(:globe, class: "size-3.5")
              span(class: "hidden sm:inline") { current_locale_code }
            end

            menu.content(class: "w-40") do
              menu.label { t("components.shared.language_toggle.menu_label") }

              available_locales.each do |locale|
                menu.item(href: locale_href(locale), aria: { current: active_locale?(locale) ? "true" : nil }) do
                  span { locale_label(locale) }
                  render Components::Ui::Icon.new(:check, class: checkmark_classes(locale))
                end
              end
            end
          end
        end
      end

      private

      def available_locales
        I18n.available_locales
      end

      def active_locale?(locale)
        I18n.locale.to_sym == locale.to_sym
      end

      def current_locale_code
        I18n.locale.to_s.upcase
      end

      def locale_label(locale)
        t("components.shared.language_toggle.#{locale_key(locale)}")
      end

      def locale_href(locale)
        request = view_context.request
        path_parameters = request.path_parameters.symbolize_keys

        return root_path(locale: locale) if path_parameters[:controller].blank? || path_parameters[:action].blank?

        view_context.url_for(
          path_parameters
            .except(:locale, :format)
            .merge(request.query_parameters.symbolize_keys.except(:locale))
            .merge(locale: locale, only_path: true)
        )
      rescue ActionController::UrlGenerationError
        root_path(locale: locale)
      end

      def locale_key(locale)
        locale.to_sym == :es ? :spanish : :english
      end

      def checkmark_classes(locale)
        cn(
          "ml-auto size-4 shrink-0 transition-opacity",
          active_locale?(locale) ? "opacity-100" : "opacity-0"
        )
      end
    end
  end
end
