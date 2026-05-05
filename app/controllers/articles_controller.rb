class ArticlesController < ApplicationController
  allow_unauthenticated_access only: [ :index, :show ]

  def index
    scoped_articles = policy_scope(Article)
    @articles = Articles::PublishedQuery.call({}, scope: scoped_articles).limit(6)
    render Views::Articles::Index.new(articles: @articles)
  end

  def show
    @article = Article.find_by!(slug: params[:slug], status: :published)
    @more_from_author = @article.user.articles
      .kept
      .status_published
      .where.not(id: @article.id)
      .order(published_at: :desc)
      .limit(2)

    @more_from_platform = Article
      .kept
      .status_published
      .where.not(id: @article.id)
      .where.not(user_id: @article.user_id)
      .order(published_at: :desc)
      .limit(2)

    authorize @article
    render Views::Articles::Show.new(
      article: @article,
      more_from_author: @more_from_author,
      more_from_platform: @more_from_platform
    )
  end
end
