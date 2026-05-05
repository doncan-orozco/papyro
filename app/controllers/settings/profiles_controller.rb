# frozen_string_literal: true

module Settings
  class ProfilesController < Settings::BaseController
    def edit
      render Views::Settings::Profiles::Edit.new(user: Current.user)
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
        render Views::Settings::Profiles::Edit.new(user: user), status: :unprocessable_entity
      end
    end

    private

    def profile_params
      params.require(:user).permit(:email_address, profile_attributes: [ :display_name ]).to_h
    end
  end
end
