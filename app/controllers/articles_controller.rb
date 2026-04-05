class ArticlesController < ApplicationController
  allow_unauthenticated_access

  def index
    @articles = Articles::PublishedQuery.call(limit: 6)
    render Views::Articles::Index.new(articles: @articles)
  end

  def featured
    @articles = Articles::PublishedQuery.call(limit: 4)
    render Views::Articles::Featured.new(articles: @articles)
  end

  def show
    @article = Article.find_by!(slug: params[:slug], status: :published)
    @related_articles = Article
      .where(status: :published, user: @article.user)
      .where.not(id: @article.id)
      .order(published_at: :desc)
      .limit(2)

    render Views::Articles::Show.new(article: @article, related_articles: @related_articles)
  rescue ActiveRecord::RecordNotFound
    render file: "#{Rails.root}/public/404.html", status: :not_found, layout: false
  end
end
