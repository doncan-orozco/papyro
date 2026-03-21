# frozen_string_literal: true

class Admin::ArticlesController < AdminController
  def index
    articles = Articles::AdminIndexQuery.call(user: Current.user)
    render Views::Admin::Articles::Index.new(articles)
  end

  def new
    @article = Article.new
    render Views::Admin::Articles::New.new(@article)
  end

  def create
    result = Articles::Operation::Create.call(
      params: article_params.to_h.merge(user_id: Current.user.id)
    )

    if result.success?
      redirect_to admin_articles_path, notice: t("admin.articles.operations.create.success")
    else
      @article = result[:model] || Article.new(article_params)
      render Views::Admin::Articles::New.new(@article), status: :unprocessable_entity
    end
  end

  def edit
    @article = find_user_article_by_id_or_slug!
    render Views::Admin::Articles::Edit.new(@article)
  rescue ActiveRecord::RecordNotFound
    redirect_to admin_articles_path, alert: t("articles.errors.not_found")
  end

  def update
    article = find_user_article_by_id_or_slug!
    result = Articles::Operation::Update.call(
      model: article,
      params: article_params.to_h
    )

    if result.success?
      redirect_to admin_articles_path, notice: t("admin.articles.operations.update.success")
    else
      @article = result[:model] || article
      render Views::Admin::Articles::Edit.new(@article), status: :unprocessable_entity
    end
  rescue ActiveRecord::RecordNotFound
    redirect_to admin_articles_path, alert: t("articles.errors.not_found")
  end

  def destroy
    article = find_user_article_by_id_or_slug!
    result = Articles::Operation::Destroy.call(model: article)

    if result.success?
      redirect_to admin_articles_path, notice: t("admin.articles.operations.destroy.success"), status: :see_other
    else
      redirect_to admin_articles_path, alert: t("admin.articles.operations.destroy.failure"), status: :see_other
    end
  rescue ActiveRecord::RecordNotFound
    redirect_to admin_articles_path, alert: t("articles.errors.not_found"), status: :see_other
  end

  def publish
    article = find_user_article_by_id_or_slug!
    action = params[:publish_action] || "publish"
    result = Articles::Operation::Publish.call(
      model: article,
      params: { action: action }
    )

    operation_key = action == "publish" ? "publish" : "unpublish"
    if result.success?
      redirect_to admin_articles_path, notice: t("admin.articles.operations.#{operation_key}.success")
    else
      redirect_to admin_articles_path, alert: t("admin.articles.operations.#{operation_key}.failure")
    end
  rescue ActiveRecord::RecordNotFound
    redirect_to admin_articles_path, alert: t("articles.errors.not_found")
  end

  private

  def article_params
    params.require(:article).permit(:title, :slug, :body, :excerpt, :status, :published_at)
  end

  def find_user_article_by_id_or_slug!
    # Try to find by numeric ID first, then by slug (since to_param returns slug)
    Current.user.articles.find_by(id: params[:id]) || Current.user.articles.find_by!(slug: params[:id])
  end
end
