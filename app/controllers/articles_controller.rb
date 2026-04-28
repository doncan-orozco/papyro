class ArticlesController < ApplicationController
  allow_unauthenticated_access only: [ :index, :show ]

  def index
    scoped_articles = policy_scope(Article)
    @articles = Articles::PublishedQuery.call({}, scope: scoped_articles).limit(6)
    render Views::Articles::Index.new(articles: @articles)
  end

  def show
    @article = Article.find_by!(slug: params[:slug], status: :published)
    @related_articles = Articles::RelatedQuery.call(
      {
        user: @article.user,
        article_id: @article.id
      }
    ).limit(2)

    authorize @article
    render Views::Articles::Show.new(article: @article, related_articles: @related_articles)
  end
end
