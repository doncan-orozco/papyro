class SessionsController < ApplicationController
  allow_unauthenticated_access only: %i[ new create ]
  before_action :skip_authorization
  rate_limit to: 10, within: 3.minutes, only: :create, with: -> { redirect_to new_session_path, alert: t("sessions.create.rate_limit") }

  def new
    render Views::Sessions::New.new(user: User.new)
  end

  def create
    result = Users::Operation::Login.new.call(params: login_params)

    if result.success?
      start_new_session_for result.value![:model]
      redirect_to after_authentication_url
    else
      return redirect_to new_session_path, alert: result.failure[:message], status: :see_other if result.failure[:code] == :invalid_credentials

      render Views::Sessions::New.new(user: result.failure[:model] || User.new), status: :unprocessable_entity
    end
  end

  def destroy
    terminate_session
    redirect_to new_session_path, status: :see_other
  end

  private

  def login_params
    params.fetch(:user, params).permit(:email_address, :password).to_h
  end
end
