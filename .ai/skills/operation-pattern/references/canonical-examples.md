# Canonical Operation Examples

Use these examples as shape guides when implementing operations in `app/concepts/*/operation/`.

## 1. Simple Create Command

Use this shape when one intent needs contract validation plus one persistence step.

```ruby
module Articles
  module Operation
    class Create < ApplicationOperation
      def call(params:, user:)
        validated_attributes = step validate_input(params)
        persisted_article = step persist_article(attributes: validated_attributes, user: user)

        { model: persisted_article }
      end

      private

      def validate_input(params)
        contract_result = Articles::Contract::Create.new.call(params)
        return Success(contract_result.to_h.symbolize_keys) if contract_result.success?

        invalid_article = inject_errors!(Article.new(params), contract_result.errors.to_h)
        fail_with_model!(invalid_article)
      end

      def persist_article(attributes:, user:)
        article = user.articles.build(attributes)
        return Success(article) if article.save

        fail_with_model!(article)
      end
    end
  end
end
```

When to use:
- `create` flows
- one write after contract validation
- no route-specific failure codes needed

## 2. Locale-Aware Update Command

Use this shape when mutating translated content or locale-sensitive fields.

```ruby
module Articles
  module Operation
    class Update < ApplicationOperation
      def call(model:, params:, locale: I18n.locale)
        normalized_params, generated_slug = step prepare_attributes(model: model, params: params, locale: locale)
        validated_attributes = step validate_input(model: model, params: normalized_params)
        persisted_article = step persist_article(model: model, attributes: validated_attributes, generated_slug: generated_slug)

        { model: persisted_article }
      end
    end
  end
end
```

When to use:
- translated models with `Mobility`
- updates that need a pre-validation normalization step
- commands that return an invalid model for form re-rendering

## 3. Transactional State Command

Use this shape when one user action combines settings updates with a state transition and all writes must succeed or fail together.

```ruby
module Articles
  module Operation
    class Publish < ApplicationOperation
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
    end
  end
end
```

When to use:
- one click triggers multiple writes
- the controller should route on `failure[:code]`
- partial persistence would create inconsistent domain state
- one specific failure code may intentionally preserve metadata changes after validation, such as `:already_published`

## 4. Translation State Command

Use this shape when publishing or unpublishing one locale-specific translation while keeping the operation contract aligned with the parent article state commands.

```ruby
module Articles
  module Operation
    class PublishTranslation < ApplicationOperation
      def call(model:, locale:)
        persisted_translation = step publish_translation_with_state_transition(model: model, locale: locale)

        { model: model, translation: persisted_translation }
      end

      private

      def publish_translation_with_state_transition(model:, locale:)
        transaction_failure = nil

        persisted_translation = ActiveRecord::Base.transaction do
          translatable_model = validate_translatable_locale(model: model, locale: locale)
          unless translatable_model.success?
            transaction_failure = translatable_model
            raise ActiveRecord::Rollback
          end

          published_parent = validate_parent_published(model)
          unless published_parent.success?
            transaction_failure = published_parent
            raise ActiveRecord::Rollback
          end

          translation = find_or_build_translation(model: model, locale: locale)
          unless translation.success?
            transaction_failure = translation
            raise ActiveRecord::Rollback
          end

          publishable_translation = validate_translation_has_content(translation.value!)
          unless publishable_translation.success?
            transaction_failure = publishable_translation
            raise ActiveRecord::Rollback
          end

          persisted_translation = persist_translation(publishable_translation.value!)
          unless persisted_translation.success?
            transaction_failure = persisted_translation
            raise ActiveRecord::Rollback
          end

          persisted_translation.value!
        end

        return transaction_failure if transaction_failure

        Success(persisted_translation)
      end
    end
  end
end
```

When to use:
- locale-specific publish or unpublish commands
- translation status changes that must stay inside one transaction boundary
- operations that return both the parent model and the mutated translation
- state commands that do not need the metadata-preserving failure branch used by parent article publish