# frozen_string_literal: true

module Articles
  module Contract
    class Create < Dry::Validation::Contract
      params do
        required(:title).filled(Types::StrippedString)
        optional(:slug).maybe(Types::NormalizedSlug)
        optional(:status).maybe(Types::StrippedString)
        optional(:body).maybe(:string)
        optional(:published_at).maybe(:time)
        optional(:excerpt).maybe(Types::StrippedString)
        optional(:original_locale).maybe(:string)
      end
    end
  end
end
