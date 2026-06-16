# frozen_string_literal: true

module Users
  module Query
    class AuthorByArticleSlug < Core::Query::Application
      base_scope { User.all }

      pipeline :join_articles,
               :filter_by_slug

      private

      def join_articles(current_scope)
        current_scope.joins(articles: :translations)
                     .select("users.*, translations.slug")
      end

      def filter_by_slug(current_scope)
        slug = filters[:slug].to_s
        return current_scope.none if slug.blank?

        current_scope.where(translations: { slug: slug })
      end
    end
  end
end
