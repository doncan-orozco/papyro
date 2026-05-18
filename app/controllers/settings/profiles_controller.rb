# frozen_string_literal: true

module Settings
  class ProfilesController < Settings::BaseController
    def edit
      render Views::Settings::Profiles::Edit.new(
        user: Current.user,
        author_profile_path: author_profile_path_for(Current.user)
      )
    end

    def update
      result = Users::Operation::UpdateProfile.new.call(
        user: Current.user,
        params: profile_params
      )

      if result.success?
        redirect_to edit_settings_profile_path, notice: t("users.operations.update_profile.success")
      else
        user = result.failure[:model] || Current.user
        render Views::Settings::Profiles::Edit.new(
          user: user,
          author_profile_path: author_profile_path_for(user)
        ), status: :unprocessable_entity
      end
    end

    private

    def profile_params
      params.require(:user).permit(
        profile_attributes: [
          :display_name, :username, :bio, :location, :portrait,
          :website_url, :x_handle, :linkedin_handle
        ]
      ).to_h
    end

    def author_profile_path_for(user)
      return root_path unless user.profile&.username.present?

      author_path(user.profile.username)
    end
  end
end
