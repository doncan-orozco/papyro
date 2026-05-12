# frozen_string_literal: true

class ArticleBodyValidator < ActiveModel::Validator
  MAX_BODY_LENGTH = 100_000

  def validate(record)
    return unless record.body.present?
    return unless record.body.content.to_s.length > MAX_BODY_LENGTH

    record.errors.add(:body, I18n.t("dry_schema.errors.max_size?", num: MAX_BODY_LENGTH))
  end
end
