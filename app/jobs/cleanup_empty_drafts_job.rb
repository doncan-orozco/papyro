# frozen_string_literal: true

class CleanupEmptyDraftsJob < ApplicationJob
  queue_as :maintenance

  STALE_AGE = 24.hours

  def perform
    Article
      .where(deleted_at: nil, archived_at: nil)
      .joins(original_translation_left_join_sql)
      .where("original_translations.status IS NULL OR original_translations.status != ?", ArticleTranslation.statuses[:published])
      .where("articles.created_at < ?", STALE_AGE.ago)
      .joins(:article_translations)
      .where(article_translations: { locale: "en", title: [ nil, "", *placeholder_titles ] })
      .find_each do |article|
        article.destroy if Articles::Service::ContentAnalysis.new(article).plain_text_body.blank?
      end
  end

  private

  def placeholder_titles
    I18n.available_locales.filter_map do |locale|
      I18n.t("studio.articles.editor.untitled", locale: locale, default: nil).presence
    end.uniq
  end

  def original_translation_left_join_sql
    <<~SQL.squish
      LEFT JOIN article_translations AS original_translations
      ON original_translations.article_id = articles.id
      AND original_translations.locale = articles.original_locale
    SQL
  end
end
