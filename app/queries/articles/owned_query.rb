# frozen_string_literal: true

module Articles
  class OwnedQuery < ApplicationQuery
    base_scope { Article.all }

    pipeline :filter_by_owner,
             :filter_by_tab,
             :filter_by_status,
             :apply_ordering

    private

    def filter_by_owner(current_scope)
      return current_scope.none if filters[:user].blank?

      current_scope.where(user: filters[:user])
    end

    def filter_by_status(current_scope)
      return current_scope if active_tab == "trash"

      status_filter = filters[:status].presence || status_from_tab
      return current_scope if status_filter.blank?

      current_scope.where(status: status_filter)
    end

    def filter_by_tab(current_scope)
      return current_scope.trashed if active_tab == "trash"

      current_scope.kept
    end

    def active_tab
      tab = filters[:tab].to_s
      return tab if %w[all trash drafts draft published archived].include?(tab)

      "all"
    end

    def status_from_tab
      return "draft" if active_tab == "drafts"
      return active_tab if %w[draft published archived].include?(active_tab)

      nil
    end

    def apply_ordering(current_scope)
      current_scope.order(updated_at: :desc)
    end
  end
end
