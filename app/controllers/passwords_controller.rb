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
    result = Users::Operation::Update.call(
      params: params.permit(:password, :password_confirmation).to_h,
      user: @user
    )

    if result.success?
      @user.sessions.destroy_all
      redirect_to new_session_path, notice: t("passwords.update.success")
    else
      flash.now[:alert] = format_validation_errors(result[:errors])
      render Views::Passwords::Edit.new(token: params[:token]), status: :unprocessable_entity
    end
  end

  private
    def set_user_by_token
      @user = User.find_by_password_reset_token!(params[:token])
    rescue ActiveSupport::MessageVerifier::InvalidSignature
      redirect_to new_password_path, alert: t("passwords.update.invalid_token")
    end

    def format_validation_errors(errors)
      errors.map { |field, messages| "#{field.to_s.humanize}: #{messages.join(', ')}" }.join("; ")
    end
end
