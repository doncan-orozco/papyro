# frozen_string_literal: true

module Articles
  module Query
    class Related < Core::Query::Application
      base_scope { Article.all }

      pipeline :include_translations,
               :filter_by_locale,
               :filter_by_publication_status,
               :filter_by_global_overrides,
               :filter_by_author,
               :exclude_author,
               :exclude_reference_article,
               :apply_ordering,
               :apply_limit

      private

      def filter_by_locale(current_scope)
        locale = filters[:locale].presence || I18n.locale.to_s

        current_scope.joins(:translations)
                     .where(translations: { locale: locale })
      end

      def filter_by_publication_status(current_scope)
        current_scope.where(translations: { status: Article::Translation.statuses[:published] })
                     .where.not(articles: { published_at: nil })
      end

      def filter_by_global_overrides(current_scope)
        current_scope.where(articles: { deleted_at: nil, archived_at: nil })
      end

      def filter_by_author(current_scope)
        return current_scope.none if filters[:user].blank? && filters[:exclude_user_id].blank?
        return current_scope if filters[:user].blank?
        current_scope.where(user: filters[:user]) || current_scope
      end

      def exclude_author(current_scope)
        return current_scope if filters[:exclude_user_id].blank?

        current_scope.where.not(user_id: filters[:exclude_user_id])
      end

      def exclude_reference_article(current_scope)
        return current_scope if filters[:article_id].blank?
        current_scope.where.not(id: filters[:article_id])
      end

      def apply_ordering(current_scope)
        current_scope.distinct
      end

      def include_translations(current_scope)
        current_scope.preload(:translations).includes({ user: :profile }, :markdown_body, cover_image_attachment: :blob)
      end

      def apply_limit(current_scope)
        current_scope
      end
    end
  end
end
