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
              class: "inline-flex h-10 items-center gap-2 rounded-full border border-border bg-background px-2.5 text-xs font-semibold uppercase tracking-[0.16em] text-foreground/80",
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
        return studio_locale_href(locale) if studio_request?(request)

        route_name = nil
        route_params = nil

        Rails.application.routes.router.recognize(request) do |route, params|
          next if route.name.blank?

          route_name = route.name
          route_params = params
          break
        end

        raise ActionController::UrlGenerationError, "Unnamed route" if route_name.blank?

        locale_pattern = I18n.available_locales.map(&:to_s).join("|")
        normalized_route_name = route_name.to_s
          .sub(/\A(?:#{locale_pattern})_/, "")
          .sub(/_(?:#{locale_pattern})\z/, "")

        localized_helper_name = "#{normalized_route_name}_#{locale}_path"
        generic_helper_name = "#{normalized_route_name}_path"

        localized_params = route_params.symbolize_keys
          .except(:locale, :format, :controller, :action)
          .merge(request.query_parameters.symbolize_keys.except(:locale))

        if view_context.respond_to?(localized_helper_name)
          return view_context.public_send(localized_helper_name, **localized_params)
        end

        raise ActionController::UrlGenerationError, "Missing helper: #{generic_helper_name}" unless view_context.respond_to?(generic_helper_name)

        I18n.with_locale(locale) do
          view_context.public_send(generic_helper_name, **localized_params.merge(locale: locale))
        end
      rescue ActionController::UrlGenerationError
        root_path(locale: locale)
      end

      def studio_request?(request)
        request.path.start_with?("/studio") || request.host.start_with?("studio.")
      end

      def studio_locale_href(locale)
        request = view_context.request
        query_params = request.query_parameters.symbolize_keys.except(:locale).merge(locale: locale)
        query_string = query_params.to_query

        query_string.present? ? "#{request.path}?#{query_string}" : "#{request.path}?locale=#{locale}"
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
