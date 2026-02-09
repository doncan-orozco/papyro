# frozen_string_literal: true

module Articles
  module Contract
    class Create < Dry::Validation::Contract
      # Schema definition - what fields we expect
      params do
        required(:title).filled(:string)
        required(:slug).filled(:string)
        required(:status).filled(:string)
        optional(:content).maybe(:string)
        optional(:published_at).value(:time)
        optional(:excerpt).maybe(:string)
        required(:user_id).filled(:integer)
      end

      # Custom validation rules beyond schema
      rule(:title) do
        if value
          key.failure(I18n.t("errors.messages.title_blank")) if value.strip.empty?
          key.failure(I18n.t("errors.messages.title_too_long")) if value.length > 255
        end
      end

      rule(:slug) do
        if value
          key.failure(I18n.t("errors.messages.slug_invalid_format")) unless slug_format_valid?(value)
          key.failure(I18n.t("errors.messages.slug_too_long")) if value.length > 255
          # Create-specific: check slug doesn't exist
          key.failure(I18n.t("errors.messages.slug_already_exists")) if Article.exists?(slug: value)
        end
      end

      rule(:status) do
        key.failure(I18n.t("errors.messages.status_invalid")) unless %w[draft published archived].include?(value)
      end

      rule(:content) do
        if value
          key.failure(I18n.t("errors.messages.content_too_long")) if value.length > 100_000
        end
      end

      rule(:excerpt) do
        if value
          key.failure(I18n.t("errors.messages.excerpt_too_long")) if value.length > 500
        end
      end

      rule(:published_at) do
        if value && value > Time.current
          key.failure(I18n.t("errors.messages.published_at_future"))
        end
      end

      rule(:user_id) do
        unless User.exists?(values[:user_id])
          key.failure(I18n.t("errors.messages.user_not_found"))
        end
      end

      # Cross-field validation: published status requires published_at
      rule(:status, :published_at) do
        if values[:status] == "published" && values[:published_at].blank?
          key(:published_at).failure(I18n.t("errors.messages.published_at_required_for_published"))
        end
      end

      private

      def slug_format_valid?(slug)
        # Only lowercase, alphanumeric, hyphens
        slug.match?(/\A[a-z0-9-]+\z/)
      end
    end
  end
end
