# Admin authentication controller
# Inspired by Writebook's session management but adapted to Papyro patterns
module Admin
  class SessionsController < ApplicationController
    allow_unauthenticated_access only: [ :new, :create ]
    rate_limit to: 10, within: 3.minutes, only: :create,
               with: -> { render_rejection :too_many_requests }

    layout "admin"

    def new
      render Views::Admin::Sessions::New.new(form: login_form)
    end

    def create
      @form = login_form

      if @form.validate(login_params)
        if user = User.authenticate_by(email_address: @form.email_address, password: @form.password)
          start_new_session_for user
          redirect_to admin_root_path, notice: t(".success")
        else
          render_rejection :unauthorized, form: @form
        end
      else
        render Views::Admin::Sessions::New.new(form: @form), status: :unprocessable_entity
      end
    end

    def destroy
      terminate_session
      redirect_to admin_login_path, notice: t(".signed_out")
    end

    private

    def render_rejection(status, form: login_form)
      flash.now[:alert] = t(".#{status}")
      render Views::Admin::Sessions::New.new(form: form), status: status
    end

    def login_form
      Users::Form::Login.new(User.new)
    end

    def login_params
      params_key = login_form.model_name.param_key
      params.fetch(params_key, params).permit(:email_address, :password).to_h
    end
  end
end
