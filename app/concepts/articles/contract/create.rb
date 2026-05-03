# frozen_string_literal: true

module Articles
  module Contract
    class Create < Dry::Validation::Contract
      params do
        required(:title).filled(Types::StrippedString)
        required(:slug).filled(Types::NormalizedSlug)
        required(:status).filled(Types::StrippedString)
        optional(:body).maybe(:string)
        optional(:published_at).maybe(:time)
        optional(:excerpt).maybe(Types::StrippedString)
      end
    end
  end
end
