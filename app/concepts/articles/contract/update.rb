# frozen_string_literal: true

module Articles
  module Contract
    class Update < Dry::Validation::Contract
      STATUSES = %w[draft published archived].freeze
      SLUG_FORMAT = /\A[a-z0-9-]+\z/

      option :article_id

      params do
        required(:title).filled(:string)
        required(:slug).filled(:string)
        required(:status).filled(:string)
        optional(:body).maybe(:string)
        optional(:published_at).maybe(:time)
        optional(:excerpt).maybe(:string)
      end

      rule(:title) do
        key.failure(I18n.t("dry_schema.errors.max_size?", num: 255)) if value && value.length > 255
      end

      rule(:slug) do
        next unless value

        if value.length > 255
          key.failure(I18n.t("dry_schema.errors.max_size?", num: 255))
        elsif value !~ SLUG_FORMAT
          key.failure(I18n.t("articles.forms.validation.slug_invalid_format"))
        elsif ::Article.where.not(id: article_id).exists?(slug: value)
          key.failure(I18n.t("errors.messages.slug_already_exists"))
        end
      end

      rule(:status) do
        key.failure(I18n.t("articles.forms.validation.status_invalid")) if value && !STATUSES.include?(value)
      end

      rule(:body) do
        key.failure(I18n.t("dry_schema.errors.max_size?", num: 100_000)) if value && value.length > 100_000
      end

      rule(:published_at) do
        key.failure(I18n.t("errors.messages.published_at_future")) if value && value > Time.current
      end

      rule(:excerpt) do
        key.failure(I18n.t("dry_schema.errors.max_size?", num: 500)) if value && value.length > 500
      end

      rule(:status, :published_at) do
        if values[:status] == "published" && values[:published_at].blank?
          key(:published_at).failure(I18n.t("errors.messages.published_at_required_for_published"))
        end
      end
    end
  end
end
