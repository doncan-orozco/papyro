# frozen_string_literal: true

module Articles
  module Query
    class OwnedBySlug < Core::Query::Application
      base_scope { Article.all }

      pipeline :join_translations,
               :filter_by_slug,
               :filter_by_locale,
               :filter_by_owner,
               :filter_by_global_overrides

      private

      def join_translations(current_scope)
        current_scope.joins(:article_translations).includes(user: :profile)
      end

      def filter_by_slug(current_scope)
        slug = filters[:slug].to_s
        return current_scope.none if slug.blank?

        current_scope.where(article_translations: { slug: slug })
      end

      def filter_by_locale(current_scope)
        locale = filters[:locale].to_s
        return current_scope if locale.blank?

        current_scope.where(article_translations: { locale: locale })
      end

      def filter_by_owner(current_scope)
        owner = filters[:user]
        return current_scope.none if owner.blank?

        current_scope.where(user: owner)
      end

      def filter_by_global_overrides(current_scope)
        current_scope.where(articles: { deleted_at: nil, archived_at: nil }).distinct
      end
    end
  end
end
