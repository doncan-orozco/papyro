# frozen_string_literal: true

module Articles
  class OwnedQuery < ApplicationQuery
    base_scope { Article.all }

    pipeline :preload_translations,
             :filter_by_owner,
             :filter_by_tab,
             :filter_by_status,
             :apply_ordering

    private

    def preload_translations(current_scope)
      current_scope.includes(:article_translations)
    end

    def filter_by_owner(current_scope)
      return current_scope.none if filters[:user].blank?

      current_scope.where(user: filters[:user])
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

    def filter_by_tab(current_scope)
      return current_scope.where.not(deleted_at: nil) if active_tab == "trash"

      current_scope.where(deleted_at: nil)
    end

    def filter_published(current_scope)
      current_scope
        .where(archived_at: nil)
        .joins(original_translation_join_sql)
        .where(original_translations: { status: ArticleTranslation.statuses[:published] })
        .where.not(published_at: nil)
    end

    def filter_draft(current_scope)
      current_scope
        .where(archived_at: nil)
        .joins(original_translation_left_join_sql)
        .where(
          "original_translations.status IS NULL OR original_translations.status != ?",
          ArticleTranslation.statuses[:published]
        )
    end

    def original_translation_join_sql
      <<~SQL.squish
        INNER JOIN article_translations AS original_translations
        ON original_translations.article_id = articles.id
        AND original_translations.locale = articles.original_locale
      SQL
    end

    def original_translation_left_join_sql
      <<~SQL.squish
        LEFT JOIN article_translations AS original_translations
        ON original_translations.article_id = articles.id
        AND original_translations.locale = articles.original_locale
      SQL
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
      current_scope.distinct.order(updated_at: :desc)
    end
  end
end
