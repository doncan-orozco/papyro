# frozen_string_literal: true

module Articles
  class AdminIndexQuery
    def self.call(user:, status: nil)
      articles = Article.where(user: user)
      articles = articles.where(status: status) if status.present?
      articles.order(updated_at: :desc)
    end
  end
end
