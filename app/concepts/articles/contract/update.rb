# frozen_string_literal: true

module Articles
  module Contract
    class Update < Dry::Validation::Contract
      params do
        optional(:title).maybe(Types::StrippedString)
        optional(:slug).maybe(Types::NormalizedSlug)
        optional(:status).maybe(Types::StrippedString)
        optional(:body).maybe(:string)
        optional(:published_at).maybe(:time)
        optional(:excerpt).maybe(Types::StrippedString)
        optional(:cover_image).maybe(Types::Any)
        optional(:cover_image_caption).maybe(Types::StrippedString)
      end
    end
  end
end
