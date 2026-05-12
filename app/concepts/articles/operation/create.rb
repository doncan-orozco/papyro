# frozen_string_literal: true

require "securerandom"

module Articles
  module Operation
    class Create < ApplicationOperation
      HASH_LENGTH = 6
      MAX_SLUG_COLLISION_RETRIES = 3

      def call(params:, user:)
        normalized_params, generated_slug = prepare_attributes(params)
        validated_attributes = step validate_input(normalized_params)
        persisted_article = step persist_article(
          attributes: validated_attributes,
          user: user,
          retry_slug_collision: generated_slug
        )

        { model: persisted_article }
      end

      private

      def prepare_attributes(params)
        attrs = params.to_h.symbolize_keys
        attrs[:original_locale] ||= I18n.locale.to_s

        return [ attrs, true ] if attrs[:slug].present?
        return [ attrs, false ] unless attrs[:title].present?

        attrs[:slug] = generate_slug_from_title(attrs[:title])
        [ attrs, true ]
      end

      def validate_input(params)
        contract_result = Articles::Contract::Create.new.call(params)

        if contract_result.failure?
          invalid_article = inject_errors!(Article.new(params), contract_result.errors.to_h)
          return fail_with_model!(invalid_article)
        end

        Success(contract_result.to_h)
      end

      def persist_article(attributes:, user:, retry_slug_collision:)
        article = user.articles.build(attributes)
        attempts = 0

        loop do
          begin
            return Success(article) if article.save

            break unless should_retry?(article, retry_slug_collision, attempts)

            attempts += 1
            article.slug = regenerate_slug(article.slug)
          rescue ActiveRecord::RecordNotUnique
            break unless retry_slug_collision && attempts < MAX_SLUG_COLLISION_RETRIES

            attempts += 1
            article.slug = regenerate_slug(article.slug)
          end
        end

        article.errors.add(:slug, :taken) if article.errors.empty?
        fail_with_model!(article)
      end

      def should_retry?(article, retry_slug_collision, attempts)
        retry_slug_collision && slug_taken_collision?(article) && attempts < MAX_SLUG_COLLISION_RETRIES
      end

      def slug_taken_collision?(article)
        article.errors.details.fetch(:slug, []).any? { |error| error[:error] == :taken }
      end

      def regenerate_slug(current_slug)
        base_slug = current_slug.to_s.sub(/-[a-z0-9]{#{HASH_LENGTH}}\z/, "")

        "#{base_slug}-#{random_slug_suffix}"
      end

      def generate_slug_from_title(title)
        base_slug = title.to_s.parameterize
        base_slug = "article" if base_slug.blank?

        base_slug
      end

      def random_slug_suffix
        SecureRandom.alphanumeric(HASH_LENGTH).downcase
      end
    end
  end
end
