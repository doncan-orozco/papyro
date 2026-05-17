# frozen_string_literal: true

module Articles
  module Validator
    class CoverImage < ActiveModel::Validator
      def validate(record)
        Articles::Service::CoverImageValidation.new(record).validate
      end
    end
  end
end
