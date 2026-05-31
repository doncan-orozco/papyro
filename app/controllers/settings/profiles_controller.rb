# frozen_string_literal: true

module Settings
  class ProfilesController < Settings::BaseController
    def edit
      render_edit_view(user: Current.user)
    end

    def update
      result = Users::Operation::UpdateProfile.new.call(
        user: Current.user,
        params: profile_params,
        locale: selected_bio_locale
      )

      if result.success?
        redirect_to edit_settings_profile_path(locale_query), notice: t("users.operations.update_profile.success")
      else
        user = result.failure[:model] || Current.user
        render_edit_view(user: user, status: :unprocessable_entity)
      end
    end

    private

    def profile_params
      params.require(:user).permit(
        profile_attributes: [
          :display_name, :username, :bio, :bio_locale, :location, :portrait,
          :website_url, :x_handle, :linkedin_handle
        ]
      ).to_h
    end

    def selected_bio_locale
      requested = params[:content_locale].presence || params.dig(:user, :profile_attributes, :bio_locale).presence || I18n.locale.to_s
      available_locales = I18n.available_locales.map(&:to_s)
      return requested if available_locales.include?(requested)

      I18n.default_locale.to_s
    end

    def locale_query
      return {} if selected_bio_locale == I18n.default_locale.to_s

      { content_locale: selected_bio_locale }
    end

    def render_edit_view(user:, status: :ok)
      view = Views::Settings::Profiles::Edit.new(
        user: user,
        author_profile_path: author_profile_path_for(user),
        selected_bio_locale: selected_bio_locale
      )

      Mobility.with_locale(selected_bio_locale) do
        render view, status: status
      end
    end

    def author_profile_path_for(user)
      return root_path unless user.profile&.username.present?

      author_path(user.profile.username)
    end
  end
end
