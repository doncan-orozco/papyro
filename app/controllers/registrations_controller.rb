class RegistrationsController < ApplicationController
  allow_unauthenticated_access only: %i[ new create ]
  before_action :skip_authorization
  rate_limit to: 10, within: 3.minutes, only: :create, with: -> { redirect_to sign_up_path, alert: t("registrations.create.rate_limit") }

  def new
    render Views::Registrations::New.new(user: User.new)
  end

  def create
    result = Users::Operation::Register.new.call(params: registration_params)

    if result.success?
      user = result.value![:model]
      start_new_session_for user
      EmailVerificationsMailer.verify(user).deliver_later
      redirect_to after_authentication_url, notice: t("registrations.create.success")
    else
      render Views::Registrations::New.new(user: result.failure[:model] || User.new), status: :unprocessable_entity
    end
  end

  private

  def registration_params
    params.fetch(:user, params).permit(:email_address, :password).to_h
  end
end
