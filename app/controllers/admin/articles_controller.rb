# frozen_string_literal: true

class Admin::ArticlesController < AdminController
  def index
    render Views::Admin::Articles::Index.new
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
      redirect_to admin_articles_path, notice: t("admin.articles.create.success")
    else
      @article = Article.new(article_params)
      @errors = result[:errors]
      render Views::Admin::Articles::New.new(@article, @errors), status: :unprocessable_entity
    end
  end

  def edit
    @article = Current.user.articles.find_by!(id: params[:id])
    render Views::Admin::Articles::Edit.new(@article)
  rescue ActiveRecord::RecordNotFound
    redirect_to admin_articles_path, alert: "Article not found"
  end

  def update
    article = Current.user.articles.find_by!(id: params[:id])
    result = Articles::Operation::Update.call(
      params: article_params.to_h.merge(id: article.id, user_id: Current.user.id)
    )

    if result.success?
      redirect_to admin_articles_path, notice: t("admin.articles.update.success")
    else
      @article = article
      @errors = result[:errors]
      render Views::Admin::Articles::Edit.new(@article, @errors), status: :unprocessable_entity
    end
  rescue ActiveRecord::RecordNotFound
    redirect_to admin_articles_path, alert: "Article not found"
  end

  def destroy
    article = Current.user.articles.find_by!(id: params[:id])
    result = Articles::Operation::Destroy.call(params: { id: article.id })

    if result.success?
      redirect_to admin_articles_path, notice: t("admin.articles.destroy.success"), status: :see_other
    else
      redirect_to admin_articles_path, alert: t("admin.articles.destroy.error"), status: :see_other
    end
  rescue ActiveRecord::RecordNotFound
    redirect_to admin_articles_path, alert: "Article not found", status: :see_other
  end

  def publish
    article = Current.user.articles.find_by!(id: params[:id])
    action = params[:publish_action] || "publish"
    result = Articles::Operation::Publish.call(
      params: { id: article.id, action: action }
    )

    if result.success?
      message_key = action == "publish" ? "admin.articles.publish.success" : "admin.articles.unpublish.success"
      redirect_to admin_articles_path, notice: t(message_key)
    else
      error_key = action == "publish" ? "admin.articles.publish.error" : "admin.articles.unpublish.error"
      redirect_to admin_articles_path, alert: t(error_key)
    end
  rescue ActiveRecord::RecordNotFound
    redirect_to admin_articles_path, alert: "Article not found"
  end

  private

  def article_params
    params.require(:article).permit(:title, :slug, :content, :excerpt, :status, :published_at)
  end
end
