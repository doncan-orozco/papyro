# frozen_string_literal: true

module Articles
  class PublishedQuery
    def self.call(scope = Article.all, limit: nil)
      result = scope.where(status: :published).order(published_at: :desc)
      limit ? result.limit(limit) : result
    end
  end
end
