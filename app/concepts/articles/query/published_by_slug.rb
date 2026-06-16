# frozen_string_literal: true

module Articles
  module Query
    class PublishedBySlug < Core::Query::Application
      base_scope { Article.all }

      pipeline :join_translations,
               :filter_by_slug,
               :filter_by_locale,
               :filter_by_publication_status,
               :filter_by_global_overrides

      private

      def join_translations(current_scope)
        current_scope.joins(:translations).includes(user: :profile)
      end

      def filter_by_slug(current_scope)
        slug = filters[:slug].to_s
        return current_scope.none if slug.blank?

        current_scope.where(translations: { slug: slug, status: Article::Translation.statuses[:published] })
      end

      def filter_by_locale(current_scope)
        locale = filters[:locale].to_s
        return current_scope if locale.blank?

        current_scope.where(translations: { locale: locale })
      end

      def filter_by_publication_status(current_scope)
        current_scope.where.not(articles: { published_at: nil })
      end

      def filter_by_global_overrides(current_scope)
        current_scope.where(articles: { deleted_at: nil, archived_at: nil }).distinct
      end
    end
  end
end
