class PasswordsController < ApplicationController
  allow_unauthenticated_access
  before_action :set_user_by_token, only: %i[ edit update ]
  rate_limit to: 10, within: 3.minutes, only: :create, with: -> { redirect_to new_password_path, alert: t("passwords.create.rate_limit") }

  def new
    render Views::Passwords::New.new(form: password_reset_request_form)
  end

  def create
    @form = password_reset_request_form

    if @form.validate(password_reset_request_params)
      if user = User.find_by(email_address: @form.email_address)
        PasswordsMailer.reset(user).deliver_later
      end

      redirect_to new_session_path, notice: t("passwords.create.instructions_sent")
    else
      render Views::Passwords::New.new(form: @form), status: :unprocessable_entity
    end
  end

  def edit
    render Views::Passwords::Edit.new(token: params[:token], form: password_update_form)
  end

  def update
    result = Users::Operation::Update.call(
      params: password_update_params,
      user: @user
    )

    if result.success?
      @user.sessions.destroy_all
      redirect_to new_session_path, notice: t("passwords.update.success")
    else
      form = result[:form] || password_update_form
      render Views::Passwords::Edit.new(token: params[:token], form: form), status: :unprocessable_entity
    end
  end

  private
    def set_user_by_token
      @user = User.find_by_token_for!(:password_reset, params[:token])
    rescue ActiveSupport::MessageVerifier::InvalidSignature
      redirect_to new_password_path, alert: t("passwords.update.invalid_token")
    end

    def password_reset_request_form
      Users::Form::PasswordResetRequest.new(User.new)
    end

    def password_update_form
      Users::Form::Update.new(@user)
    end

    def password_reset_request_params
      params_key = password_reset_request_form.model_name.param_key
      params.fetch(params_key, params).permit(:email_address).to_h
    end

    def password_update_params
      params_key = password_update_form.model_name.param_key
      params.fetch(params_key, params).permit(:password, :password_confirmation).to_h
    end
end
