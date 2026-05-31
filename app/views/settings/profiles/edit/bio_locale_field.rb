# frozen_string_literal: true

module Views
  module Settings
    module Profiles
      class Edit::BioLocaleField < Views::Base
        include Phlex::Rails::Helpers::HiddenFieldTag

        def initialize(profile_form:, selected_locale:)
          @profile_form = profile_form
          @selected_locale = normalized_locale(selected_locale)
        end

        def view_template
          div(
            class: "space-y-2",
            data: {
              controller: "settings--profiles--bio-locale",
              "settings--profiles--bio-locale-active-locale-value": @selected_locale
            }
          ) do
            render_header
            render_bio_field
            hidden_field_tag(
              "user[profile_attributes][bio_locale]",
              @selected_locale,
              data: { "settings--profiles--bio-locale-target": "localeInput" }
            )
          end
        end

        private

        attr_reader :profile_form

        def render_header
          div(class: "flex items-center justify-between gap-3") do
            render Components::Ui::Label.new(for: bio_input_id) { t("users.settings.profile.bio_label") }

            div(class: "inline-flex items-center rounded-md border border-border p-0.5", role: "tablist", aria: { label: t("users.settings.profile.bio_locale_label") }) do
              available_locales.each do |locale|
                button(
                  id: bio_tab_id(locale),
                  type: "button",
                  class: locale_button_class(locale),
                  role: "tab",
                  aria: {
                    selected: locale == @selected_locale
                  },
                  data: {
                    locale: locale,
                    action: "settings--profiles--bio-locale#switch",
                    "settings--profiles--bio-locale-target": "button"
                  }
                ) do
                  t("language.name", locale: locale)
                end
              end
            end
          end

          p(class: "text-sm text-foreground/80") { t("users.settings.profile.bio_locale_hint") }
        end

        def render_bio_field
          profile_form.label(:bio, t("users.settings.profile.bio_label"), class: "sr-only")
          profile_form.text_area(
            :bio,
            id: bio_input_id,
            rows: 3,
            placeholder: t("users.settings.profile.bio_placeholder"),
            class: "flex min-h-[60px] w-full rounded-md border border-input bg-transparent px-3 py-2 text-base shadow-sm transition-colors placeholder:text-muted-foreground focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-ring disabled:cursor-not-allowed disabled:opacity-50 aria-invalid:ring-3 aria-invalid:ring-destructive/20 dark:aria-invalid:ring-destructive/40 aria-invalid:border-destructive dark:aria-invalid:border-destructive/50"
          )
          profile_form.field_errors(:bio)
        end

        def locale_button_class(locale)
          base = "inline-flex items-center justify-center whitespace-nowrap rounded-sm px-2.5 py-1 text-xs font-medium transition-colors focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-ring"
          state = locale == @selected_locale ? "bg-foreground text-background" : "text-foreground/70 hover:text-foreground"
          [ base, state ].join(" ")
        end

        def bio_input_id
          "user_profile_attributes_bio"
        end

        def bio_tab_id(locale)
          "profile-bio-tab-#{locale}"
        end

        def available_locales
          I18n.available_locales.map(&:to_s)
        end

        def normalized_locale(locale)
          locale_str = locale.to_s
          available_locales.include?(locale_str) ? locale_str : I18n.default_locale.to_s
        end
      end
    end
  end
end
