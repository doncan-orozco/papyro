# Base controller for admin panel requiring authentication
class AdminController < ApplicationController
  before_action :require_admin_role

  layout "admin"

  private

  def require_admin_role
    # For MVP: all authenticated users are admins
    # Later: add role column to users table
    unless Current.user&.admin?
      redirect_to main_app.admin_login_path, alert: t("admin.errors.unauthorized")
    end
  end

  def authentication_redirect_path
    main_app.admin_login_path
  end

  def after_authentication_url
    main_app.admin_root_path
  end
end
