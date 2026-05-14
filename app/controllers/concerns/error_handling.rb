module ErrorHandling
  extend ActiveSupport::Concern

  included do
    rescue_from Pundit::NotAuthorizedError, with: :handle_not_authorized
    rescue_from ActiveRecord::RecordNotFound, with: :handle_not_found
  end

  private

  def handle_not_authorized
    redirect_to(request.referrer || root_path, alert: t("admin.errors.unauthorized"))
  end

  def handle_not_found(exception = nil)
    skip_authorization unless pundit_policy_authorized?
    skip_policy_scope unless pundit_policy_scoped?

    if exception&.model == "Article" || (params[:controller] == "articles" && params[:action] == "show")
      author = nil
      if params[:slug].present?
        author = Users::Query::AuthorByArticleSlug.call({ slug: params[:slug] }).first
      end
      render Views::Articles::NotFound.new(author: author), status: :not_found
    else
      render file: Rails.root.join("public/404.html"), status: :not_found, layout: false
    end
  end
end
