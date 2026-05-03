class PasswordsController < ApplicationController
  allow_unauthenticated_access
  before_action :skip_authorization
  before_action :set_user_by_token, only: %i[ edit update ]
  rate_limit to: 10, within: 3.minutes, only: :create, with: -> { redirect_to new_password_path, alert: t("passwords.create.rate_limit") }

  def new
    render Views::Passwords::New.new(user: password_reset_user)
  end

  def create
    user = password_reset_user
    normalized_params = normalize_password_reset_request_params(password_reset_request_params)
    contract_result = Users::Contract::PasswordResetRequest.new.call(normalized_params)

    if contract_result.failure?
      inject_errors!(user, contract_result.errors.to_h)
      return render Views::Passwords::New.new(user: user), status: :unprocessable_entity
    end

    if found_user = User.find_by(email_address: normalized_params[:email_address])
      PasswordsMailer.reset(found_user).deliver_later
    end

    redirect_to new_session_path, notice: t("passwords.create.instructions_sent")
  end

  def edit
    render Views::Passwords::Edit.new(token: params[:token], user: @user)
  end

  def update
    result = Users::Operation::Update.new.call(
      params: password_update_params,
      user: @user
    )

    if result.success?
      @user.sessions.destroy_all
      redirect_to new_session_path, notice: t("passwords.update.success")
    else
      model = result.failure[:model] || @user
      render Views::Passwords::Edit.new(token: params[:token], user: model), status: :unprocessable_entity
    end
  end

  private

    def set_user_by_token
      @user = User.find_by_token_for!(:password_reset, params[:token])
    rescue ActiveSupport::MessageVerifier::InvalidSignature
      redirect_to new_password_path, alert: t("passwords.update.invalid_token")
    end

    def password_reset_user
      @password_reset_user ||= User.new
    end

    def password_reset_request_params
      params.fetch(:user, params).permit(:email_address).to_h
    end

    def normalize_password_reset_request_params(params)
      params.merge(email_address: params[:email_address].to_s.strip.downcase)
    end

    def password_update_params
      params.fetch(:user, params).permit(:password, :password_confirmation).to_h
    end

    def inject_errors!(model, errors_hash)
      errors_hash.each do |field, messages|
        Array(messages).each { |message| model.errors.add(field, message) }
      end
      model
    end
end
