class ArticlesController < ApplicationController
  allow_unauthenticated_access

  def featured
    @articles = Articles::PublishedQuery.call(limit: 4)
    render Views::Articles::Featured.new(articles: @articles)
  end

  def show
    @article = Article.find_by!(slug: params[:slug], status: :published)
    @all_articles = Article.where(status: :published).order(published_at: :desc)
    @prev_article = @all_articles.where("published_at < ?", @article.published_at).first
    @next_article = @all_articles.where("published_at > ?", @article.published_at).last
    render Views::Articles::Show.new(article: @article, prev_article: @prev_article, next_article: @next_article)
  rescue ActiveRecord::RecordNotFound
    render file: "#{Rails.root}/public/404.html", status: :not_found, layout: false
  end
end
