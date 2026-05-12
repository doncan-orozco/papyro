# frozen_string_literal: true

module Articles
  class PublishedQuery < ApplicationQuery
    base_scope { Article.all }

    pipeline :filter_by_locale,
             :filter_by_publication_status,
             :filter_by_global_overrides,
             :apply_ordering

    private

    def filter_by_locale(current_scope)
      # Get the current locale (defaults to I18n.locale)
      locale = filters[:locale] || I18n.locale.to_s

      # Join with article_translations to access locale-specific status
      current_scope.joins(:article_translations)
                   .where(article_translations: { locale: locale })
    end

    def filter_by_publication_status(current_scope)
      current_scope.where(article_translations: { status: ArticleTranslation.statuses[:published] })
                   .where.not(articles: { published_at: nil })
    end

    def filter_by_global_overrides(current_scope)
      # Exclude deleted and archived articles from public visibility
      current_scope.kept.active
    end

    def apply_ordering(current_scope)
      current_scope.order(articles: { published_at: :desc })
                   .distinct
    end
  end
end
