# frozen_string_literal: true

class CleanupEmptyDraftsJob < ApplicationJob
  queue_as :maintenance

  STALE_AGE = 24.hours

  def perform
    Article.where(status: :draft)
      .where("created_at < ?", STALE_AGE.ago)
      .where(title: [ nil, "", *placeholder_titles ])
      .find_each do |article|
        article.destroy if article.plain_text_body.blank?
      end
  end

  private

  def placeholder_titles
    I18n.available_locales.filter_map do |locale|
      I18n.t("studio.articles.editor.untitled", locale: locale, default: nil).presence
    end.uniq
  end
end
