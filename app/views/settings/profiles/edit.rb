# frozen_string_literal: true

module Views
  module Settings
    module Profiles
      class Edit < Views::Base
        include Phlex::Rails::Helpers::FormWith
        include Phlex::Rails::Helpers::ImageTag

        def initialize(user:, author_profile_path:)
          @user = user
          @author_profile_path = author_profile_path
        end

        def view_template
          render Views::Settings::Layout.new(active: :profile) do
            render Components::Ui::Card.new do |card|
              card.header do
                card.title { t("users.settings.profile.title") }
                card.description { t("users.settings.profile.description") }
              end

              card.content do
                form_with(model: @user, url: settings_profile_path, method: :patch, class: "space-y-5") do |form|
                  div(class: "grid grid-cols-1 gap-8 md:grid-cols-4 md:items-start") do
                    form.fields_for :profile_attributes, profile_for_form do |profile_form|
                      div(
                        class: "space-y-2 md:col-span-1",
                        "data-controller": "settings--profiles--portrait-preview",
                        "data-settings--profiles--portrait-preview-alt-value": t("users.settings.profile.portrait_label"),
                        "data-settings--profiles--portrait-preview-image-class-value": "h-full w-full object-cover grayscale transition-transform duration-700 group-hover:scale-105"
                      ) do
                        label(
                          for: portrait_input_id,
                          class: "group relative flex aspect-[3/4] w-full cursor-pointer flex-col items-center justify-center overflow-hidden border border-border/60 bg-muted/40 transition-colors hover:border-border"
                        ) do
                          span(class: "sr-only") { t("users.settings.profile.portrait_label") }

                          div("data-settings--profiles--portrait-preview-target": "canvas") do
                            if profile_for_form.portrait.attached?
                              image_tag(
                                profile_for_form.portrait,
                                alt: t("users.settings.profile.portrait_label"),
                                class: "h-full w-full object-cover grayscale transition-transform duration-700 group-hover:scale-105"
                              )
                            else
                              div(class: "relative flex h-full w-full items-center justify-center bg-gradient-to-br from-muted/55 via-muted/35 to-muted/70") do
                                span(class: "pointer-events-none text-6xl font-black uppercase tracking-tight text-foreground/20 sm:text-7xl") do
                                  avatar_initial
                                end
                              end
                            end
                          end

                          div(class: "absolute inset-0 flex flex-col items-center justify-center bg-black/35 opacity-100 transition-opacity duration-300 md:bg-black/55 md:opacity-0 md:group-hover:opacity-100") do
                            render Components::Ui::Icon.new(:camera, size: 24, class: "mb-2 text-white")
                            span(class: "text-[11px] font-bold uppercase tracking-[0.18em] text-white") do
                              t("users.settings.profile.portrait_change_cta")
                            end
                          end

                          profile_form.file_field :portrait,
                            id: portrait_input_id,
                            accept: "image/png,image/jpeg,image/webp",
                            class: "sr-only",
                            "data-settings--profiles--portrait-preview-target": "input",
                            "data-action": "change->settings--profiles--portrait-preview#preview"
                        end

                        p(class: "text-xs text-muted-foreground") { t("users.settings.profile.portrait_hint") }
                        profile_form.field_errors(:portrait)
                      end

                      div(class: "space-y-6 md:col-span-3") do
                        profile_form.field :display_name,
                          as: :text_field,
                          label: t("users.settings.profile.display_name_label"),
                          options: {
                            required: true,
                            autocomplete: "name",
                            placeholder: t("users.settings.profile.display_name_placeholder")
                          }

                        profile_form.field :username,
                          as: :text_field,
                          label: t("users.settings.profile.username_label"),
                          options: {
                            placeholder: t("users.settings.profile.username_placeholder"),
                            disabled: true,
                            hint: t("users.settings.profile.username_locked_hint")
                          }

                        profile_form.field :bio,
                          as: :text_area,
                          label: t("users.settings.profile.bio_label"),
                          options: {
                            placeholder: t("users.settings.profile.bio_placeholder"),
                            rows: 3
                          }

                        profile_form.field :location,
                          as: :text_field,
                          label: t("users.settings.profile.location_label"),
                          options: {
                            placeholder: t("users.settings.profile.location_placeholder"),
                            autocomplete: "address-level2"
                          }

                        profile_form.field :website_url,
                          as: :url_field,
                          label: t("users.settings.profile.website_url_label"),
                          options: {
                            placeholder: t("users.settings.profile.website_url_placeholder"),
                            autocomplete: "url"
                          }

                        profile_form.field :x_handle,
                          as: :text_field,
                          label: t("users.settings.profile.x_handle_label"),
                          options: {
                            placeholder: t("users.settings.profile.x_handle_placeholder")
                          }

                        profile_form.field :linkedin_handle,
                          as: :text_field,
                          label: t("users.settings.profile.linkedin_handle_label"),
                          options: {
                            placeholder: t("users.settings.profile.linkedin_handle_placeholder")
                          }

                        form.field :email_address,
                          as: :email_field,
                          label: t("users.settings.profile.email_label"),
                          options: {
                            required: true,
                            autocomplete: "email",
                            placeholder: t("users.settings.profile.email_placeholder")
                          }

                        div(class: "flex flex-wrap items-center justify-end gap-3 pt-1") do
                          link_to t("users.settings.profile.cancel"),
                            author_profile_path,
                            class: "inline-flex h-10 items-center justify-center whitespace-nowrap rounded-md border border-input bg-background px-4 py-2 text-sm font-medium ring-offset-background transition-colors hover:bg-muted focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 disabled:pointer-events-none disabled:opacity-50"
                          form.submit t("users.settings.profile.submit"),
                            class: "inline-flex h-10 items-center justify-center whitespace-nowrap rounded-md bg-black px-4 py-2 text-sm font-semibold text-white shadow-sm transition-colors hover:bg-rose-600 hover:text-white focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2"
                        end
                      end
                    end
                  end
                end
              end
            end
          end
        end

        private

        attr_reader :author_profile_path

        def profile_for_form
          @profile_for_form ||= @user.profile || @user.build_profile
        end

        def portrait_input_id
          "user_profile_attributes_portrait"
        end

        def avatar_initial
          profile_for_form.display_name.to_s.strip[0]&.upcase || "U"
        end
      end
    end
  end
end
