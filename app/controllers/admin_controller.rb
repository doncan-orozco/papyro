# Base controller for admin panel requiring authentication
class AdminController < ApplicationController
  include Authentication

  before_action :require_authentication
  before_action :require_admin_role

  layout "admin"

  private

  def require_admin_role
    # For MVP: all authenticated users are admins
    # Later: add role column to users table
    unless Current.user
      redirect_to admin_login_path, alert: t("admin.errors.unauthorized")
    end
  end

  def after_authentication_url
    admin_root_path
  end
end
