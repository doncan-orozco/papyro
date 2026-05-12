# frozen_string_literal: true

module Users
  class AuthorByArticleSlugQuery < ApplicationQuery
    base_scope { User.all }

    pipeline :join_article_translations,
             :filter_by_slug,
             :distinct_authors

    private

    def join_article_translations(current_scope)
      current_scope.joins(articles: :article_translations)
    end

    def filter_by_slug(current_scope)
      slug = filters[:slug].to_s
      return current_scope.none if slug.blank?

      current_scope.where(article_translations: { slug: slug })
    end

    def distinct_authors(current_scope)
      current_scope.distinct
    end
  end
end
