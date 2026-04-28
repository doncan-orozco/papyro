class SessionsController < ApplicationController
  allow_unauthenticated_access only: %i[ new create ]
  before_action :skip_authorization
  rate_limit to: 10, within: 3.minutes, only: :create, with: -> { redirect_to new_session_path, alert: t("sessions.create.rate_limit") }

  def new
    render Views::Sessions::New.new(form: login_form)
  end

  def create
    @form = login_form

    if @form.validate(login_params)
      if user = User.authenticate_by(email_address: @form.email_address, password: @form.password)
        start_new_session_for user
        redirect_to after_authentication_url
      else
        flash[:alert] = t("sessions.create.invalid_credentials")
        redirect_to new_session_path, status: :see_other
      end
    else
      render Views::Sessions::New.new(form: @form), status: :unprocessable_entity
    end
  end

  def destroy
    terminate_session
    redirect_to new_session_path, status: :see_other
  end

  private

  def login_form
    Users::Form::Login.new(User.new)
  end

  def login_params
    params_key = login_form.model_name.param_key
    params.fetch(params_key, params).permit(:email_address, :password).to_h
  end
end
