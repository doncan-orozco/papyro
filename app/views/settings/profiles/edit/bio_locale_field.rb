# frozen_string_literal: true

module Views
  module Settings
    module Profiles
      class Edit::BioLocaleField < Views::Base
        TEXTAREA_CLASS = "flex min-h-[60px] w-full rounded-md border border-input bg-transparent px-3 py-2 text-base shadow-sm transition-colors placeholder:text-muted-foreground focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-ring disabled:cursor-not-allowed disabled:opacity-50 aria-invalid:ring-3 aria-invalid:ring-destructive/20 dark:aria-invalid:ring-destructive/40 aria-invalid:border-destructive dark:aria-invalid:border-destructive/50"
        TAB_BUTTON_CLASS = "inline-flex items-center justify-center whitespace-nowrap rounded-sm px-2.5 py-1 text-xs font-medium transition-colors focus-visible:outline-none focus-visible:ring-1 focus-visible:ring-ring"

        def initialize(profile_form:)
          @profile_form = profile_form
        end

        def view_template
          div(
            class: "space-y-4",
            data: {
              controller: "settings--profiles--bio-locale-tabs",
              "settings--profiles--bio-locale-tabs-active-locale-value": active_locale
            }
          ) do
            div(class: "space-y-1") do
              div(class: "flex items-center justify-between gap-3") do
                render Components::Ui::Label.new { t("users.settings.profile.bio_label") }

                div(
                  class: "inline-flex items-center rounded-md border border-border p-0.5",
                  role: "tablist",
                  aria: { label: t("users.settings.profile.bio_locale_label") }
                ) do
                  available_locales.each do |locale|
                    button(
                      type: "button",
                      id: tab_id(locale),
                      class: tab_button_class(locale),
                      role: "tab",
                      aria: {
                        selected: (locale == active_locale).to_s,
                        controls: panel_id(locale)
                      },
                      data: {
                        locale: locale,
                        action: "settings--profiles--bio-locale-tabs#switch",
                        "settings--profiles--bio-locale-tabs-target": "button"
                      }
                    ) { t("language.name", locale: locale) }
                  end
                end
              end

              p(class: "text-sm text-foreground/80") { t("users.settings.profile.bio_locale_hint") }
            end

            available_locales.each_with_index do |locale, index|
              translation = find_or_build_translation(locale)
              base_name = "user[profile_attributes][translations_attributes][#{index}]"

              div(
                class: "space-y-1",
                id: panel_id(locale),
                role: "tabpanel",
                aria: { labelledby: tab_id(locale) },
                hidden: locale == active_locale ? nil : true,
                data: {
                  locale: locale,
                  "settings--profiles--bio-locale-tabs-target": "panel"
                }
              ) do
                render Components::Ui::Label.new(for: bio_input_id(index)) do
                  t("language.name", locale: locale)
                end
                input(type: "hidden", name: "#{base_name}[id]", value: translation.id)
                input(type: "hidden", name: "#{base_name}[locale]", value: locale)
                textarea(
                  id: bio_input_id(index),
                  name: "#{base_name}[bio]",
                  rows: 3,
                  placeholder: t("users.settings.profile.bio_placeholder"),
                  class: TEXTAREA_CLASS
                ) { translation.bio.to_s }
              end
            end
          end
        end

        private

        attr_reader :profile_form

        def available_locales
          I18n.available_locales.map(&:to_s)
        end

        def active_locale
          current_locale = I18n.locale.to_s
          available_locales.include?(current_locale) ? current_locale : I18n.default_locale.to_s
        end

        def find_or_build_translation(locale)
          profile = profile_form.object
          profile.translations.find { |t| t.locale == locale } ||
            profile.translations.build(locale: locale)
        end

        def tab_button_class(locale)
          state = locale == active_locale ? "bg-foreground text-background" : "text-foreground/70 hover:text-foreground"
          [ TAB_BUTTON_CLASS, state ].join(" ")
        end

        def tab_id(locale)
          "profile-bio-tab-#{locale}"
        end

        def panel_id(locale)
          "profile-bio-panel-#{locale}"
        end

        def bio_input_id(index)
          "user_profile_attributes_translations_attributes_#{index}_bio"
        end
      end
    end
  end
end
