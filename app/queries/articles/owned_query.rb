# frozen_string_literal: true

module Articles
  class OwnedQuery < ApplicationQuery
    base_scope { Article.all }

    pipeline :filter_by_owner,
             :filter_by_status,
             :apply_ordering

    private

    def filter_by_owner(current_scope)
      return current_scope.none if filters[:user].blank?

      current_scope.where(user: filters[:user])
    end

    def filter_by_status(current_scope)
      return current_scope if filters[:status].blank?

      current_scope.where(status: filters[:status])
    end

    def apply_ordering(current_scope)
      current_scope.order(updated_at: :desc)
    end
  end
end
