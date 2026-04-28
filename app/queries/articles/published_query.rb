# frozen_string_literal: true

module Articles
  class PublishedQuery < ApplicationQuery
    base_scope { Article.where(status: :published) }

    pipeline :apply_ordering

    private

    def apply_ordering(current_scope)
      current_scope.order(published_at: :desc)
    end
  end
end
