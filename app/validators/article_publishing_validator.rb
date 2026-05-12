# frozen_string_literal: true

class ArticlePublishingValidator < ActiveModel::Validator
  def validate(record)
    validate_future_date(record)
  end

  private

  def validate_future_date(record)
    return unless record.published_at.present? && record.published_at > Time.current

    record.errors.add(:published_at, I18n.t("errors.messages.published_at_future"))
  end
end
