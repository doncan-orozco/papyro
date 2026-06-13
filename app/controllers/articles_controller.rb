class ArticlesController < ApplicationController
  allow_unauthenticated_access only: [ :index, :show ]

  def index
    scoped_articles = policy_scope(Article)
    @pagy, @articles = pagy(
      Articles::Query::Published.call({}, scope: scoped_articles),
      limit: 10
    )

    respond_to do |format|
      format.html do
        render Views::Articles::Index.new(
          articles: @articles,
          show_welcome_hero: Current.user.guest?,
          pagy: @pagy
        )
      end
      format.turbo_stream do
        render Views::Articles::LoadMore.new(
          articles: @articles,
          pagy: @pagy
        )
      end
    end
  end

  def show
    @article = find_published_article_by_slug!

    authorize @article

    more_from_author = Articles::Query::Related.call({
      user: @article.user,
      article_id: @article.id,
      locale: I18n.locale.to_s
    }).limit(4)
    more_from_platform = Articles::Query::Related.call({
      exclude_user_id: @article.user_id,
      article_id: @article.id,
      locale: I18n.locale.to_s
    }).limit(4)

    @total_author_articles_count = Articles::Query::Related.call({
      user: @article.user,
      locale: I18n.locale.to_s
    }).count

    @presenter = ::Articles::Presenter::Show.new(
      @article,
      more_from_author: more_from_author,
      more_from_platform: more_from_platform,
      author_total_count: @total_author_articles_count,
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
