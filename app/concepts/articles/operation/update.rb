# frozen_string_literal: true

require "securerandom"

module Articles
  module Operation
    class Update < Core::Operation
      HASH_LENGTH = 6
      MAX_SLUG_COLLISION_RETRIES = 3

      def call(model:, params:, locale: I18n.locale)
        normalized_params, generated_slug = step prepare_attributes(model: model, params: params, locale: locale)
        validated_attributes = step validate_input(model: model, params: normalized_params, locale: locale)
        persisted_article    = step persist_article(model: model, attributes: validated_attributes, generated_slug: generated_slug, locale: locale)

        { model: persisted_article }
      end

      private

      def prepare_attributes(model:, params:, locale:)
        normalized_params = params.to_h.symbolize_keys

        if slug_locked_for_current_locale?(model, locale)
          return fail_with_locked_slug_error!(model) if slug_change_requested?(model: model, params: normalized_params)

          return Success([ normalized_params.except(:slug), false ])
        end

        attrs, generated = normalize_draft_slug(model: model, params: normalized_params)
        Success([ attrs, generated ])
      end

      def validate_input(model:, params:, locale:)
        if model.trashed?
          return Failure(
            model: model,
            errors: model_errors(model),
            code: :trashed
          )
        end

        contract_result = Articles::Contract::Update.new.call(params)

        if contract_result.failure?
          model.assign_attributes(params.except(:slug, :status, :body))
          assign_localized_body_preview(model: model, locale: locale, params: params)
          invalid_article = inject_errors!(model, contract_result.errors.to_h)
          return fail_with_model!(invalid_article)
        end

        if publish_requested?(params) && params[:published_at].blank? && !model.published?
          model.assign_attributes(params.except(:slug, :status, :body))
          assign_localized_body_preview(model: model, locale: locale, params: params)
          model.errors.add(:published_at, I18n.t("errors.messages.published_at_required_for_published"))
          return fail_with_model!(model)
        end

        Success(contract_result.to_h.symbolize_keys)
      end

      def persist_article(model:, attributes:, generated_slug:, locale:)
        body_provided = attributes.key?(:body)
        body_content = attributes[:body]

        model.assign_attributes(attributes.except(:status, :body))
        attempts = 0

        loop do
          begin
            return Success(model) if persist_model_and_localized_body(
              model: model,
              locale: locale,
              body_provided: body_provided,
              body_content: body_content
            )

            break unless should_retry?(model, generated_slug, attempts)

            attempts += 1
            model.slug = regenerate_slug(model.slug)
          rescue ActiveRecord::RecordNotUnique
            break unless generated_slug && attempts < MAX_SLUG_COLLISION_RETRIES

            attempts += 1
            model.slug = regenerate_slug(model.slug)
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
        return [ params, false ] if incoming_slug == model.slug

        [ params, true ]
      end

      def regenerate_slug(current_slug)
        base_slug = current_slug.to_s.sub(/-[a-z0-9]{#{HASH_LENGTH}}\z/, "")
        base_slug = "article" if base_slug.blank?

        "#{base_slug}-#{random_slug_suffix}"
      end

      def slug_change_requested?(model:, params:)
        params.key?(:slug) && params[:slug].present? && params[:slug] != model.slug
      end

      def slug_locked_for_current_locale?(model, locale)
        current_locale = locale

        # The original locale slug becomes immutable once the article is published.
        return true if model.published? && model.original?(current_locale)

        # Any locale slug is immutable after that locale translation is approved.
        model.approved?(current_locale)
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

        base_slug
      end

      def random_slug_suffix
        SecureRandom.alphanumeric(HASH_LENGTH).downcase
      end

      def publish_requested?(params)
        params[:status].to_s == "published"
      end

      def assign_localized_body_preview(model:, locale:, params:)
        return unless params.key?(:body)

        if model.original?(locale)
          model.body = params[:body]
        else
          translation_for_locale(model, locale).content = params[:body]
        end
      end

      def persist_model_and_localized_body(model:, locale:, body_provided:, body_content:)
        if body_provided && model.original?(locale)
          model.body = body_content
        end

        return false unless model.save
        return true unless body_provided
        return true if model.original?(locale)

        translation = translation_for_locale(model, locale)
        translation.content = body_content
        translation.save
      end

      def translation_for_locale(model, locale)
        model.article_translations.find_or_initialize_by(locale: locale.to_s)
      end
    end
  end
end
