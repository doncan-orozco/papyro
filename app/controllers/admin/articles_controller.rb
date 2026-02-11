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

    case result
    in Dry::Monads::Success
      redirect_to admin_articles_path, notice: t("admin.articles.operations.create.success")
    in Dry::Monads::Failure
      @article = result[:model] || Article.new(article_params)
      @errors = result[:errors]
      render Views::Admin::Articles::New.new(@article, @errors), status: :unprocessable_entity
    end
  end

  def edit
    @article = Current.user.articles.find_by!(id: params[:id])
    render Views::Admin::Articles::Edit.new(@article)
  rescue ActiveRecord::RecordNotFound
    redirect_to admin_articles_path, alert: t("articles.errors.not_found")
  end

  def update
    article = Current.user.articles.find_by!(id: params[:id])
    result = Articles::Operation::Update.call(
      model: article,
      params: article_params.to_h
    )

    case result
    in Dry::Monads::Success
      redirect_to admin_articles_path, notice: t("admin.articles.operations.update.success")
    in Dry::Monads::Failure
      @article = result[:model]
      @errors = result[:errors]
      render Views::Admin::Articles::Edit.new(@article, @errors), status: :unprocessable_entity
    end
  rescue ActiveRecord::RecordNotFound
    redirect_to admin_articles_path, alert: t("articles.errors.not_found")
  end

  def destroy
    article = Current.user.articles.find_by!(id: params[:id])
    result = Articles::Operation::Destroy.call(model: article)

    case result
    in Dry::Monads::Success
      redirect_to admin_articles_path, notice: t("admin.articles.operations.destroy.success"), status: :see_other
    in Dry::Monads::Failure
      redirect_to admin_articles_path, alert: t("admin.articles.operations.destroy.failure"), status: :see_other
    end
  rescue ActiveRecord::RecordNotFound
    redirect_to admin_articles_path, alert: t("articles.errors.not_found"), status: :see_other
  end

  def publish
    article = Current.user.articles.find_by!(id: params[:id])
    action = params[:publish_action] || "publish"
    result = Articles::Operation::Publish.call(
      model: article,
      params: { action: action }
    )

    case result
    in Dry::Monads::Success
      operation_key = action == "publish" ? "publish" : "unpublish"
      redirect_to admin_articles_path, notice: t("admin.articles.operations.#{operation_key}.success")
    in Dry::Monads::Failure
      operation_key = action == "publish" ? "publish" : "unpublish"
      redirect_to admin_articles_path, alert: t("admin.articles.operations.#{operation_key}.failure")
    end
  rescue ActiveRecord::RecordNotFound
    redirect_to admin_articles_path, alert: t("articles.errors.not_found")
  end

  private

  def article_params
    params.require(:article).permit(:title, :slug, :content, :excerpt, :status, :published_at)
  end
end
