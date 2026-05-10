class ApplicationController < ActionController::Base
  include Authentication
  include LocaleManagement
  include Pundit::Authorization
  include Pagy::Method
  after_action :verify_pundit_authorization

  rescue_from Pundit::NotAuthorizedError, with: :handle_not_authorized
  rescue_from ActiveRecord::RecordNotFound, with: :handle_not_found

  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
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

  def handle_not_authorized
    redirect_to(request.referrer || root_path, alert: t("admin.errors.unauthorized"))
  end

  def handle_not_found(exception = nil)
    skip_authorization unless pundit_policy_authorized?
    skip_policy_scope unless pundit_policy_scoped?

    # Premium 404 for missing/unpublished articles
    if exception&.model == "Article" || (params[:controller] == "articles" && params[:action] == "show")
      # Try to find the author for a better not-found page
      author = nil
      if params[:slug].present?
        author = User.joins(:articles).find_by(articles: { slug: params[:slug] })
      end
      render Views::Articles::NotFound.new(author: author), status: :not_found
    else
      render file: Rails.root.join("public/404.html"), status: :not_found, layout: false
    end
  end

  def parse_page(page_param = params[:page])
    page = page_param.to_i
    page.positive? ? page : 1
  end
end
