class ApplicationController < ActionController::Base
  include Authentication
  include LocaleManagement
  include Pundit::Authorization
  include Pagy::Method
  include ErrorHandling

  allow_browser versions: :modern
  stale_when_importmap_changes

  before_action :require_qa_auth, if: -> { ENV["APP_ENV"] == "qa" }

  after_action :verify_pundit_authorization

  private

  def verify_pundit_authorization
    action_name == "index" ? verify_policy_scoped : verify_authorized
  end

  def pundit_user
    Current.user
  end

  def parse_page(page_param = params[:page])
    [ page_param.to_i, 1 ].max
  end

  def require_qa_auth
    authenticate_or_request_with_http_basic("QA Environment") do |username, password|
      username == "admin" && password == ENV["QA_PASSWORD"]
    end
  end
end
