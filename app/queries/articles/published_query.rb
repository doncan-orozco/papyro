# frozen_string_literal: true

module Articles
  class PublishedQuery < ApplicationQuery
    base_scope { Article.all }

    pipeline :filter_by_status,
             :apply_ordering

    private

    def filter_by_status(current_scope)
      current_scope.where(status: :published)
    end

    def apply_ordering(current_scope)
      current_scope.order(published_at: :desc)
    end
  end
end
