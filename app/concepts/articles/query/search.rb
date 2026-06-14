# frozen_string_literal: true

module Articles
  module Query
    class Search < Core::Query::Application
      base_scope { Article.all }

      pipeline :include_translations,
               :filter_by_locale,
               :filter_by_publication_status,
               :filter_by_global_overrides,
               :filter_by_title,
               :apply_ordering

      private

      def filter_by_locale(current_scope)
        locale = filters[:locale] || I18n.locale.to_s

        current_scope.joins(:article_translations)
                     .where(article_translations: { locale: locale })
      end

      def filter_by_publication_status(current_scope)
        current_scope.where(article_translations: { status: ArticleTranslation.statuses[:published] })
                     .where.not(articles: { published_at: nil })
      end

      def filter_by_global_overrides(current_scope)
        current_scope.where(articles: { deleted_at: nil, archived_at: nil })
      end

      def include_translations(current_scope)
        current_scope.eager_load(:article_translations)
      end

      def filter_by_title(current_scope)
        query = filters[:query].to_s.strip
        return current_scope if query.blank?

        words = query.split(/\s+/)
        words.each do |word|
          safe_word = ActiveRecord::Base.sanitize_sql_like(word)
          current_scope = current_scope.where(
            "article_translations.title LIKE ?", "%#{safe_word}%"
          )
        end
        current_scope
      end

      def apply_ordering(current_scope)
        current_scope.order(articles: { published_at: :desc })
                     .distinct
      end
    end
  end
end
