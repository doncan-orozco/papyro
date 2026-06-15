# frozen_string_literal: true

module Articles
  module Query
    class Owned < Core::Query::Application
      base_scope { Article.all }

      pipeline :preload_translations,
               :filter_by_owner,
               :filter_by_tab,
               :filter_by_status,
               :apply_ordering

      private

      def preload_translations(current_scope)
        current_scope.includes(:translations, :article_translations, :user)
      end

      def filter_by_owner(current_scope)
        return current_scope.none if filters[:user].blank?

        current_scope.where(user: filters[:user])
      end

      def filter_by_tab(current_scope)
        return current_scope.where.not(deleted_at: nil) if active_tab == "trash"

        # Exclude trashed articles by default
        current_scope.where(deleted_at: nil)
      end

      def filter_by_status(current_scope)
        return current_scope if active_tab == "trash"

        status_filter = filters[:status].presence || status_from_tab
        return current_scope if status_filter.blank?

        case status_filter.to_s
        when "published"
          filter_published(current_scope)
        when "draft"
          filter_draft(current_scope)
        when "archived"
          current_scope.where.not(archived_at: nil)
        else
          current_scope
        end
      end

      def apply_ordering(current_scope)
        current_scope.order(updated_at: :desc)
      end

      def filter_published(current_scope)
        current_scope.where(published_at: ..Time.current)
      end

      def filter_draft(current_scope)
        current_scope.where(published_at: nil)
      end

      def active_tab
        filters[:tab] || ""
      end

      def status_from_tab
        case filters[:tab]
        when "published"
          "published"
        when "drafts"
          "draft"
        when "all"
          nil
        else
          nil
        end
      end
    end
  end
end
