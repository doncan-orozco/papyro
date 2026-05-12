# frozen_string_literal: true

class CoverImageValidator < ActiveModel::Validator
  def validate(record)
    Articles::CoverImageValidation.new(record).validate
  end
end
