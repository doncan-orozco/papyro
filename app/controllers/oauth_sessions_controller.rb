class OauthSessionsController < ApplicationController
  allow_unauthenticated_access only: :create
  before_action :skip_authorization

  def create
    auth = request.env["omniauth.auth"]
    return redirect_to(new_session_path, alert: t("sessions.create.invalid_credentials"), status: :see_other) if auth.blank?

    user = User.from_omniauth(auth)
    start_new_session_for(user)
    redirect_to after_authentication_url
  rescue ActiveRecord::RecordInvalid, ArgumentError
    redirect_to new_session_path, alert: t("sessions.create.invalid_credentials"), status: :see_other
  end
end
