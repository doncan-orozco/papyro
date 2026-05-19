class EmailVerificationsController < ApplicationController
  allow_unauthenticated_access only: :show
  before_action :skip_authorization

  def show
    user = User.find_by_token_for(:email_verification, params[:token])

    if user.blank?
      redirect_to new_session_path, alert: t("users.email_verification.invalid_or_expired")
      return
    end

    user.update!(verified_at: Time.current) unless user.verified?
    start_new_session_for(user) unless authenticated?

    redirect_to after_authentication_url, notice: t("users.email_verification.verified")
  rescue ActiveSupport::MessageVerifier::InvalidSignature
    redirect_to new_session_path, alert: t("users.email_verification.invalid_or_expired")
  end
end
