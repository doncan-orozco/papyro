class PasswordsController < ApplicationController
  allow_unauthenticated_access
  before_action :set_user_by_token, only: %i[ edit update ]
  rate_limit to: 10, within: 3.minutes, only: :create, with: -> { redirect_to new_password_path, alert: t("passwords.create.rate_limit") }

  def new
    render Views::Passwords::New.new
  end

  def create
    email = params[:email_address].to_s.strip.downcase

    if user = User.find_by(email_address: email)
      PasswordsMailer.reset(user).deliver_later
    end

    redirect_to new_session_path, notice: t("passwords.create.instructions_sent")
  end

  def edit
    render Views::Passwords::Edit.new(token: params[:token])
  end

  def update
    if @user.update(params.permit(:password, :password_confirmation))
      @user.sessions.destroy_all
      redirect_to new_session_path, notice: t("passwords.update.success")
    else
      redirect_to edit_password_path(params[:token]), alert: t("passwords.update.mismatch")
    end
  end

  private
    def set_user_by_token
      @user = User.find_by_password_reset_token!(params[:token])
    rescue ActiveSupport::MessageVerifier::InvalidSignature
      redirect_to new_password_path, alert: t("passwords.update.invalid_token")
    end
end
