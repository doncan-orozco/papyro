# frozen_string_literal: true

module Articles
  class RelatedQuery < ApplicationQuery
    base_scope { Article.all }

    pipeline :filter_by_status,
             :filter_by_author,
             :exclude_reference_article,
             :apply_ordering

    private

    def filter_by_status(current_scope)
      current_scope.status_published
    end

    def filter_by_author(current_scope)
      return current_scope.none if filters[:user].blank?

      current_scope.where(user: filters[:user])
    end

    def exclude_reference_article(current_scope)
      return current_scope if filters[:article_id].blank?

      current_scope.where.not(id: filters[:article_id])
    end

    def apply_ordering(current_scope)
      current_scope.order(published_at: :desc)
    end
  end
end
