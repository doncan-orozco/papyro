# Gold Standard Mutation Shape


```ruby
module Articles
  module Operation
    class Publish < Core::Operation
      def call(model:, settings_params: {}, locale: I18n.locale)
        persisted_model = step publish_with_optional_settings(
          model: model,
          settings_params: settings_params,
          locale: locale
        )

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

        result
      end

      def validate_publishable(model)
        return fail_with_code!(model, :trashed, message: I18n.t("studio.articles.operations.update.trashed")) if model.trashed?
        return fail_with_code!(model, :already_published, message: I18n.t("errors.messages.article_already_published")) if model.published?

        Success(model)
      end

      def persist_publish_state(model)
        model.published_at ||= Time.current
        return Success(model) if model.save

        fail_with_model!(model)
      end
    end
  end
end
```
