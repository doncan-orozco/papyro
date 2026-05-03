# frozen_string_literal: true

require "securerandom"

module Articles
  module Operation
    class Update < ApplicationOperation
      HASH_LENGTH = 6
      MAX_SLUG_COLLISION_RETRIES = 3

      def call(model:, params:)
        normalized_params, generated_slug = step prepare_attributes(model: model, params: params)
        validated_attributes = step validate_input(model: model, params: normalized_params)
        persisted_article    = step persist_article(model: model, attributes: validated_attributes, generated_slug: generated_slug)

        { model: persisted_article }
      end

      private

      def prepare_attributes(model:, params:)
        normalized_params = params.to_h.symbolize_keys

        if model.status_published?
          return fail_with_locked_slug_error!(model) if slug_change_requested?(model: model, params: normalized_params)

          return Success([ normalized_params.except(:slug), false ])
        end

        attrs, generated = normalize_draft_slug(model: model, params: normalized_params)
        Success([ attrs, generated ])
      end

      def validate_input(model:, params:)
        contract_result = Articles::Contract::Update.new.call(params)

        if contract_result.failure?
          model.assign_attributes(params.except(:slug))
          invalid_article = inject_errors!(model, contract_result.errors.to_h)
          return fail_with_model!(invalid_article)
        end

        Success(contract_result.to_h)
      end

      def persist_article(model:, attributes:, generated_slug:)
        model.assign_attributes(attributes)
        attempts = 0

        loop do
          begin
            return Success(model) if model.save

            break unless should_retry?(model, generated_slug, attempts)

            attempts += 1
            model.slug = generate_slug_from_title(model.title)
          rescue ActiveRecord::RecordNotUnique
            break unless generated_slug && attempts < MAX_SLUG_COLLISION_RETRIES

            attempts += 1
            model.slug = generate_slug_from_title(model.title)
          end
        end

        model.errors.add(:slug, :taken) if model.errors.empty?
        fail_with_model!(model)
      end

      def should_retry?(model, generated_slug, attempts)
        generated_slug && slug_taken_collision?(model) && attempts < MAX_SLUG_COLLISION_RETRIES
      end

      def slug_taken_collision?(model)
        model.errors.details.fetch(:slug, []).any? { |error| error[:error] == :taken }
      end

      def normalize_draft_slug(model:, params:)
        incoming_slug = params[:slug]
        title_changed = params[:title].present? && params[:title] != model.title
        slug_not_intentionally_changed = incoming_slug.blank? || incoming_slug == model.slug

        if title_changed && slug_not_intentionally_changed
          return [ params.merge(slug: generate_slug_from_title(params[:title])), true ]
        end

        return [ params.except(:slug), false ] if incoming_slug.blank?

        [ params, false ]
      end

      def slug_change_requested?(model:, params:)
        params.key?(:slug) && params[:slug].present? && params[:slug] != model.slug
      end

      def fail_with_locked_slug_error!(model)
        locked_model = inject_errors!(model, {
          slug: [ I18n.t("studio.articles.operations.update.slug_locked") ]
        })

        fail_with_model!(locked_model)
      end

      def generate_slug_from_title(title)
        base_slug = title.to_s.parameterize
        base_slug = "article" if base_slug.blank?

        "#{base_slug}-#{random_slug_suffix}"
      end

      def random_slug_suffix
        SecureRandom.alphanumeric(HASH_LENGTH).downcase
      end
    end
  end
end
