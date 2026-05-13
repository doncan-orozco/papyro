class PasswordsController < ApplicationController
  allow_unauthenticated_access
  before_action :skip_authorization
  before_action :set_user_by_token, only: %i[ edit update ]
  rate_limit to: 10, within: 3.minutes, only: :create, with: -> { redirect_to new_password_path, alert: t("passwords.create.rate_limit") }

  def new
    render Views::Passwords::New.new(user: User.new)
  end

  def create
    result = Users::Operation::PasswordResetRequest.new.call(params: password_reset_request_params)

    unless result.success?
      return render Views::Passwords::New.new(user: result.failure[:model] || User.new), status: :unprocessable_entity
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

    def password_reset_request_params
      params.fetch(:user, params).permit(:email_address).to_h
    end

    def password_update_params
      params.fetch(:user, params).permit(:password, :password_confirmation).to_h
    end
end
