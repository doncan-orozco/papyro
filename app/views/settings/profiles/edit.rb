# frozen_string_literal: true

module Views
  module Settings
    module Profiles
      class Edit < Views::Base
        include Phlex::Rails::Helpers::FormWith

        def initialize(user:)
          @user = user
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
                  form.fields_for :profile_attributes, profile_for_form do |profile_form|
                    profile_form.field :display_name,
                      as: :text_field,
                      label: t("users.settings.profile.display_name_label"),
                      options: {
                        required: true,
                        autocomplete: "name",
                        placeholder: t("users.settings.profile.display_name_placeholder")
                      }
                  end

                  form.field :email_address,
                    as: :email_field,
                    label: t("users.settings.profile.email_label"),
                    options: {
                      required: true,
                      autocomplete: "email",
                      placeholder: t("users.settings.profile.email_placeholder")
                    }

                  div(class: "flex flex-wrap gap-3") do
                    form.submit t("users.settings.profile.submit")
                    link_to t("users.settings.profile.cancel"),
                      user_path(@user),
                      class: "inline-flex items-center justify-center whitespace-nowrap rounded-md text-sm font-medium ring-offset-background transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 disabled:pointer-events-none disabled:opacity-50 h-10 px-4 py-2 border border-input bg-background hover:bg-muted"
                  end
                end
              end
            end
          end
        end

        private

        def profile_for_form
          @profile_for_form ||= @user.profile || @user.build_profile
        end
      end
    end
  end
end
