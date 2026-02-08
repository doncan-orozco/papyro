# Admin authentication controller
# Inspired by Writebook's session management but adapted to Papyro patterns
module Admin
  class SessionsController < ApplicationController
    allow_unauthenticated_access only: [:new, :create]
    rate_limit to: 10, within: 3.minutes, only: :create,
               with: -> { render_rejection :too_many_requests }

    layout "admin"

    def new
      # Render admin login form
    end

    def create
      if user = User.authenticate_by(params.permit(:email_address, :password))
        start_new_session_for user
        redirect_to admin_root_path, notice: t(".success")
      else
        render_rejection :unauthorized
      end
    end

    def destroy
      terminate_session
      redirect_to admin_login_path, notice: t(".signed_out")
    end

    private

    def render_rejection(status)
      flash.now[:alert] = t(".#{status}")
      render :new, status: status
    end
  end
end
