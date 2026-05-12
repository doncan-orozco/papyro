class ArticlesController < ApplicationController
  allow_unauthenticated_access only: [ :index, :show ]

  def index
    scoped_articles = policy_scope(Article)
    @articles = Articles::PublishedQuery.call({}, scope: scoped_articles).limit(6)
    render Views::Articles::Index.new(articles: @articles)
  end

  def show
    @article = find_published_article_by_slug!
    @translation_fallback = translation_fallback?

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
      more_from_platform: @more_from_platform,
      translation_fallback: @translation_fallback
    )
  end

  private

  def find_published_article_by_slug!
    locale_slug = params[:slug].to_s

    # Try locale-specific translation slug first (any published state — display fallback
    # is handled separately by translation_fallback?)
    article = Article
      .joins(:article_translations)
      .where(article_translations: { slug: locale_slug, locale: I18n.locale.to_s, status: ArticleTranslation.statuses[:published] })
      .where.not(articles: { published_at: nil })
      .kept
      .active
      .first

    return article if article.present?

    # Last resort: match slug across any locale (supports cross-locale linking)
    Article
      .joins(:article_translations)
      .where(article_translations: { slug: locale_slug, status: ArticleTranslation.statuses[:published] })
      .where.not(articles: { published_at: nil })
      .kept
      .active
      .first!
  end

  def translation_fallback?
    return false if I18n.locale.to_s == "en"

    !@article.translation_published?
  end
end
