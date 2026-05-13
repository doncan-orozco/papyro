class ArticlesController < ApplicationController
  allow_unauthenticated_access only: [ :index, :show ]

  def index
    scoped_articles = policy_scope(Article)
    articles = Articles::PublishedQuery.call({}, scope: scoped_articles).limit(6)
    render Views::Articles::Index.new(articles: articles)
  end

  def show
    @article = find_published_article_by_slug!

    authorize @article

    more_from_author = Articles::RelatedQuery.call({
      user: @article.user,
      article_id: @article.id,
      limit: 2
    })
    more_from_platform = Articles::RelatedQuery.call({
      exclude_user_id: @article.user_id,
      article_id: @article.id,
      limit: 2
    })

    render Views::Articles::Show.new(
      article: @article,
      more_from_author: more_from_author,
      more_from_platform: more_from_platform
    )
  end

  private

  def find_published_article_by_slug!
    locale_slug = params[:slug].to_s

    # Try locale-specific slug first, then fall back to any locale slug.
    article = Articles::PublishedBySlugQuery.call({ slug: locale_slug, locale: I18n.locale.to_s }).first

    return article if article.present?

    Articles::PublishedBySlugQuery.call({ slug: locale_slug }).first!
  end
end
