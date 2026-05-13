class ApplicationController < ActionController::Base
  include Authentication
  include LocaleManagement
  include Pundit::Authorization
  include Pagy::Method
  include ErrorHandling
  after_action :verify_pundit_authorization

  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  private

  def verify_pundit_authorization
    if action_name == "index"
      verify_policy_scoped
    else
      verify_authorized
    end
  end

  def pundit_user
    Current.user
  end

  def parse_page(page_param = params[:page])
    page = page_param.to_i
    page.positive? ? page : 1
  end
end
