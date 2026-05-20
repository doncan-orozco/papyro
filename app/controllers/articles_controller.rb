class ArticlesController < ApplicationController
  allow_unauthenticated_access only: [ :index, :show ]

  def index
    scoped_articles = policy_scope(Article)
    articles = Articles::Query::Published.call({}, scope: scoped_articles).limit(6)
    render Views::Articles::Index.new(
      articles: articles,
      show_welcome_hero: Current.user.guest?
    )
  end

  def show
    @article = find_published_article_by_slug!

    authorize @article

    more_from_author = Articles::Query::Related.call({
      user: @article.user,
      article_id: @article.id,
      limit: 2
    })
    more_from_platform = Articles::Query::Related.call({
      exclude_user_id: @article.user_id,
      article_id: @article.id,
      limit: 2
    })

    @presenter = ::Articles::Presenter::Show.new(
      @article,
      more_from_author: more_from_author,
      more_from_platform: more_from_platform,
      locale: I18n.locale
    )

    render Views::Articles::Show.new(
      presenter: @presenter
    )
  end

  private

  def find_published_article_by_slug!
    locale_slug = params[:slug].to_s

    owner_article = find_owned_article_by_slug(locale_slug)
    return owner_article if owner_article.present?

    # Try locale-specific slug first, then fall back to any locale slug.
    article = Articles::Query::PublishedBySlug.call({ slug: locale_slug, locale: I18n.locale.to_s }).first

    return article if article.present?

    Articles::Query::PublishedBySlug.call({ slug: locale_slug }).first!
  end

  def find_owned_article_by_slug(locale_slug)
    return nil unless Current.user&.registered?

    article = Articles::Query::OwnedBySlug.call({ slug: locale_slug, locale: I18n.locale.to_s, user: Current.user }).first
    return article if article.present?

    Articles::Query::OwnedBySlug.call({ slug: locale_slug, user: Current.user }).first
  end
end
