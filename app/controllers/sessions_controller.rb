class SessionsController < ApplicationController
  allow_unauthenticated_access only: %i[ new create ]
  before_action :skip_authorization
  rate_limit to: 10, within: 3.minutes, only: :create, with: -> { redirect_to new_session_path, alert: t("sessions.create.rate_limit") }

  def new
    render Views::Sessions::New.new(user: login_user)
  end

  def create
    user = login_user
    normalized_params = normalize_login_params(login_params)
    contract_result = Users::Contract::Login.new.call(normalized_params)

    if contract_result.failure?
      inject_errors!(user, contract_result.errors.to_h)
      return render Views::Sessions::New.new(user: user), status: :unprocessable_entity
    end

    if authenticated_user = User.authenticate_by(email_address: normalized_params[:email_address], password: normalized_params[:password])
      start_new_session_for authenticated_user
      redirect_to after_authentication_url
    else
      flash[:alert] = t("sessions.create.invalid_credentials")
      redirect_to new_session_path, status: :see_other
    end
  end

  def destroy
    terminate_session
    redirect_to new_session_path, status: :see_other
  end

  private

  def login_user
    @login_user ||= User.new
  end

  def login_params
    params.fetch(:user, params).permit(:email_address, :password).to_h
  end

  def normalize_login_params(params)
    params.merge(email_address: params[:email_address].to_s.strip.downcase)
  end

  def inject_errors!(model, errors_hash)
    errors_hash.each do |field, messages|
      Array(messages).each { |message| model.errors.add(field, message) }
    end
    model
  end
end
