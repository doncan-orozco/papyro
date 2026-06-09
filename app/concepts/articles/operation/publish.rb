# frozen_string_literal: true

module Articles
  module Operation
    class Publish < Core::Operation
      def call(model:, settings_params: {}, locale: I18n.locale)
        persisted_model = step publish_with_optional_settings(
          model: model,
          settings_params: settings_params,
          locale: locale
        )

        enqueue_og_image_generation(persisted_model)

        { model: persisted_model }
      end

      private

      def publish_with_optional_settings(model:, settings_params:, locale:)
        transaction_failure = nil
        preserved_failure = nil

        persisted_model = Mobility.with_locale(locale) do
          ActiveRecord::Base.transaction do
            prepared_model = if settings_params.present?
              result = apply_settings(model: model, settings_params: settings_params, locale: locale)
              unless result.success?
                transaction_failure = result
                raise ActiveRecord::Rollback
              end

              result.value!
            else
              model
            end

            publishable_model = validate_publishable(prepared_model)
            unless publishable_model.success?
              if publishable_model.failure[:code] == :already_published
                preserved_failure = publishable_model
                prepared_model
              else
                transaction_failure = publishable_model
                raise ActiveRecord::Rollback
              end
            else
              persisted_model = persist_publish_state(publishable_model.value!)
              unless persisted_model.success?
                transaction_failure = persisted_model
                raise ActiveRecord::Rollback
              end

              persisted_model.value!
            end
          end
        end

        return transaction_failure if transaction_failure
        return preserved_failure if preserved_failure

        Success(persisted_model)
      end

      def apply_settings(model:, settings_params:, locale:)
        return Success(model) if settings_params.blank?

        result = Articles::Operation::Update.new.call(
          model: model,
          params: settings_params,
          locale: locale
        )

        return Success(result.value![:model]) if result.success?
        return result if result.failure[:code] != :trashed || result.failure[:message].present?

        fail_with_code!(
          result.failure[:model] || model,
          :trashed,
          message: I18n.t("studio.articles.operations.update.trashed")
        )
      end

      def validate_publishable(model)
        unless model.user.verified?
          return fail_with_code!(
            model,
            :email_unverified,
            message: I18n.t("studio.articles.operations.publish.email_verification_required")
          )
        end

        if model.trashed?
          return fail_with_code!(
            model,
            :trashed,
            message: I18n.t("studio.articles.operations.update.trashed")
          )
        end

        if model.published?
          return fail_with_code!(
            model,
            :already_published,
            message: I18n.t("errors.messages.article_already_published")
          )
        end

        body_html = model.body&.to_html.to_s
        if model.title.blank? || body_html.strip.blank? || model.excerpt.to_s.strip.blank?
          return fail_with_business_error!(model, I18n.t("errors.messages.article_incomplete_for_publish"))
        end

        Success(model)
      end

      def persist_publish_state(model)
        previous_published_at = model.published_at
        previous_archived_at = model.archived_at
        now = Time.current

        model.assign_attributes(published_at: now, archived_at: nil)
        unless model.save
          restore_publish_attributes(
            model,
            previous_published_at: previous_published_at,
            previous_archived_at: previous_archived_at
          )
          return fail_with_model!(model)
        end

        original_translation = model.article_translations.find_by(locale: model.original_locale)
        if original_translation.blank?
          restore_publish_attributes(
            model,
            previous_published_at: previous_published_at,
            previous_archived_at: previous_archived_at
          )
          model.errors.add(:base, I18n.t("errors.messages.translation_not_found"))
          return fail_with_model!(model)
        end

        # Update translation with status enum (published=2) and published_at timestamp.
        unless original_translation.update(status: :published, published_at: now)
          restore_publish_attributes(
            model,
            previous_published_at: previous_published_at,
            previous_archived_at: previous_archived_at
          )
          model.errors.add(:base, I18n.t("studio.articles.operations.publish.failure"))
          return fail_with_model!(model)
        end

        Success(model)
      end

      def restore_publish_attributes(model, previous_published_at:, previous_archived_at:)
        model.published_at = previous_published_at
        model.archived_at = previous_archived_at
      end

      def enqueue_og_image_generation(article)
        return if article.cover_image.attached?

        Articles::GenerateOgImageJob.perform_later(article.id)
      end
    end
  end
end
