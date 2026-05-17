# frozen_string_literal: true

module Settings
  class SecurityController < Settings::BaseController
    def edit
      render Views::Settings::Security::Edit.new(user: Current.user)
    end

    def update
      result = Users::Operation::UpdatePassword.new.call(
        user: Current.user,
        params: security_params
      )

      if result.success?
        redirect_to edit_settings_security_path, notice: t("users.operations.update_password.success")
      else
        user = result.failure[:model] || Current.user
        render Views::Settings::Security::Edit.new(user: user), status: :unprocessable_entity
      end
    end

    private

    def security_params
      params.require(:user).permit(:current_password, :password, :password_confirmation).to_h
    end
  end
end
