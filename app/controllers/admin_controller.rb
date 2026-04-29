# Base controller for admin panel requiring authentication
class AdminController < ApplicationController
  before_action :require_admin_role

  # MissionControl::Jobs (mounted at /jobs) uses this as its base controller.
  # Those controllers do not call policy_scope / authorize, so skip Pundit's
  # after-action verification to avoid PolicyScopingNotPerformedError.
  skip_after_action :verify_pundit_authorization

  layout "admin"

  private

  def require_admin_role
    # For MVP: all authenticated users are admins
    # Later: add role column to users table
    unless Current.user&.admin?
      redirect_to admin_login_path, alert: t("admin.errors.unauthorized")
    end
  end

  def authentication_redirect_path
    admin_login_path
  end

  def after_authentication_url
    admin_root_path
  end

  # Fall back to the standard session / root paths until dedicated admin routes
  # are added to config/routes.rb.
  def admin_login_path
    main_app.new_session_path
  end

  def admin_root_path
    main_app.root_path
  end
end
